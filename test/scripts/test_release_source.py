import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('release_source', ROOT / 'scripts/export-release-source.py')
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)


class SourcePreparationTests(unittest.TestCase):
    def test_engine_deps_parser_rejects_execution_and_unpinned_sources(self):
        prefix = "vars = {'revision': '" + 'a' * 40 + "'}\n"
        parsed = source.engine_sources(prefix + "deps = {'engine/pkg': 'https://example.com/repo@' + Var('revision')}\n")
        self.assertEqual(parsed[0]['revision'], 'a' * 40)
        for expression in ["__import__('os').system('echo unsafe')", "'https://example.com/repo@main'"]:
            with self.assertRaises(ValueError):
                source.engine_sources(prefix + "deps = {'engine/pkg': " + expression + "}\n")

    def test_real_lockfile_is_complete_and_custom_hosts_fail_closed(self):
        text = (ROOT / 'pubspec.lock').read_text()
        packages = source.lock_packages(text)
        self.assertEqual(packages['sqlite3']['version'], '3.7.0')
        self.assertIn('flutter', packages)
        with self.assertRaises(ValueError):
            source.lock_packages(text.replace('https://pub.dev', 'https://other.example'))
        with self.assertRaises(ValueError):
            source.lock_packages(text.replace('source: hosted', 'source: git', 1))

    def test_private_files_are_rejected_before_git_archive(self):
        source.verify_project_files(['LICENSE', 'lib/main.dart', 'pubspec.lock'])
        for name in ['.local/signing/signing.json', 'android/local.properties',
                     'nested/.env', 'key.P12', '.aws/config', 'build/output.apk']:
            with self.subTest(name=name), self.assertRaises(ValueError):
                source.verify_project_files(['lib/main.dart', name])

    def test_cached_download_is_not_trusted_without_matching_lock_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'package.tar.gz'
            path.write_bytes(b'wrong archive')
            with self.assertRaises(ValueError):
                source.download('https://pub.dev/unused', path, '0' * 64)

    def test_flutter_license_blocks_can_be_deduplicated_and_regrouped(self):
        license = 'package_a\n\nCopyright A.\nTerms A.\n' + '-' * 80 + '\npackage_b\n\nCopyright B.\nTerms B.'
        notices = 'package_b\nCopyright B. Terms B.\n\npackage_a\nCopyright A. Terms A.'
        self.assertTrue(source.license_in_notices(license, notices))
        self.assertFalse(source.license_in_notices(license, notices.replace('Terms B.', 'Other terms.')))

    def test_bundled_font_licenses_match_the_actual_font_metadata(self):
        families = {'sans': 'roboto', 'serif': 'notoserif',
                    'mono': 'robotomono', 'condensed': 'robotocondensed'}
        for filename, family in families.items():
            with self.subTest(font=filename):
                metadata = source.font_metadata(ROOT / f'assets/fonts/{filename}.ttf')
                license = (ROOT / f'assets/fonts/LICENSE_{family}.txt').read_text()
                if 'Apache' in metadata['13']:
                    self.assertIn('Apache License', license)
                    self.assertIn(metadata['0'], license)
                else:
                    self.assertIn('SIL Open Font License', license)
                if filename == 'condensed':
                    self.assertNotIn('SIL Open Font License', license)


if __name__ == '__main__':
    unittest.main()
