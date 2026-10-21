"""Check Russian/English documentation pairs, freshness, structure, and links.

--update records both file hashes after the author has synchronized the text;
it never translates content or certifies its meaning.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
PUBLIC_MANIFEST = 'docs/translation_manifest.json'
USER_SOURCES = ('README.md', 'docs/README.md', 'docs/USER_GUIDE_RU.md')


def english_path(path):
    return path.with_name(path.stem.removesuffix('_RU') + '_EN' + path.suffix)


def discover(root):
    return [(Path(name), english_path(Path(name))) for name in USER_SOURCES]


def digest(path):
    # Git CRLF conversion must not invalidate manifests on another OS.
    return hashlib.sha256(path.read_bytes().replace(b'\r\n', b'\n')).hexdigest()


def slug(title):
    title = re.sub(r'`|\*|<[^>]+>', '', title).lower()
    return re.sub(r'[^\w\-\s]', '', title).replace(' ', '-')


def without_code(text):
    return re.sub(r'^```[^\n]*\n.*?^```[^\n]*$', '', text, flags=re.M | re.S)


def anchors(text):
    text = without_code(text)
    found = set(re.findall(r'<a\s+(?:id|name)="([^"]+)"', text))
    counts = {}
    for heading in re.findall(r'^#{1,6}\s+(.+)$', text, re.M):
        key = slug(heading)
        count = counts.get(key, 0)
        counts[key] = count + 1
        found.add(key + (f'-{count}' if count else ''))
    return found


def code_blocks(text):
    return [(language, body) for language, body in
            re.findall(r'^```([^\n]*)\n(.*?)^```[^\n]*$', text, re.M | re.S)
            if language.strip() != 'mermaid']


def check_pair(root, source, english):
    errors = []
    if not (root / source).exists():
        return [f'Missing user documentation: {source.as_posix()}']
    if not (root / english).exists():
        return [f'Missing English edition: {english.as_posix()}']
    a, b = ((root / path).read_text(encoding='utf-8') for path in (source, english))
    if code_blocks(a) != code_blocks(b):
        errors.append(f'Code blocks differ: {source} / {english}')
    if len(re.findall(r'^#{1,6}\s', a, re.M)) != len(re.findall(r'^#{1,6}\s', b, re.M)):
        errors.append(f'Heading count differs: {source} / {english}')
    for path, text, other in ((source, a, english), (english, b, source)):
        if f']({other.name})' not in text:
            errors.append(f'Missing language switch in {path}')
        if re.search(r'ZXQ\d+QXZ', text):
            errors.append(f'Unresolved translation token in {path}')
        for target in re.findall(r'\]\(([^)\n]+)\)', without_code(text)):
            if re.match(r'^(?:[a-z][a-z0-9+.-]*:|//)', target, re.I):
                continue
            file, _, fragment = target.partition('#')
            destination = ((root / path).parent / unquote(file)).resolve() if file else root / path
            if destination.suffix == '.md' and destination.relative_to(root.resolve()).as_posix() not in {
                    str(item).replace('\\', '/') for pair in discover(root) for item in pair}:
                errors.append(f'User documentation links to private documentation in {path}: {target}')
            if not destination.exists():
                errors.append(f'Broken link in {path}: {target}')
            elif destination.suffix == '.md' and fragment:
                if unquote(fragment) not in anchors(destination.read_text(encoding='utf-8')):
                    errors.append(f'Broken anchor in {path}: {target}')
    return errors


def run(root, update=False):
    pairs = discover(root)
    errors = []
    entries = []
    for source, english in pairs:
        errors.extend(check_pair(root, source, english))
        if not (root / english).exists():
            continue
        entries.append({'ru': source.as_posix(), 'en': english.as_posix(),
                        'ruSha256': digest(root / source), 'enSha256': digest(root / english)})
    if errors:
        return errors
    path = root / PUBLIC_MANIFEST
    expected = {'schema': 1, 'pairs': entries}
    if update:
        path.write_text(json.dumps(expected, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    elif not path.exists() or json.loads(path.read_text(encoding='utf-8')) != expected:
        errors.append(f'Stale/missing translation manifest: {PUBLIC_MANIFEST}; synchronize both editions, then use --update')
    return errors


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--update', action='store_true')
    args = parser.parse_args()
    problems = run(ROOT, args.update)
    if problems:
        print('\n'.join(problems), file=sys.stderr)
        sys.exit(1)
    print('Documentation languages, freshness, code blocks, headings and local links: OK')
