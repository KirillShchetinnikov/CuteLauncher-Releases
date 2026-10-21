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


if __name__ == '__main__':
    unittest.main()
