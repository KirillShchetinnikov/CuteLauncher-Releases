import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('docs_languages', ROOT / 'scripts/check-docs.py')
docs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(docs)


class DocumentationLanguageTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / 'docs').mkdir()
        self.ru = Path('README.md')
        self.en = Path('README_EN.md')
        self.write(self.ru, '# Русский\n\n[English](README_EN.md)\n\n## Раздел\n\n```sh\necho test\n```\n')
        self.write(self.en, '# English\n\n[Русский](README.md)\n\n## Section\n\n```sh\necho test\n```\n')
        self.discovery = patch.object(docs, 'discover', return_value=[(self.ru, self.en)])
        self.discovery.start()
        self.addCleanup(self.discovery.stop)

    def write(self, name, content):
        (self.root / name).write_bytes(content.encode('utf-8'))

    def test_stale_source_or_translation_requires_explicit_manifest_update(self):
        self.assertEqual(docs.run(self.root, update=True), [])
        self.assertEqual(docs.run(self.root), [])
        for name in (self.ru, self.en):
            with self.subTest(name=name):
                with (self.root / name).open('a', encoding='utf-8') as stream:
                    stream.write('\nNew information.\n')
                self.assertTrue(any('Stale' in error for error in docs.run(self.root)))
                self.assertEqual(docs.run(self.root, update=True), [])

    def test_missing_translation_and_changed_commands_fail(self):
        (self.root / self.en).unlink()
        self.assertTrue(any('Missing English' in error for error in docs.run(self.root, True)))
        self.write(self.en, '# English\n\n[Русский](README.md)\n\n## Section\n\n```sh\necho different\n```\n')
        self.assertTrue(any('Code blocks differ' in error for error in docs.run(self.root, True)))

    def test_links_and_heading_aliases_are_validated(self):
        with (self.root / self.en).open('a', encoding='utf-8') as stream:
            stream.write('\n[Broken](README.md#missing)\n')
        self.assertTrue(any('Broken anchor' in error for error in docs.run(self.root, True)))
        with (self.root / self.ru).open('a', encoding='utf-8') as stream:
            stream.write('\n<a id="missing"></a>\n')
        self.assertEqual(docs.run(self.root, True), [])

    def test_manifest_hashes_are_portable_between_lf_and_crlf(self):
        self.assertEqual(docs.run(self.root, True), [])
        for name in (self.ru, self.en):
            path = self.root / name
            path.write_bytes(path.read_bytes().replace(b'\n', b'\r\n'))
        self.assertEqual(docs.run(self.root), [])

    def test_private_documents_do_not_require_translation(self):
        (self.root / 'docs/ARCHITECTURE_RU.md').write_text('Private technical notes')
        self.assertEqual(docs.run(self.root, True), [])
        self.assertEqual(docs.run(self.root), [])

    def test_user_pages_cannot_link_to_private_documents(self):
        (self.root / 'docs/ARCHITECTURE_RU.md').write_text('Private technical notes')
        with (self.root / self.en).open('a', encoding='utf-8') as stream:
            stream.write('\n[Internal](docs/ARCHITECTURE_RU.md)\n')
        self.assertTrue(any('links to private' in error for error in docs.run(self.root, True)))

    def test_new_release_requires_both_dated_changelog_entries(self):
        tag = 'v1.0.25+74'
        self.assertEqual(len(docs.check_release_notes(self.root, tag)), 2)
        self.write(Path('CHANGELOG_RU.md'), f'# История\n\n## {tag} — 2026-10-21\n\n- Исправление.\n')
        self.assertTrue(any('CHANGELOG_EN.md' in error for error in docs.check_release_notes(self.root, tag)))
        self.write(Path('CHANGELOG_EN.md'), f'# Changelog\n\n## {tag} — 2026-10-21\n\n- Fix.\n')
        self.assertEqual(docs.check_release_notes(self.root, tag), [])
        self.assertTrue(docs.check_release_notes(self.root, 'v1.0.25+75'))

    def test_changelog_mismatched_dates_and_empty_entries_fail(self):
        tag = 'v1.0.25+74'
        self.write(Path('CHANGELOG_RU.md'), f'# История\n\n## {tag} — 2026-10-21\n\n- Исправление.\n')
        self.write(Path('CHANGELOG_EN.md'), f'# Changelog\n\n## {tag} — 2026-10-22\n\n')
        errors = docs.check_release_notes(self.root, tag)
        self.assertTrue(any('dates differ' in error for error in errors))
        self.assertTrue(any('Empty release' in error for error in errors))

    def test_changelog_duplicate_entries_invalid_dates_and_tags_fail(self):
        tag = 'v1.0.25-test.1+74'
        for name in ('CHANGELOG_RU.md', 'CHANGELOG_EN.md'):
            self.write(Path(name), f'## {tag} — 2026-10-21\n\n- Fix.\n')
        self.assertEqual(docs.check_release_notes(self.root, tag), [])
        with (self.root / 'CHANGELOG_RU.md').open('a', encoding='utf-8') as stream:
            stream.write(f'\n## {tag} — 2026-10-21\n\n- Duplicate.\n')
        self.assertTrue(any('Expected one' in error for error in docs.check_release_notes(self.root, tag)))
        self.write(Path('CHANGELOG_RU.md'), f'## {tag} — 2026-02-31\n\n- Fix.\n')
        self.assertTrue(any('Invalid release date' in error for error in docs.check_release_notes(self.root, tag)))
        self.assertEqual(docs.check_release_notes(self.root, 'main'), ['Unsupported changelog release tag'])

    def test_each_language_must_link_back_to_its_counterpart(self):
        self.write(self.en, '# English\n\n## Section\n\n```sh\necho test\n```\n')
        self.assertTrue(any('Missing language switch' in error for error in docs.run(self.root, True)))

    def test_release_gate_runs_before_manifest_update(self):
        self.assertTrue(docs.run(self.root, update=True, release_tag='v1.0.25+74'))
        self.assertFalse((self.root / docs.PUBLIC_MANIFEST).exists())

    def test_every_public_markdown_document_has_a_language_pair(self):
        publisher_spec = importlib.util.spec_from_file_location('public_docs', ROOT / 'scripts/publish-source.py')
        publisher = importlib.util.module_from_spec(publisher_spec)
        publisher_spec.loader.exec_module(publisher)
        paired = {path.as_posix() for name in docs.USER_SOURCES
                  for path in (Path(name), docs.english_path(Path(name)))}
        self.assertEqual(paired, publisher.PUBLIC_DOCS)


if __name__ == '__main__':
    unittest.main()
