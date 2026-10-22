"""Create a public source commit in an independent, already checked-out repository.

No private Git objects or history are copied. Network pushes belong to the workflow.
"""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import tarfile
import tempfile


ROOT_FILES = {
    '.gitignore', '.metadata', 'LICENSE', 'README.md', 'README_EN.md',
    'CHANGELOG_RU.md', 'CHANGELOG_EN.md', 'analysis_options.yaml',
    'build.yaml', 'l10n.yaml', 'pubspec.yaml', 'pubspec.lock',
}
PUBLIC_DIRS = {
    'android', 'assets', 'catalog', 'diagnostics', 'drift_schemas',
    'lib', 'scripts', 'test', 'tools',
}
PUBLIC_DOCS = {
    'README.md', 'README_EN.md', 'docs/README.md', 'docs/README_EN.md',
    'docs/USER_GUIDE_RU.md', 'docs/USER_GUIDE_EN.md',
    'CHANGELOG_RU.md', 'CHANGELOG_EN.md',
}
PUBLIC_DOC_ASSETS = {
    'docs/DADB_LICENSE.txt', 'docs/translation_manifest.json',
    'docs/images/screenshots/01-glass-autumn.webp',
    'docs/images/screenshots/02-glass-settings.webp',
    'docs/images/screenshots/03-calendar.webp',
    'docs/images/screenshots/04-sleep-timer.webp',
    'docs/images/screenshots/05-standard-gradient.webp',
    'docs/images/screenshots/06-sections.webp',
    'docs/images/screenshots/07-soft-spring.webp',
    'docs/images/screenshots/08-top-panel.webp',
    'docs/images/screenshots/09-outline-night.webp',
    'docs/images/screenshots/10-outline-settings.webp',
    'docs/images/screenshots/11-adaptive-wallpaper.webp',
    'docs/images/screenshots/12-tile-appearance.webp',
}
PRIVATE_DIRS = {
    '.git', '.local', '.tools', '.dart_tool', '.codex', '.agents', '.aws',
    '.idea', '.vscode', '.claude', '.gemini', '.qwen', 'node_modules',
    'build', 'artifacts', 'agents',
}
AGENT_FILES = {
    'agents.md', 'agents_en.md', 'agents.override.md', 'claude.md', 'gemini.md', 'qwen.md',
    '.cursorrules',
}
SECRET_FILES = {
    '.env', 'local.properties', 'key.properties', 'keystore.properties',
    'signing.json', 'adbkey', 'adbkey.pub', 'id_rsa', 'id_ed25519',
    'google_play_api_key.json',
}
MANIFEST = 'PUBLIC_SOURCE.json'
REQUIRED = {
    'LICENSE', 'README.md', 'pubspec.yaml', 'pubspec.lock', 'lib/main.dart',
    'android/app/build.gradle', 'android/settings.gradle',
    'android/gradle/wrapper/gradle-wrapper.properties', 'scripts/build-apk.ps1',
    'docs/USER_GUIDE_RU.md',
}
SECRET_CONTENT = re.compile(
    rb'-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----'
    rb'|(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})'
    rb'|AIza[0-9A-Za-z_-]{35}'
)
# Public dummy key for localhost HTTPS tests, documented beside the fixture.
# Only this exact committed content is allowed, never arbitrary test keys.
PUBLIC_TEST_FIXTURES = {
    'test/fixtures/cloud/test_key.txt':
        '90b2445d2be5939fb236d013897fa8b6ba3e4b4e1e6ec80cb79af8262255909a',
}


