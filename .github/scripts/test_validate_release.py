import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    'release_validation', Path(__file__).with_name('validate_release.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReleaseValidationTest(unittest.TestCase):
    def test_cli_exports_release_titles_for_workflow(self):
        script = Path(__file__).with_name('validate_release.py').resolve()
        for version in ['1.0.0+18', '1.0.0-test.3+18']:
            with tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                (root / 'pubspec.yaml').write_text('version: ' + version)
                output = root / 'github-env'
                subprocess.run([sys.executable, str(script), 'v' + version.split('+')[0]],
                               cwd=root, env={**os.environ, 'GITHUB_ENV': str(output)},
                               check=True, capture_output=True)
                name, build = version.rsplit('+', 1)
                self.assertIn(f'RELEASE_TITLE=CuteLauncher {name}\n',
                              output.read_text())

    def test_stable_and_prerelease_match_exact_pubspec(self):
        for version in ['1.0.0+16', '1.0.0-test.1+16']:
            self.assertEqual(module.validate('v' + version, 'version: ' + version),
                             tuple(version.rsplit('+', 1)))
            self.assertEqual(module.validate('v' + version.split('+')[0], 'version: ' + version),
                             tuple(version.rsplit('+', 1)))

    def test_missing_build_mismatch_and_injection_are_rejected(self):
        for tag in ['v1.0.1', 'v-dev', 'v1.0.0+0', 'v1.0.0+17', 'v1.0.0+16\nother']:
            with self.assertRaises(ValueError):
                module.validate(tag, 'version: 1.0.0+16')

    def test_cli_rejects_build_reuse_after_a_tag_without_build(self):
        script = Path(__file__).with_name('validate_release.py').resolve()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            def git(*args):
                subprocess.run(['git', *args], cwd=root, check=True, capture_output=True)
            git('init')
            (root / 'pubspec.yaml').write_text('version: 1.1.0+75')
            git('add', 'pubspec.yaml')
            git('-c', 'user.name=Test', '-c', 'user.email=test@example.com', 'commit', '-m', 'Previous')
            git('tag', 'v1.1.0')
            tags = root / 'published.txt'
            tags.write_text('v1.1.0\n')
            (root / 'pubspec.yaml').write_text('version: 1.1.1+75')
            result = subprocess.run([sys.executable, str(script), 'v1.1.1', str(tags)],
                                    cwd=root, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b'Build must exceed', result.stderr)
            (root / 'pubspec.yaml').write_text('version: 1.1.1+76')
            subprocess.run([sys.executable, str(script), 'v1.1.1', str(tags)],
                           cwd=root, check=True, capture_output=True)

    def test_build_exceeds_stable_and_prerelease(self):
        self.assertEqual(module.validate('v1.0.0+16', 'version: 1.0.0+16',
                                        ['v3.2.2', 'v1.0.0-test.1+15']), ('1.0.0', '16'))
        for tag in ['v1.0.0-test.1+16', 'v2.0.0+20']:
            with self.assertRaises(ValueError):
                module.validate('v1.0.0+16', 'version: 1.0.0+16', [tag])


if __name__ == '__main__':
    unittest.main()
