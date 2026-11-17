"""Archive one R8 pass before Gradle's next build overwrites its mapping."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import tempfile


def digest(path):
    if path.is_symlink() or not path.is_file() or path.stat().st_size == 0:
        raise ValueError(f'Expected a nonempty regular file: {path.name}')
    with path.open('rb') as stream:
        return {'bytes': path.stat().st_size,
                'sha256': hashlib.file_digest(stream, 'sha256').hexdigest()}


def archive(mapping, output, pass_name, version, build, commit, apks, build_id):
    if pass_name not in {'arm', 'x64'} or not re.fullmatch(r'[0-9a-f]{40}', commit) or not build_id:
        raise ValueError('Invalid pass, source commit or build identity')
    allowed = {'x86_64'} if pass_name == 'x64' else {'universal', 'armeabi-v7a', 'arm64-v8a'}
    names = {f'CuteLauncher-{version}-{abi}-release.apk' for abi in allowed}
    if not apks or len({p.name for p in apks}) != len(apks) or any(p.name not in names for p in apks):
        raise ValueError('APK names do not match the R8 pass and version')
    identity = {'version': f'{version}+{build}', 'commit': commit, 'buildId': build_id}
    if output.is_symlink():
        raise ValueError('Symbol output must not be a symlink')
    for previous in output.glob('*/build.json'):
        data = json.loads(previous.read_text(encoding='utf-8'))
        if any(data.get(key) != value for key, value in identity.items()):
            raise ValueError('Different build identity already exists in symbol output')
    destination = output / pass_name
    if destination.exists():
        raise ValueError('R8 pass already archived; never overwrite symbols')
    source_files = [mapping / 'mapping.txt']
    if (mapping / 'configuration.txt').exists():
        source_files.append(mapping / 'configuration.txt')
    metadata = dict(identity, passName=pass_name,
                    apks={p.name: digest(p) for p in apks},
                    files={p.name: digest(p) for p in source_files})
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.r8-', dir=output) as temporary:
        prepared = Path(temporary) / pass_name
        prepared.mkdir()
        for source in source_files:
            shutil.copyfile(source, prepared / source.name)
            if digest(prepared / source.name) != metadata['files'][source.name]:
                raise ValueError('R8 output changed while archiving')
        (prepared / 'build.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
        prepared.rename(destination)
    print(f'Archived R8 {pass_name}: {destination}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mapping', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--pass-name', choices=('arm', 'x64'), required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--build', required=True)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--build-id', required=True)
    parser.add_argument('--apk', type=Path, action='append', required=True)
    args = parser.parse_args()
    archive(args.mapping, args.output, args.pass_name, args.version, args.build,
            args.commit, args.apk, args.build_id)
