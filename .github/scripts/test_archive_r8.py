import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('archive_r8', Path(__file__).resolve().parents[2] / 'scripts/archive-r8.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ArchiveR8Tests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.mapping = self.root / 'mapping'
        self.mapping.mkdir()
        (self.mapping / 'mapping.txt').write_text('Original -> a:\n', encoding='utf-8')
        self.output = self.root / 'symbols/r8'
        self.apk = self.root / 'CuteLauncher-1.2.3-arm64-v8a-release.apk'
        self.apk.write_bytes(b'ARM APK')

    def archive(self, pass_name='arm', commit='a' * 40):
        return module.archive(self.mapping, self.output, pass_name, '1.2.3', '80', commit, [self.apk], 'test-run-1')

    def test_each_pass_survives_replaced_gradle_outputs_and_has_apk_hash(self):
        self.archive()
        (self.mapping / 'mapping.txt').write_text('Different -> b:\n', encoding='utf-8')
        self.apk = self.root / 'CuteLauncher-1.2.3-x86_64-release.apk'
        self.apk.write_bytes(b'X64 APK')
        self.archive('x64')
        self.assertEqual((self.output / 'arm/mapping.txt').read_text(), 'Original -> a:\n')
        self.assertEqual((self.output / 'x64/mapping.txt').read_text(), 'Different -> b:\n')
        arm = json.loads((self.output / 'arm/build.json').read_text())
        self.assertEqual(arm['version'], '1.2.3+80')
        self.assertEqual(arm['commit'], 'a' * 40)
        self.assertEqual(arm['apks']['CuteLauncher-1.2.3-arm64-v8a-release.apk']['sha256'],
                         '1ba17086a88d52507c012439f826c5ff0e3ee01abed0ddcae3586062f5a1ba35')

    def test_previous_pass_cannot_be_overwritten(self):
        self.archive()
        with self.assertRaises(ValueError):
            self.archive()
        self.assertEqual((self.output / 'arm/mapping.txt').read_text(), 'Original -> a:\n')

    def test_other_source_build_cannot_be_mixed(self):
        self.archive()
        self.apk = self.root / 'CuteLauncher-1.2.3-x86_64-release.apk'
        self.apk.write_bytes(b'X64 APK')
        with self.assertRaisesRegex(ValueError, 'identity'):
            self.archive('x64', 'b' * 40)
        self.assertFalse((self.output / 'x64').exists())

    def test_missing_or_empty_mapping_fails_without_completed_pass(self):
        (self.mapping / 'mapping.txt').write_bytes(b'')
        with self.assertRaises(ValueError):
            self.archive()
        self.assertFalse((self.output / 'arm').exists())

    def test_same_commit_from_other_run_cannot_be_mixed(self):
        self.archive()
        self.apk = self.root / 'CuteLauncher-1.2.3-x86_64-release.apk'
        self.apk.write_bytes(b'X64 APK')
        with self.assertRaisesRegex(ValueError, 'identity'):
            module.archive(self.mapping, self.output, 'x64', '1.2.3', '80', 'a' * 40, [self.apk], 'test-run-2')
        self.assertFalse((self.output / 'x64').exists())

    def test_wrong_pass_apk_and_extra_file_are_rejected(self):
        self.apk = self.root / 'CuteLauncher-1.2.3-x86_64-release.apk'
        self.apk.write_bytes(b'X64 APK')
        with self.assertRaises(ValueError):
            self.archive('arm')
        self.assertFalse((self.output / 'arm').exists())


if __name__ == '__main__':
    unittest.main()
