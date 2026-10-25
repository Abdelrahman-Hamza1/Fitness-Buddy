"""A11 T18: pin one flavor/build, upload policy, secrets and TD-060 gate."""
from pathlib import Path
import os
import subprocess
import tempfile
import textwrap
import unittest


class AndroidCiTest(unittest.TestCase):
    def test_AT_006_signing_annotations_use_flavor_and_upload_eligibility(self):
        text = (Path(__file__).resolve().parents[2] / '.github/workflows/ci.yml').read_text()
        summary = text.split('- name: Job summary (signing, outputs, time)', 1)[1].split('\n  android-it:', 1)[0]
        script = textwrap.dedent(summary.split('run: |\n', 1)[1]).split('# Also as an annotation:', 1)[1].split('\n', 1)[1]
        for flavor, ref, signed, upload in (
            ('prod', 'refs/heads/main', 'true', 'true'),
            ('prod', 'refs/heads/merge/A11', 'true', 'false'),
            ('staging', 'refs/heads/step/A11', 'true', 'true'),
            ('prod', 'refs/heads/main', 'false', 'false')):
            with self.subTest(flavor=flavor, ref=ref, signed=signed), tempfile.TemporaryDirectory() as tmp:
                outputs = Path(tmp)
                (outputs / 'flutter-apk').mkdir()
                (outputs / 'flutter-apk' / f'app-{flavor}-release.apk').write_bytes(b'apk')
                result = subprocess.run(['bash', '-euo', 'pipefail', '-c', script], check=True,
                    capture_output=True, text=True, env={**os.environ, 'outputs': tmp,
                    'FLAVOR': flavor, 'GITHUB_REF': ref, 'SIGNED': signed})
                self.assertIn(f'signed={signed}', result.stdout)
                self.assertIn(f'upload-eligible={upload}', result.stdout)
                self.assertIn(f'app-{flavor}-release.apk', result.stdout)

    def test_release_policy(self):
        workflow = Path(__file__).resolve().parents[2] / '.github/workflows/ci.yml'
        text = workflow.read_text()
        android = text.split('\n  android:\n', 1)[1].split('\n  android-it:', 1)[0]
        self.assertIn('timeout-minutes: 30', android)
        self.assertEqual(android.count('make build-android '), 1)
        self.assertIn('flavor=staging', android)
        self.assertIn('"$GITHUB_REF" == refs/heads/main || "$GITHUB_REF" == refs/heads/merge/*', android)
        self.assertIn('flavor=prod', android)
        for key in ('FB_API_BASE_URL', 'FB_SENTRY_DSN'):
            self.assertIn(key + ': ${{ secrets.' + key + ' }}', android)
            self.assertNotIn('vars.' + key, text)
        self.assertIn('app-*-release*.apk', android)
        prod = android.split('- name: Upload the signed prod APK', 1)[1].split('- name: Job summary', 1)[0]
        self.assertIn("if: steps.key.outputs.signed == 'true' && github.ref == 'refs/heads/main'", prod)
        for field in ('app-prod-release.apk', 'archive: false', 'retention-days: 30', 'if-no-files-found: error'):
            self.assertIn(field, prod)
        for test in ('build-android-selftest.sh', 'verify-key-backup-selftest.sh', 'test_android_ci.py', 'test_sentry_envelope_sink.py'):
            self.assertIn(test, text)
        selector = android.split('- name: Select the release flavor (A11 D14)', 1)[1].split('- name:', 1)[0]
        script = textwrap.dedent(selector.split('run: |\n', 1)[1])
        for ref, expected in (
                ('refs/heads/main', 'prod'), ('refs/heads/merge/A11', 'prod'),
                ('refs/heads/step/A11-dogfood-readiness', 'staging'),
                ('refs/pull/1/merge', 'staging'), ('refs/tags/main', 'staging')):
            with self.subTest(ref=ref), tempfile.TemporaryDirectory() as tmp:
                output = Path(tmp) / 'output'
                subprocess.run(['bash', '-euo', 'pipefail', '-c', script], check=True,
                               env={**os.environ, 'GITHUB_REF': ref, 'GITHUB_OUTPUT': str(output)})
                self.assertEqual(output.read_text(), f'name={expected}\n')
        self.assertIn('FLAVOR: ${{ steps.flavor.outputs.name }}', android)
        self.assertIn('FLAVOR="$FLAVOR"', android)
        # TD-060 gate is separately compared byte-for-byte during diff review.
        self.assertRegex(text, r'(?s)\n  ci:.*needs:')


if __name__ == '__main__':
    unittest.main()
