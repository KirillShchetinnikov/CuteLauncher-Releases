"""Check the exact four release APKs before signing and before publication."""
import argparse
import os
from pathlib import Path
import re
import subprocess
from zipfile import ZipFile


CERTIFICATE = 'c503e78d308fcde372b136beb5fed0f0b8d58739eac5e7f84258f630eda06b60'
APPLICATION_ID = 'io.github.kirillshchetinnikov.cutelauncher'
ABIS = {'armeabi-v7a', 'arm64-v8a', 'x86_64'}


def check_files(folder, version):
    expected = {
        f'CuteLauncher-{version}-{abi}-release.apk': ABIS if abi == 'universal' else {abi}
        for abi in ('universal', *sorted(ABIS))
    }
    files = {apk.name: apk for apk in folder.glob('*.apk')}
    if files.keys() != expected.keys():
        raise ValueError(f'Unexpected APK names: {sorted(files)}')
    for name, apk in files.items():
        if apk.is_symlink():
            raise ValueError(f'Symlink is not an APK input: {name}')
        with ZipFile(apk) as archive:
            abis = {name.split('/')[1] for name in archive.namelist()
                    if name.startswith('lib/') and name.endswith('.so')}
        if abis != expected[name]:
            raise ValueError(f'Unexpected ABI composition: {name}: {sorted(abis)}')
    return files.values()


def run(*args):
    return subprocess.run([str(arg) for arg in args], check=True,
                          capture_output=True, text=True).stdout.strip()


def verify(folder, version, build, android_home, signed=False):
    files = check_files(folder, version)
    tools = sorted((android_home / 'build-tools').iterdir(),
                   key=lambda path: tuple(int(x) for x in re.findall(r'\d+', path.name)))[-1]
    extension = '.bat' if os.name == 'nt' else ''
    analyzer = android_home / 'cmdline-tools/latest/bin' / ('apkanalyzer' + extension)
    signer = tools / ('apksigner' + extension)
    for apk in files:
        for field, expected in (('application-id', APPLICATION_ID),
                                ('version-name', version), ('version-code', str(build))):
            if run(analyzer, 'manifest', field, apk) != expected:
                raise ValueError(f'Unexpected {field}: {apk.name}')
        if signed:
            output = run(signer, 'verify', '--print-certs', apk)
            # Build Tools 37 uses "V2 Signer:" instead of "Signer #1".
            # A certificate may be reported once per signature scheme.
            certificates = re.findall(
                r'^(?:Signer #\d+|V[234](?:\.\d+)? Signer(?: #\d+)?):? '
                r'certificate SHA-256 digest: ([a-fA-F0-9]{64})[ \t]*$',
                output, re.M)
            if not certificates or {value.lower() for value in certificates} != {CERTIFICATE}:
                raise ValueError(f'Unexpected signing certificate: {apk.name}')
        else:
            result = subprocess.run([str(signer), 'verify', str(apk)], capture_output=True)
            if result.returncode == 0:
                raise ValueError(f'Build must not contain signed APKs: {apk.name}')
    print(f'Verified four {"signed" if signed else "unsigned"} APKs: {version}+{build}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path)
    parser.add_argument('version')
    parser.add_argument('build')
    parser.add_argument('--signed', action='store_true')
    args = parser.parse_args()
    verify(args.folder, args.version, args.build,
           Path(os.environ['ANDROID_HOME']), args.signed)
