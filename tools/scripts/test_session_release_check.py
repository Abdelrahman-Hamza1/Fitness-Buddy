"""Fail-closed tests for the A20 built-artifact gate using synthetic APKs."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from apk_hardening_check import DumpError

spec = importlib.util.spec_from_file_location(
    'session_release_check', Path(__file__).with_name('session-release-check.py'))
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)

EXCLUSION = '''        E: exclude
          A: domain="sharedpref" (Raw: "sharedpref")
          A: path="." (Raw: ".")
'''


class SyntheticDumps:
    omit = None

    def __init__(self, *args):
        pass

    def resources(self):
        # Resource shrinking renames XML files; the manifest refs must be followed.
        return '''resource 0x7f010001 xml/backup_rules
  () (file) res/a.xml
resource 0x7f010002 xml/data_extraction_rules
  () (file) res/b.xml
'''

    def xmltree(self, path):
        if path == 'AndroidManifest.xml':
            return '''E: manifest
  E: application
    A: http://schemas.android.com/apk/res/android:fullBackupContent(0x010104eb)=@0x7f010001
    A: http://schemas.android.com/apk/res/android:dataExtractionRules(0x0101063e)=@0x7f010002
'''
        if path == 'res/a.xml':
            return 'E: full-backup-content\n' + ('' if self.omit == 'legacy' else EXCLUSION)
        if path == 'res/b.xml':
            text = 'E: data-extraction-rules\n'
            for mode in ('cloud-backup', 'device-transfer', 'cross-platform-transfer'):
                text += '    E: ' + mode + '\n'
                if self.omit != mode:
                    text += EXCLUSION
            return text
        raise AssertionError('gate did not resolve the packaged resource')


class ReleaseGateTest(unittest.TestCase):
    def check(self, marker=b'ordinary release bytes'):
        with tempfile.TemporaryDirectory() as tmp:
            apk = Path(tmp) / 'release.apk'
            with zipfile.ZipFile(apk, 'w') as archive:
                archive.writestr('classes.dex', marker)
                archive.writestr('lib/arm64-v8a/libapp.so', b'AOT')
            with patch.object(checker, 'ApkDumps', SyntheticDumps):
                checker.check('unused-aapt', apk)

    def tearDown(self):
        SyntheticDumps.omit = None

    def test_packaged_resource_references_and_all_exclusions_pass(self):
        self.check()

    def test_missing_exclusion_in_any_transfer_mode_fails(self):
        for mode in ('legacy', 'cloud-backup', 'device-transfer', 'cross-platform-transfer'):
            with self.subTest(mode=mode):
                SyntheticDumps.omit = mode
                with self.assertRaises(DumpError):
                    self.check()

    def test_packaged_debug_channel_and_probe_fail(self):
        for marker in (b'fitness_buddy/session_test', b'a20-status', b'debug_probe_only'):
            with self.subTest(marker=marker), self.assertRaises(DumpError):
                self.check(marker)
