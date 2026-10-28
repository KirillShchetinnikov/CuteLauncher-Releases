"""Collect a private, versioned source kit. Never asserts legal completeness.

Requires git, the pinned Flutter SDK, pub deps JSON, and the Gradle inventory.
Uses only Python's standard library. Downloads public package archives and checks
their lockfile hashes; project secrets and machine-local paths are not exported.
"""
import argparse
import ast
from concurrent.futures import ThreadPoolExecutor
import gzip
import importlib.util
import io
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tarfile
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

PRIVATE_PATH = re.compile(r'(^|/)(\.local|\.tools|\.dart_tool|\.git|\.codex|\.agents|\.aws|build|artifacts)(/|$)|\.(p12|pfx|jks|keystore|pem)$|(^|/)(local\.properties|key\.properties|signing\.json|\.env|adbkey|id_rsa|id_ed25519)$', re.I)


def verify_project_files(files):
    if any(PRIVATE_PATH.search(name) for name in files):
        raise ValueError('Private/build-only path is tracked')


def font_metadata(path):
    data = path if isinstance(path, bytes) else path.read_bytes()
    count = struct.unpack_from('>H', data, 4)[0]
    table = next(struct.unpack_from('>I', data, 20 + i * 16)[0] for i in range(count)
                 if data[12 + i * 16:16 + i * 16] == b'name')
    _, count, start = struct.unpack_from('>HHH', data, table)
    names = {}
    for i in range(count):
        platform, _, _, key, length, offset = struct.unpack_from('>HHHHHH', data, table + 6 + i * 12)
        if platform == 3 and key in (0, 1, 5, 13, 14):
            names[str(key)] = data[table + start + offset:table + start + offset + length].decode('utf-16-be')
    return names


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args]).decode().strip()


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def lock_packages(text):
    """Read only the hosted/sdk subset of pub's generated lockfile; fail closed."""
    packages = {}
    for match in re.finditer(r'^  ([\w]+):\n((?:    .*\n|\n)+)', text, re.M):
        name, block = match.groups()
        source = re.search(r'^    source: (\w+)$', block, re.M)
        version = re.search(r'^    version: "([^"]+)"$', block, re.M)
        if not source or not version or source[1] not in ('hosted', 'sdk'):
            raise ValueError(f'Unsupported lock entry: {name}')
        item = {'version': version[1], 'source': source[1]}
        if source[1] == 'hosted':
            sha = re.search(r'^      sha256: "?([a-f0-9]{64})"?$', block, re.M)
            url = re.search(r'^      url: "?(https://[^"\s]+)"?$', block, re.M)
            if not sha or not url or url[1] != 'https://pub.dev':
                raise ValueError(f'Unsupported hosted source: {name}')
            item['sha256'] = sha[1]
        packages[name] = item
    if not packages or len(packages) != len(re.findall(r'^  \w+:$', text, re.M)):
        raise ValueError('Lockfile was not parsed completely')
    return packages


def download(url, path, expected=None):
    if not path.exists():
        temp = path.with_suffix(path.suffix + '.partial')
        request = urllib.request.Request(url, headers={'User-Agent': 'CuteLauncher-source-kit/1'})
        with urllib.request.urlopen(request, timeout=90) as response, temp.open('wb') as output:
            shutil.copyfileobj(response, output)
        temp.replace(path)
    sha = digest(path)
    if expected and sha != expected:
        raise ValueError(f'Archive checksum mismatch: {path.name}')
    return sha


def license_name(name):
    return bool(re.match(r'^(LICENSE|LICENCE|NOTICE|COPYING)(?:[._-].*)?$', Path(name).name, re.I))


def license_in_notices(text, notices):
    # Flutter groups/deduplicates separate blocks in a package LICENSE file.
    normalized = ' '.join(notices.split())
    text = re.sub(r'^-{10,}\s*$', '\n', text, flags=re.M)
    paragraphs = [paragraph for paragraph in re.split(r'\n\s*\n', text)
                  if paragraph.strip() and not re.fullmatch(r'[-\s]+', paragraph)]
    return bool(paragraphs) and all(' '.join(paragraph.split()) in normalized for paragraph in paragraphs)


def pom_licenses(path):
    root = ET.parse(path).getroot()
    for element in root.iter():
        element.tag = element.tag.split('}')[-1]
    return [{'name': item.findtext('name'), 'url': item.findtext('url')}
            for item in root.findall('./licenses/license')]


