"""Require a tag matching pubspec and an explicit build number."""
import os
from pathlib import Path
import re
import sys


def validate(tag, pubspec, published_tags=()):
    match = re.search(r'^version:\s*(\S+)\s*$', pubspec, re.MULTILINE)
    if not match or not re.fullmatch(
        r'v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\+[1-9]\d*', tag
    ) or tag != 'v' + match[1]:
        raise ValueError('Tag must match pubspec: vMAJOR.MINOR.PATCH[-test.N]+BUILD')
    version, build = match[1].rsplit('+', 1)
    published_builds = [int(item.rsplit('+', 1)[1]) for item in published_tags
                        if re.fullmatch(r'v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\+\d+', item)]
    if published_builds and int(build) <= max(published_builds):
        raise ValueError('Build must exceed every published build, including prereleases')
    return version, build


if __name__ == '__main__':
    tags = Path(sys.argv[2]).read_text().splitlines() if len(sys.argv) > 2 else []
    version, build = validate(sys.argv[1], Path('pubspec.yaml').read_text(), tags)
    if os.environ.get('GITHUB_ENV'):
        with open(os.environ['GITHUB_ENV'], 'a') as stream:
            stream.write(f'RELEASE_VERSION={version}\nRELEASE_BUILD={build}\n'
                         f'RELEASE_TITLE=CuteLauncher {version} (build {build})\n')
