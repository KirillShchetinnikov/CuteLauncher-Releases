import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('release_source', ROOT / 'scripts/export-release-source.py')
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)


class SourcePreparationTests(unittest.TestCase):
    def test_new_native_libraries_cannot_silently_escape_the_source_inventory(self):
        config = json.loads((ROOT / 'scripts/release-native-sources.json').read_text())
        selected = source.selected_native_sources(config, {'sqlite3': '3.7.0'})
        names = ['lib/arm64-v8a/libapp.so', 'lib/arm64-v8a/libflutter.so', 'lib/arm64-v8a/libsqlite3.so']
        coverage = source.native_library_sources(names, config, selected)
        self.assertEqual(coverage[names[-1]], ['sqlite3-dart', 'sqlite-amalgamation'])
        for name in ['lib/arm64-v8a/libunknown.so', 'lib/arm64-v8a/libdatastore_shared_counter.so']:
            with self.subTest(name=name), self.assertRaises(ValueError):
                source.native_library_sources([name], config, selected)

    def test_recursive_deps_are_pinned_and_relative_to_the_parent(self):
        root = "vars = {}\ndeps = {'engine/vulkan': 'https://example.com/vulkan@" + 'a' * 40 + "'}\nrecursedeps = ['engine/vulkan']\n"
        nested = "use_relative_paths = True\nvars = {'rev': '" + 'b' * 40 + "'}\ndeps = {'headers/src': {'url': 'https://example.com/headers@{rev}'}}\n"
        result = source.engine_source_closure(root, lambda item: nested)
        self.assertEqual([item['path'] for item in result], ['engine/vulkan', 'engine/vulkan/headers/src'])
        self.assertEqual(result[1]['revision'], 'b' * 40)
        for bad in [nested.replace('{rev}', 'main'), nested.replace('headers/src', '../escape')]:
            with self.assertRaises(ValueError):
                source.engine_source_closure(root, lambda item: bad)
        with self.assertRaises(ValueError):
            source.engine_source_closure(root.replace("['engine/vulkan']", "['absent']"), lambda item: nested)

    def test_empty_maven_placeholder_is_distinct_from_code_without_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'artifact.aar'
            with zipfile.ZipFile(path, 'w') as archive:
                archive.writestr('META-INF/MANIFEST.MF', 'Manifest-Version: 1.0\n')
            self.assertFalse(source.artifact_has_code(path))
            nested = io.BytesIO()
            with zipfile.ZipFile(nested, 'w') as archive:
                archive.writestr('package/Actual.class', b'bytecode')
            with zipfile.ZipFile(path, 'w') as archive:
                archive.writestr('classes.jar', nested.getvalue())
            self.assertTrue(source.artifact_has_code(path))

    def test_removed_native_dependencies_do_not_block_current_releases(self):
        config = json.loads((ROOT / 'scripts/release-native-sources.json').read_text())
        resolved = {'sqlite3': '3.7.0', 'androidx.datastore:datastore-core-android': '1.1.7'}
        selected = source.selected_native_sources(config, resolved)
        self.assertEqual({item['name'] for item in selected},
                         {'androidx-support', 'sqlite3-dart', 'sqlite-amalgamation'})
        for coordinate in resolved:
            with self.subTest(coordinate=coordinate), self.assertRaises(ValueError):
                source.selected_native_sources(config, {**resolved, coordinate: '999.0'})
        with self.assertRaises(ValueError):
            source.selected_native_sources({'versions': {}, 'sources': [{'name': 'unmapped'}]}, {})

    def test_public_kit_filters_internal_docs_and_detects_secrets(self):
        spec = importlib.util.spec_from_file_location('publisher', ROOT / 'scripts/publish-source.py')
        publisher = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(publisher)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            for name in publisher.REQUIRED | {'AGENTS.md', 'docs/INTERNAL_RU.md',
                                             'docs/agents/WORKFLOW_RU.md', 'scripts/publish-source.py'}:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('source\n')
            (root / 'scripts/publish-source.py').write_bytes((ROOT / 'scripts/publish-source.py').read_bytes())
            subprocess.run(['git', '-C', str(root), 'add', '.'], check=True)
            subprocess.run(['git', '-C', str(root), 'update-index', '--chmod=+x', 'scripts/publish-source.py'], check=True)
            subprocess.run(['git', '-C', str(root), '-c', 'user.name=Test',
                            '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'fixture'], check=True)
            target = root / 'public.zip'
            source.project_archive(root, 'HEAD', target, public=True)
            with zipfile.ZipFile(target) as archive:
                names = set(archive.namelist())
                self.assertTrue(publisher.REQUIRED <= names)
                self.assertFalse({'AGENTS.md', 'docs/INTERNAL_RU.md', 'docs/agents/WORKFLOW_RU.md'} & names)
                self.assertEqual(archive.getinfo('scripts/publish-source.py').external_attr >> 16, 0o100755)
            (root / 'lib/main.dart').write_text('-----BEGIN PRIVATE KEY-----\n')
            subprocess.run(['git', '-C', str(root), 'add', 'lib/main.dart'], check=True)
            subprocess.run(['git', '-C', str(root), '-c', 'user.name=Test',
                            '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'secret fixture'], check=True)
            with self.assertRaises(ValueError):
                source.project_archive(root, 'HEAD', root / 'unsafe.zip', public=True)

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