def engine_sources(deps_text):
    """Parse pinned Git sources without executing the DEPS Python program."""
    tree = ast.parse(deps_text)
    assignments = {target.id: node.value for node in tree.body if isinstance(node, ast.Assign)
                   for target in node.targets if isinstance(target, ast.Name)}
    variables = ast.literal_eval(assignments['vars'])
    def evaluate(node):
        if isinstance(node, ast.Constant): return node.value
        if isinstance(node, ast.List): return [evaluate(value) for value in node.elts]
        if isinstance(node, ast.Dict): return {evaluate(k): evaluate(v) for k, v in zip(node.keys, node.values)}
        if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Add): return evaluate(node.left) + evaluate(node.right)
        if (isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == 'Var'
                and len(node.args) == 1 and not node.keywords): return variables[evaluate(node.args[0])]
        raise ValueError('Unsupported DEPS expression')
    result = []
    for path, value in evaluate(assignments['deps']).items():
        url = value if isinstance(value, str) else value.get('url') if isinstance(value, dict) else None
        if not url: continue  # CIPD tools remain pinned in the original SDK DEPS.
        url = re.sub(r'\{(\w+)\}', lambda match: variables[match[1]], url)
        repository, revision = url.rsplit('@', 1)
        if not re.fullmatch('[0-9a-f]{40}', revision): raise ValueError('Unpinned engine source')
        result.append({'path': path, 'repository': repository, 'revision': revision})
    return result


def engine_source_closure(deps_text, read_deps):
    """Follow explicit gclient recursedeps without executing downloaded Python."""
    result = []
    seen = set()

    def visit(text, prefix=''):
        tree = ast.parse(text)
        values = {target.id: node.value for node in tree.body if isinstance(node, ast.Assign)
                  for target in node.targets if isinstance(target, ast.Name)}
        relative = ast.literal_eval(values.get('use_relative_paths', ast.Constant(False)))
        base = prefix + '/' if relative and prefix else ''
        current = {}
        for item in engine_sources(text):
            item = {**item, 'path': base + item['path']}
            path = item['path']
            if path in seen or not path or path.startswith('/') or '\\' in path or any(
                    part in ('', '.', '..') for part in path.split('/')):
                raise ValueError(f'Duplicate or unsafe engine dependency path: {path}')
            seen.add(path)
            current[path] = item
            result.append(item)
        recurse = ast.literal_eval(values.get('recursedeps', ast.List(elts=[], ctx=ast.Load())))
        if not isinstance(recurse, list) or any(not isinstance(path, str) for path in recurse):
            raise ValueError('Unsupported recursive DEPS declaration')
        for path in recurse:
            path = base + path
            if path not in current:
                raise ValueError(f'Recursive DEPS has no pinned source: {path}')
            visit(read_deps(current[path]), path)

    visit(deps_text)
    return result


def archive_deps(path):
    with tarfile.open(path) as archive:
        member = archive.getmember('DEPS')
        if not member.isfile() or member.size > 4 * 1024 * 1024:
            raise ValueError('Invalid recursive DEPS member')
        return archive.extractfile(member).read().decode('utf-8')


def project_archive(root, commit, target, public=False):
    if not public:
        subprocess.run(['git', '-C', str(root), 'archive', '--format=zip',
                        f'--output={target}', commit], check=True)
        return
    spec = importlib.util.spec_from_file_location('publish_source', root / 'scripts/publish-source.py')
    publisher = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(publisher)
    selected = publisher.source_files(root, commit)
    with tempfile.TemporaryDirectory() as directory:
        staging = Path(directory)
        publisher.export(root, commit, selected, staging)
        with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
            for name in sorted(selected):
                info = zipfile.ZipInfo.from_file(staging / name, name)
                info.create_system = 3
                info.external_attr = int(selected[name], 8) << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                with archive.open(info, 'w') as output, (staging / name).open('rb') as stream:
                    shutil.copyfileobj(stream, output)


def selected_native_sources(config, resolved):
    for coordinate, expected in config['versions'].items():
        if coordinate in resolved and resolved[coordinate] != expected:
            raise ValueError(f'Native source pins need updating: {coordinate}')
    result = []
    for item in config['sources']:
        requires = item.get('requires')
        if not requires or requires not in config['versions']:
            raise ValueError(f'Native source lacks a pinned dependency: {item["name"]}')
        if requires in resolved:
            result.append(item)
    return result


