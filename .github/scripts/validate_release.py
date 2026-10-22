"""Require a tag matching pubspec and an explicit build number."""
import os
from pathlib import Path
import re
import subprocess
import sys


def validate(tag, pubspec, published_tags=()):
    match = re.search(r'^version:\s*(\S+)\s*$', pubspec, re.MULTILINE)
    if not match or not re.fullmatch(
        r'\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\+[1-9]\d*', match[1]
    ) or tag not in {'v' + match[1].split('+')[0], 'v' + match[1]}:
        raise ValueError('Tag must match the pubspec version: vMAJOR.MINOR.PATCH[-test.N]')
    version, build = match[1].rsplit('+', 1)
    published_builds = [int(item.rsplit('+', 1)[1]) for item in published_tags
                        if re.fullmatch(r'v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\+\d+', item)]
    if published_builds and int(build) <= max(published_builds):
        raise ValueError('Build must exceed every published build, including prereleases')
    return version, build


if __name__ == '__main__':
    tags = Path(sys.argv[2]).read_text(encoding='utf-8-sig').splitlines() if len(sys.argv) > 2 else []
    # New tags omit build metadata; recover their internal versionCode from source.
    published = list(tags)
    for tag in tags:
        if re.fullmatch(r'v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?', tag):
            result = subprocess.run(['git', 'show', f'refs/tags/{tag}:pubspec.yaml'],
                                    check=True, capture_output=True, text=True)
            previous = re.search(r'^version:\s*(\S+)\s*$', result.stdout, re.M)
            if not previous:
                raise ValueError(f'Missing source version for published tag {tag}')
            published.append('v' + previous[1])
    version, build = validate(sys.argv[1], Path('pubspec.yaml').read_text(), published)
    if os.environ.get('GITHUB_ENV'):
        with open(os.environ['GITHUB_ENV'], 'a') as stream:
            stream.write(f'RELEASE_VERSION={version}\nRELEASE_BUILD={build}\n'
                         f'RELEASE_TITLE=CuteLauncher {version}\n')
