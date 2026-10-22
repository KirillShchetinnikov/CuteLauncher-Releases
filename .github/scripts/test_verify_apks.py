import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile


spec = importlib.util.spec_from_file_location('verify_apks', Path(__file__).with_name('verify_apks.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ApkVerificationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.apks = self.root / 'apks'
        self.apks.mkdir()
        (self.root / 'sdk/build-tools/36.0.0').mkdir(parents=True)
        for abi in ('universal', *sorted(module.ABIS)):
            self.write_apk(abi, module.ABIS if abi == 'universal' else {abi})

    def write_apk(self, abi, abis):
        with ZipFile(self.apks / f'CuteLauncher-1.2.3-{abi}-release.apk', 'w') as archive:
            for item in abis:
                archive.writestr(f'lib/{item}/libapp.so', b'test')

    def output(self, *args):
        if args[1] == 'manifest':
            return {'application-id': module.APPLICATION_ID,
                    'version-name': '1.2.3', 'version-code': '80'}[args[2]]
        return 'Signer #1 certificate SHA-256 digest: ' + module.CERTIFICATE

    def test_exact_four_apks_and_expected_abis(self):
        self.assertEqual(len(list(module.check_files(self.apks, '1.2.3'))), 4)
        self.write_apk('arm64-v8a', {'x86_64'})
        with self.assertRaisesRegex(ValueError, 'ABI composition'):
            module.check_files(self.apks, '1.2.3')

    def test_extra_or_missing_apk_is_rejected(self):
        extra = self.apks / 'extra.apk'
        extra.write_bytes(b'')
        with self.assertRaisesRegex(ValueError, 'APK names'):
            module.check_files(self.apks, '1.2.3')
        extra.unlink()
        next(self.apks.glob('*.apk')).unlink()
        with self.assertRaisesRegex(ValueError, 'APK names'):
            module.check_files(self.apks, '1.2.3')

    def test_wrong_metadata_and_certificate_are_rejected(self):
        for field in ('application-id', 'version-name', 'version-code', 'certificate'):
            def output(*args):
                if (args[1] == 'manifest' and args[2] == field) or (
                        args[1] == 'verify' and field == 'certificate'):
                    return 'wrong value'
                return self.output(*args)
            with self.subTest(field=field), patch.object(module, 'run', side_effect=output):
                with self.assertRaises(ValueError):
                    module.verify(self.apks, '1.2.3', '80', self.root / 'sdk', signed=True)

    def test_signed_apks_are_verified_and_unsigned_stage_rejects_signatures(self):
        with patch.object(module, 'run', side_effect=self.output):
            module.verify(self.apks, '1.2.3', '80', self.root / 'sdk', signed=True)
            with patch.object(module.subprocess, 'run') as process:
                process.return_value.returncode = 0
                with self.assertRaisesRegex(ValueError, 'must not contain signed'):
                    module.verify(self.apks, '1.2.3', '80', self.root / 'sdk')


if __name__ == '__main__':
    unittest.main()