def artifact_has_code(path):
    def contains_code(archive, depth=0):
        for name in archive.namelist():
            if name.endswith(('.class', '.dex', '.so')):
                return True
            if name.endswith('.jar'):
                if depth >= 2:
                    raise ValueError('Unexpected nested Android artifact')
                with zipfile.ZipFile(io.BytesIO(archive.read(name))) as nested:
                    if contains_code(nested, depth + 1):
                        return True
        return False
    with zipfile.ZipFile(path) as archive:
        return contains_code(archive)


def native_library_sources(names, config, selected):
    available = {'project', 'flutter'} | {item['name'] for item in selected}
    coverage = {}
    for name in names:
        providers = config['libraries'].get(name.rsplit('/', 1)[-1])
        if not providers or not set(providers) <= available:
            raise ValueError(f'Native library lacks pinned sources: {name}')
        coverage[name] = providers
    return coverage


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ref', required=True)
    parser.add_argument('--public', action='store_true', help='Filter project.zip through the public source allowlist; never includes internal documentation')
    parser.add_argument('--output', type=Path, default=Path('artifacts/source'), help='Parent directory for the immutable source kit')
    parser.add_argument('--engine-sources', type=Path, required=True, help='Directory with collected recursive DEPS archives and manifest.json')
    parser.add_argument('--flutter', type=Path, default=Path('.tools/flutter-upgrade'))
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--aapt2', type=Path, required=True,
                        help='Android SDK aapt2 executable; verifies the selected APK identity')
    parser.add_argument('--inventory', type=Path, default=Path('.local/release-dependencies.json'))
    parser.add_argument('--pub-deps', type=Path, default=Path('.local/dart-dependencies.json'))
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    commit = git(root, 'rev-parse', '--verify', '--end-of-options', f'{args.ref}^{{commit}}')
    spec = git(root, 'show', f'{commit}:pubspec.yaml')
    version = re.search(r'^version:\s*(\S+)$', spec, re.M)[1]
    badging = subprocess.check_output([str(args.aapt2), 'dump', 'badging', str(args.apk)]).decode()
    identity = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    version_name, build = version.rsplit('+', 1)
    if not identity or identity.groups() != ('io.github.kirillshchetinnikov.cutelauncher', build, version_name):
        raise ValueError('APK identity/version does not match the selected source commit')
    lock = git(root, 'show', f'{commit}:pubspec.lock')
    if lock != (root / 'pubspec.lock').read_text(encoding='utf-8').strip():
        raise ValueError('Dependency inventory must match the selected committed lockfile')
    inventory = json.loads(args.inventory.read_text(encoding='utf-8-sig'))
    if inventory['lockSha256'] != digest(root / 'pubspec.lock') or str(inventory['versionCode']) != build or inventory['versionName'] != version_name:
        raise ValueError('Gradle inventory is stale or belongs to another release')
    files = git(root, 'ls-tree', '-r', '--name-only', commit).splitlines()
    verify_project_files(files)
    kit = root / args.output / f'CuteLauncher-{version}-{commit[:12]}-source-kit-{digest(args.apk)[:12]}'
    kit.mkdir(parents=True, exist_ok=False)
    cache = root / '.local/source-downloads'
    cache.mkdir(parents=True, exist_ok=True)
    project_archive(root, commit, kit / 'project.zip', public=args.public)
    packages = lock_packages(lock + '\n')
    pub_graph = json.loads(args.pub_deps.read_text(encoding='utf-8-sig'))
    graph = {p['name']: p for p in pub_graph['packages']}
    if graph[pub_graph['root']]['version'] != version:
        raise ValueError('Pub dependency graph version mismatch')
    for name, package in packages.items():
        if graph[name]['version'] != package['version']:
            raise ValueError(f'Pub graph/lockfile version mismatch: {name}')
    runtime = set()
    pending = list(graph[pub_graph['root']]['directDependencies'])
    while pending:
        name = pending.pop()
        if name not in runtime:
            runtime.add(name)
            pending.extend(graph[name]['dependencies'])
    notices = ''
    with zipfile.ZipFile(args.apk) as apk:
        notices = gzip.decompress(apk.read('assets/flutter_assets/NOTICES.Z')).decode()
        native_files = [name for name in apk.namelist() if re.match(r'lib/[^/]+/.*\.so$', name)]
    pub_dir = kit / 'pub'
    pub_dir.mkdir()

    def package_source(pair):
        name, item = pair
        if item['source'] == 'sdk':
            return {'name': name, **item, 'runtime': name in runtime, 'sourceArchive': 'flutter-sdk.zip'}
        filename = f'{name}-{item["version"]}.tar.gz'
        url = f'https://pub.dev/api/archives/{filename}'
        path = cache / filename
        download(url, path, item['sha256'])
        licenses = []
        with tarfile.open(path) as archive:
            for member in archive.getmembers():
                if member.isfile() and license_name(member.name):
                    data = archive.extractfile(member).read()
                    text = data.decode(errors='replace').replace('\r\n', '\n').strip()
                    # Flutter strips a package-name heading before grouping identical licenses.
                    text = re.sub(r'^\w+\n\n(?=Copyright)', '', text)
                    licenses.append({'file': member.name, 'sha256': hashlib.sha256(data).hexdigest(),
                                     'inFlutterNotices': license_in_notices(text, notices.replace('\r\n', '\n'))})
        if not licenses:
            raise ValueError(f'No license in package archive: {filename}')
        shutil.copyfile(path, pub_dir / filename)
        return {'name': name, **item, 'runtime': name in runtime, 'url': url,
                'sourceArchive': f'pub/{filename}', 'licenses': licenses}

    with ThreadPoolExecutor(max_workers=6) as executor:
        pub = list(executor.map(package_source, packages.items()))
    sdk_revision = git(args.flutter, 'rev-parse', 'HEAD')
    sdk_version = json.loads((args.flutter / 'bin/cache/flutter.version.json').read_text())
    if sdk_revision != sdk_version['frameworkRevision']:
        raise ValueError('SDK revision mismatch')
    tree = subprocess.check_output(['git', '-C', str(args.flutter), 'ls-tree', 'HEAD', '--',
                                   'DEPS', 'engine', 'bin/internal/release-candidate-branch.version'])
    content_hash = hashlib.sha1(b'blob ' + str(len(tree)).encode() + b'\0' + tree).hexdigest()
    if content_hash != sdk_version['engineContentHash']:
        raise ValueError('SDK engine source does not match the prebuilt engine content hash')
    subprocess.run(['git', '-C', str(args.flutter), 'archive', '--format=zip',
                    f'--output={kit / "flutter-sdk.zip"}', sdk_revision], check=True)
    android = []
    android_dir = kit / 'android'
    android_dir.mkdir()
    for item in inventory['components']:
        coordinate = item['coordinate']
        if not item['source'] and not coordinate.startswith('io.flutter:') and any(
                artifact_has_code(path) for path in item['artifacts']):
            raise ValueError(f'Missing resolved Android sources: {coordinate}')
        safe = coordinate.replace(':', '_')
        record = {'coordinate': coordinate, 'binaries': [], 'licenses': [], 'sourceArchive': None}
        for binary in item['artifacts']:
            path = Path(binary)
            record['binaries'].append({'file': path.name, 'sha256': digest(path)})
        if item['source']:
            path = Path(item['source'])
            target = android_dir / f'{safe}-sources.jar'
            shutil.copyfile(path, target)
            record['sourceArchive'] = f'android/{target.name}'
            record['sourceSha256'] = digest(target)
        for pom in item.get('poms', []):
            record['licenses'].extend(pom_licenses(pom))
            shutil.copyfile(pom, android_dir / f'{safe}.pom')
        android.append(record)
    native_config = json.loads((root / 'scripts/release-native-sources.json').read_text())
    resolved_versions = {item['coordinate'].rsplit(':', 1)[0]: item['coordinate'].rsplit(':', 1)[1]
                         for item in inventory['components']}
    resolved_versions['sqlite3'] = packages['sqlite3']['version']
    selected_native = selected_native_sources(native_config, resolved_versions)
    native_coverage = native_library_sources(native_files, native_config, selected_native)
    native_dir = kit / 'native'
    native_dir.mkdir()
    native = []
    for item in selected_native:
        filename = item['name'] + ('.zip' if item['url'].endswith('.zip') else '.tar.gz')
        source = cache / filename
        download(item['url'], source, item['sha256'])
        shutil.copyfile(source, native_dir / filename)
        native.append({**item, 'sourceArchive': f'native/{filename}'})
    collected = json.loads((args.engine_sources / 'manifest.json').read_text())
    if collected['sdkFrameworkRevision'] != sdk_revision:
        raise ValueError('Engine source collection belongs to another SDK')
    engine = collected['sources']
    by_path = {item['path']: item for item in engine}
    def read_deps(item):
        record = by_path[item['path']]
        archive = record['archive']
        if Path(archive).name != archive or digest(args.engine_sources / archive) != record['sha256']:
            raise ValueError('Invalid recursive engine archive')
        return archive_deps(args.engine_sources / archive)
    expected_engine = engine_source_closure((args.flutter / 'DEPS').read_text(), read_deps)
    if {item['path']: {key: item[key] for key in ('path', 'repository', 'revision')} for item in engine} != {
            item['path']: item for item in expected_engine} or len(by_path) != len(engine):
        raise ValueError('Engine source collection does not match recursive pinned DEPS')
    engine_dir = kit / 'engine-deps'
    engine_dir.mkdir()
    for item in engine:
        archive = item['archive']
        if Path(archive).name != archive or not re.fullmatch('[a-f0-9]{64}', item['sha256']):
            raise ValueError('Invalid engine archive metadata')
        original = args.engine_sources / archive
        if digest(original) != item['sha256']: raise ValueError('Engine archive checksum mismatch')
        shutil.copyfile(original, engine_dir / archive)
        item['sourceArchive'] = 'engine-deps/' + archive
    resources = []
    for name in files:
        if name.startswith(('assets/', 'docs/images/concepts/')) and (not args.public or name.startswith('assets/')):
            # Always inventory the bytes in project.zip, even for an older ref.
            committed = subprocess.check_output(['git', '-C', str(root), 'show', f'{commit}:{name}'])
            entry = {'file': name, 'sha256': hashlib.sha256(committed).hexdigest()}
            if name.endswith('.ttf'):
                entry['fontNames'] = font_metadata(committed)
            resources.append(entry)
    gaps = [
        'Native source and build trees are collected, but rebuilding each native library and verifying the complete SDK/build dependency closure remains a separate check.',
        'Recipient access is not established by local export. Distribute only the public-filtered kit and verify its availability alongside the matching APK.'
    ]
    manifest = {'kind': 'release-source-preparation', 'completeCorrespondingSource': False,
                'publicProject': args.public,
                'commit': commit, 'version': version,
                'apk': {'file': args.apk.name, 'sha256': digest(args.apk), 'nativeLibraries': native_files},
                'flutter': sdk_version, 'pub': pub, 'android': android, 'native': native,
                'engineDeps': engine, 'nativeLibrarySources': native_coverage,
                'resources': resources, 'remaining': gaps}
    manifest['archives'] = [{'file': path.relative_to(kit).as_posix(), 'sha256': digest(path)}
                            for path in sorted(kit.rglob('*')) if path.is_file()]
    (kit / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (kit / 'README.txt').write_text(
        'Source preparation, not verified complete corresponding source.\n'
        + ('Project filtered for public distribution.\n' if args.public else 'PRIVATE: project includes internal documentation; do not publish this kit.\n')
        + 'Extract project.zip; use the SDK versions pinned in pubspec.yaml and android/.\n'
        'Run flutter pub get, flutter gen-l10n, dart run build_runner build, then flutter build apk --release.\n'
        'Use your own signing identity; project signing keys are never included.\n'
        'flutter-sdk.zip is the exact pinned SDK Git tree, including engine source and DEPS.\n'
        'engine-deps/ contains pinned root and recursive DEPS Git source archives; CIPD tool pins remain in SDK DEPS.\n'
        'pub/ contains all lockfile package archives verified by their published SHA256.\n'
        'android/ contains resolved Maven source jars and license metadata.\n'
        'native/ contains source and build trees selected from the resolved native dependencies.\n'
        'Signing keys/passwords are intentionally absent; recipients can sign their own build.\n'
        + '\n'.join(gaps) + '\n', encoding='utf-8')
    print(f'Source preparation: {kit}')
    print(f'Pub archives: {sum(p["source"] == "hosted" for p in pub)}; Android modules: {len(android)}')
    print('Runtime license texts absent verbatim from Flutter notices:',
          [p['name'] for p in pub if p['runtime'] and p.get('licenses')
           and not any(license['inFlutterNotices'] for license in p['licenses'])])
    print('Complete corresponding source: false; remaining items are explicit in manifest.json')


if __name__ == '__main__':
    main()
