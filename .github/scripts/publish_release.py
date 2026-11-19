"""Publish four verified APKs, or resume only an exactly matching managed draft."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
from urllib.parse import quote

MARKER = 'cutelauncher-release-v1'
AUTHOR = 'github-actions[bot]'


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def notes(repository, tag):
    base = f'https://github.com/{repository}/blob/{quote(tag, safe="")}'
    return (f'[Изменения на русском]({base}/CHANGELOG_RU.md)\n\n'
            f'[Changelog in English]({base}/CHANGELOG_EN.md)\n\n'
            'Поддержать разработчика / Support the developer · '
            '[CloudTips](https://pay.cloudtips.ru/p/118c2a7f) · '
            '[ЮMoney / YooMoney](https://yoomoney.ru/fundraise/1LLAULV57ME.261119)\n')


class GitHub:
    def __init__(self, repository):
        self.repository = repository
        self.base = f'repos/{repository}'

    def api(self, endpoint, method='GET', data=None, paginate=False):
        command = ['gh', 'api', endpoint, '--method', method]
        if paginate:
            command += ['--paginate', '--slurp']
        if data is not None:
            command += ['--input', '-']
        result = subprocess.run(command, input=json.dumps(data) if data is not None else None,
                                capture_output=True, text=True, check=True)
        return json.loads(result.stdout) if result.stdout.strip() else None

    def tag_commit(self, tag):
        obj = self.api(f'{self.base}/git/ref/tags/{quote(tag, safe="")}')['object']
        for _ in range(8):
            if obj['type'] == 'commit':
                return obj['sha']
            if obj['type'] != 'tag':
                break
            obj = self.api(f'{self.base}/git/tags/{obj["sha"]}')['object']
        raise ValueError('Tag does not resolve to a commit')

    def default_branch(self):
        branch = self.api(self.base)['default_branch']
        if not isinstance(branch, str) or not branch:
            raise ValueError('Repository default branch is unavailable')
        return branch

    def find_release(self, tag):
        releases = [release for page in self.api(f'{self.base}/releases?per_page=100', paginate=True)
                    for release in page if release['tag_name'] == tag]
        if len(releases) > 1:
            raise ValueError('Multiple releases for the tag')
        return releases[0] if releases else None

    def get_release(self, release_id):
        endpoint = f'{self.base}/releases/{release_id}'
        for delay in (1, 2, 4, 0):
            try:
                release = self.api(endpoint)
                if release['id'] != release_id:
                    raise ValueError('Draft identity changed')
                release['assets'] = [asset for page in self.api(
                    f'{endpoint}/assets?per_page=100', paginate=True) for asset in page]
                return release
            except subprocess.CalledProcessError as error:
                # GitHub may briefly return 404 for a newly created draft.
                if not delay or not re.search(r'\(HTTP 404\)\s*$', error.stderr or ''):
                    raise
                time.sleep(delay)

    def create(self, data):
        return self.api(f'{self.base}/releases', 'POST', data)

    def upload(self, release_id, path):
        endpoint = (f'https://uploads.github.com/{self.base}/releases/{release_id}/assets'
                    f'?name={quote(path.name, safe="")}')
        subprocess.run(['gh', 'api', endpoint, '--method', 'POST',
                        '-H', 'Content-Type: application/vnd.android.package-archive',
                        '--input', str(path)], check=True, capture_output=True)

    def publish(self, release_id, data):
        return self.api(f'{self.base}/releases/{release_id}', 'PATCH', data)


def check_draft(release, manifest):
    if not release.get('draft'):
        raise ValueError('Release is already published; never modify published APKs')
    if (release.get('tag_name') != manifest['tag']
            or release.get('author', {}).get('login') != AUTHOR):
        raise ValueError('Draft tag or owner differs')
    match = re.fullmatch(r'.*\n<!-- ' + MARKER + r' (\{[^\n]+\}) -->\n?', release.get('body', ''), re.S)
    if not match or json.loads(match[1]) != manifest:
        raise ValueError('Draft manifest differs or is unmanaged')
    assets = {}
    for asset in release.get('assets', []):
        name = asset['name']
        expected = manifest['apks'].get(name)
        if (name in assets or expected is None or asset.get('state') != 'uploaded'
                or asset.get('size') != expected['bytes']
                or asset.get('digest') != 'sha256:' + expected['sha256']):
            # A starter/partial or mismatched asset is not safe to replace.
            raise ValueError(f'Unverified draft asset: {name}')
        assets[name] = asset
    return assets


def publish_release(github, repository, tag, version, build, commit, folder):
    if tag not in {'v' + version, 'v' + version + '+' + build}:
        raise ValueError('Tag and APK version differ')
    if not re.fullmatch(r'[0-9a-f]{40}', commit) or github.tag_commit(tag) != commit:
        raise ValueError('Remote tag does not resolve to the expected commit')
    expected = {f'CuteLauncher-{version}-{abi}-release.apk'
                for abi in ('universal', 'armeabi-v7a', 'arm64-v8a', 'x86_64')}
    files = {p.name: p for p in folder.glob('*.apk')}
    if (set(files) != expected or any(p.is_symlink() or not p.is_file() or p.stat().st_size == 0
                                      for p in files.values())):
        raise ValueError('Expected exactly four nonempty regular APK files')
    manifest = {'repository': repository, 'tag': tag, 'version': version,
                'build': build, 'commit': commit,
                'apks': {name: {'bytes': path.stat().st_size, 'sha256': sha256(path)}
                         for name, path in sorted(files.items())}}
    body = notes(repository, tag)
    release = github.find_release(tag)
    if release is None:
        # The tag already exists and was peeled above. A SHA target_commitish can
        # require Workflows write when old-tag workflows differ from default HEAD.
        release = github.create({'tag_name': tag, 'draft': True,
                                 'prerelease': '-' in version, 'name': f'CuteLauncher {version}',
                                 'body': body + '\n<!-- ' + MARKER + ' ' + json.dumps(manifest, sort_keys=True) + ' -->\n'})
    release_id = release['id']
    for name, path in sorted(files.items()):
        # Re-read before each mutation: another actor may have published or edited the draft.
        current = github.get_release(release_id)
        existing = check_draft(current, manifest)
        if name not in existing:
            if sha256(path) != manifest['apks'][name]['sha256']:
                raise ValueError('Local APK changed during publication')
            github.upload(release_id, path)  # No clobber/delete, including partial assets.
    default_branch = github.default_branch()
    current = github.get_release(release_id)
    if github.tag_commit(tag) != commit:
        raise ValueError('Tag commit changed')
    if set(check_draft(current, manifest)) != expected:
        raise ValueError('Draft does not contain all four verified APKs')
    # For an existing tag, target_commitish does not move the tag. Reset an old
    # SHA target to the current default branch in this same PATCH, so GitHub's
    # update permission check does not require Workflows write for that old SHA.
    # Strip the marker and publish atomically, never an intermediate unmarked draft.
    github.publish(release_id, {'body': body, 'draft': False, 'prerelease': '-' in version,
                                'target_commitish': default_branch,
                                'make_latest': 'false' if '-' in version else 'true'})


def main():
    from validate_release import validate
    from verify_apks import verify
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path)
    parser.add_argument('tag')
    parser.add_argument('version')
    parser.add_argument('build')
    args = parser.parse_args()
    version, build = validate(args.tag, Path('pubspec.yaml').read_text(encoding='utf-8'))
    if (version, build) != (args.version, args.build):
        raise ValueError('Release inputs differ from checked-out pubspec')
    def git_commit(ref):
        return subprocess.run(['git', 'rev-parse', '--verify', '--end-of-options', ref],
                              check=True, capture_output=True, text=True).stdout.strip()
    commit = git_commit('HEAD^{commit}')
    if commit != git_commit(f'refs/tags/{args.tag}^{{commit}}') or commit != os.environ['GITHUB_SHA']:
        raise ValueError('HEAD, peeled tag and workflow commit differ')
    verify(args.folder, version, build, Path(os.environ['ANDROID_HOME']), signed=True)
    repository = os.environ['GITHUB_REPOSITORY']
    publish_release(GitHub(repository), repository, args.tag, version, build, commit, args.folder)
    print(f'Published four verified APKs: {args.tag}')


if __name__ == '__main__':
    main()