def git(root, *args, check=True):
    return subprocess.run(['git', '-C', str(root), *args], check=check,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def public_path(name):
    path = PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or '\\' in name:
        raise ValueError(f'Unsafe source path: {name}')
    lowered = [part.lower() for part in path.parts]
    if (any(part in PRIVATE_DIRS for part in lowered)
            or path.name.lower() in AGENT_FILES
            or name.startswith('.github/workflows/')):
        return False
    if path.suffix.lower() == '.md':
        return name in PUBLIC_DOCS
    if path.parts[0] == 'docs':
        return name in PUBLIC_DOC_ASSETS
    allowed = (name in ROOT_FILES or path.parts[0] in PUBLIC_DIRS
               or name.startswith('.github/scripts/'))
    if not allowed:
        return False  # New top-level directories require an explicit decision.
    basename = path.name.lower()
    if (basename in SECRET_FILES or basename.startswith('.env.')
            or path.suffix.lower() in {'.p12', '.pfx', '.jks', '.keystore', '.pem', '.key', '.apk', '.aab'}):
        raise ValueError(f'Private/build-only file in public source selection: {name}')
    return True


def source_files(root, commit):
    selected = {}
    tree = git(root, 'ls-tree', '-r', '-z', commit).stdout
    for entry in tree.split(b'\0'):
        if not entry:
            continue
        metadata, raw_name = entry.split(b'\t', 1)
        mode, kind, _ = metadata.split()
        name = raw_name.decode('utf-8')
        if public_path(name):
            if kind != b'blob' or mode not in {b'100644', b'100755'}:
                raise ValueError(f'Symlinks and submodules need explicit review: {name}')
            selected[name] = mode
    missing = REQUIRED - selected.keys()
    if missing:
        raise ValueError(f'Missing source/build files: {sorted(missing)}')
    return selected


def export(root, commit, selected, destination):
    process = subprocess.Popen(['git', '-C', str(root), '-c', 'core.autocrlf=false',
                                '-c', 'core.eol=lf', 'archive', '--format=tar', commit],
                               stdout=subprocess.PIPE)
    copied = set()
    try:
        with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
            for member in archive:
                if member.name not in selected:
                    continue
                if not member.isfile():
                    raise ValueError(f'Unexpected archive entry: {member.name}')
                target = destination / member.name
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.extractfile(member) as source, target.open('wb') as output:
                    overlap = b''
                    digest = hashlib.sha256()
                    suspicious = False
                    while chunk := source.read(1024 * 1024):
                        if SECRET_CONTENT.search(overlap + chunk):
                            suspicious = True
                        digest.update(chunk)
                        output.write(chunk)
                        overlap = chunk[-512:]
                if suspicious and PUBLIC_TEST_FIXTURES.get(member.name) != digest.hexdigest():
                    raise ValueError(f'Credential-like content in selected file: {member.name}')
                target.chmod(member.mode & 0o777)
                copied.add(member.name)
        # tarfile stops at end markers before Git finishes writing padding.
        # Drain the pipe to avoid a broken-pipe exit, notably on Windows.
        while process.stdout.read(1024 * 1024):
            pass
    finally:
        process.stdout.close()
        returncode = process.wait()
    if returncode or copied != selected.keys():
        raise ValueError(f'Source archive mismatch: git exit {returncode}; '
                         f'missing files {sorted(selected.keys() - copied)}')


def snapshot(root, ref, destination, release_tag=''):
    root, destination = root.resolve(), destination.resolve()
    commit = git(root, 'rev-parse', '--verify', '--end-of-options', f'{ref}^{{commit}}').stdout.decode().strip()
    selected = source_files(root, commit)
    spec = git(root, 'show', f'{commit}:pubspec.yaml').stdout.decode()
    version = re.search(r'^version:\s*(\d+\.\d+\.\d+(?:-test\.\d+)?\+\d+)\s*$', spec, re.M)
    if not version:
        raise ValueError('Unsupported source version')
    version = version[1]
    if release_tag:
        if release_tag != 'v' + version:
            raise ValueError('Release tag must equal v + pubspec version')
        tagged = git(root, 'rev-parse', '--verify', f'refs/tags/{release_tag}^{{commit}}').stdout.decode().strip()
        if tagged != commit:
            raise ValueError('Release tag and source commit differ')
    source_git = git(root, 'rev-parse', '--absolute-git-dir').stdout.strip()
    public_git = git(destination, 'rev-parse', '--absolute-git-dir').stdout.strip()
    if source_git == public_git or destination == root or root in destination.parents:
        raise ValueError('Public checkout must be independent of the private repository')
    if git(destination, 'status', '--porcelain', '--untracked-files=all').stdout:
        raise ValueError('Public checkout must be clean')

    # Validate and prepare everything before changing the public checkout.
    with tempfile.TemporaryDirectory() as directory:
        prepared = Path(directory)
        export(root, commit, selected, prepared)
        old_manifest = destination / MANIFEST
        previous_manifest = old_manifest.read_bytes() if old_manifest.exists() else None
        git(destination, 'rm', '-r', '-f', '--ignore-unmatch', '--', '.')
        for name in sorted(selected):
            source, target = prepared / name, destination / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read_bytes())
            target.chmod(source.stat().st_mode & 0o777)
        if previous_manifest is not None:
            old_manifest.write_bytes(previous_manifest)
        # Force-add committed source even if its private .gitignore excludes it
        # (e.g. migration schemas and Python diagnostic tools).
        names = sorted(selected) + ([MANIFEST] if previous_manifest is not None else [])
        subprocess.run(['git', '-C', str(destination), '--literal-pathspecs', 'add', '-f',
                        '--pathspec-from-file=-', '--pathspec-file-nul'],
                       input=b'\0'.join(name.encode() for name in names) + b'\0', check=True)
        # core.filemode=false on Windows must not strip executable bits.
        index = git(destination, 'ls-files', '--stage', '-z').stdout
        records = []
        for entry in index.split(b'\0'):
            if entry:
                metadata, name = entry.split(b'\t', 1)
                mode, oid, stage = metadata.split()
                mode = selected.get(name.decode('utf-8'), mode)
                records.append(mode + b' ' + oid + b' ' + stage + b'\t' + name)
        subprocess.run(['git', '-C', str(destination), 'update-index', '-z', '--index-info'],
                       input=b'\0'.join(records) + b'\0', check=True)
        changes = git(destination, 'diff', '--cached', '--quiet', check=False)
        if changes.returncode not in (0, 1):
            raise ValueError('Cannot compare public source tree')
        if changes.returncode == 1:
            manifest = {
                'kind': 'public-project-source', 'version': version,
                'sourceCommit': commit, 'completeCorrespondingSource': False,
                'history': 'Independent public snapshots; private history is not included.',
            }
            old_manifest.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
            git(destination, 'add', '-f', '--', MANIFEST)
            git(destination, '-c', 'user.name=KirillShchetinnikov',
                '-c', 'user.email=kipik666@gmail.com', 'commit', '-m',
                f'Publish source {version}\n\nSource commit: {commit}')
            print(f'Created public snapshot for {version} ({commit[:12]})')
        else:
            print('Public source unchanged; reusing existing public commit')
    if release_tag:
        existing = git(destination, 'rev-parse', '--verify', f'refs/tags/{release_tag}', check=False)
        if existing.returncode == 0:
            old_tree = git(destination, 'rev-parse', f'refs/tags/{release_tag}^{{tree}}').stdout
            new_tree = git(destination, 'rev-parse', 'HEAD^{tree}').stdout
            if old_tree != new_tree:
                raise ValueError('Existing public tag points to different source; never overwrite it')
        else:
            git(destination, 'tag', release_tag)
    return commit


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--ref', required=True)
    parser.add_argument('--destination', type=Path, required=True)
    parser.add_argument('--release-tag', default='')
    args = parser.parse_args()
    snapshot(args.source, args.ref, args.destination, args.release_tag)


if __name__ == '__main__':
    main()
