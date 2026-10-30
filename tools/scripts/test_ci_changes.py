"""TD-104/TD-108: the `changes` job's docs-only decision in ci.yml.

Runs the job's own script (extracted from ci.yml) in a throwaway git repo.
Pins: only merge/** pushes may be docs-only; spec/ counts as code; a rename is
judged on both sides (code moved into docs/ is not docs-only); NUL-separated
paths; an empty diff is never docs-only.
"""
from pathlib import Path
import os
import subprocess
import tempfile
import textwrap
import unittest

ROOT = Path(__file__).resolve().parents[2]


def changes_script():
    text = (ROOT / '.github/workflows/ci.yml').read_text()
    step = text.split('- name: Docs-only merge?', 1)[1]
    body = step.split('run: |\n', 1)[1].split('\n\n', 1)[0]
    return textwrap.dedent(body)


class DocsOnlyTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name) / 'repo'
        self.repo.mkdir()
        self.env = {**os.environ, 'GIT_AUTHOR_NAME': 't', 'GIT_AUTHOR_EMAIL': 't@example.com',
                    'GIT_COMMITTER_NAME': 't', 'GIT_COMMITTER_EMAIL': 't@example.com',
                    'GIT_CONFIG_GLOBAL': os.devnull, 'GIT_CONFIG_NOSYSTEM': '1'}
        self.git('init', '-q', '-b', 'main')
        for path, content in (('apps/mobile/lib/main.dart', 'void main() {}\n'),
                              ('docs/guide.md', 'guide\n'), ('spec/10.md', 'spec\n'),
                              ('README.md', 'readme\n')):
            self.write(path, content)
        self.commit('base')
        self.git('update-ref', 'refs/remotes/origin/main', 'HEAD')

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.run(['git', *args], cwd=self.repo, env=self.env, check=True,
                              capture_output=True, text=True).stdout

    def write(self, path, content):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def commit(self, message):
        self.git('add', '-A')
        self.git('commit', '-q', '-m', message)

    def decide(self, event='push', ref='refs/heads/merge/A01'):
        out = Path(self.tmp.name) / 'output'
        out.write_text('')
        subprocess.run(['bash', '-eo', 'pipefail', '-c', changes_script()], cwd=self.repo, check=True,
                       env={**self.env, 'EVENT': event, 'REF': ref, 'RUNNER_TEMP': self.tmp.name,
                            'GITHUB_OUTPUT': str(out), 'GITHUB_STEP_SUMMARY': os.devnull})
        return dict(line.split('=', 1) for line in out.read_text().split())

    def test_docs_only_merge_skips(self):
        self.write('docs/guide.md', 'more\n')
        self.write('technical-planning/x.md', 'plan\n')
        self.write('.claude/skills/x/SKILL.md', 'skill\n')
        self.commit('docs')
        self.assertEqual(self.decide(), {'android': 'false', 'docs_only': 'true'})

    def test_only_merge_pushes_can_be_docs_only(self):
        self.write('docs/guide.md', 'more\n')
        self.commit('docs')
        for event, ref in (('push', 'refs/heads/step/A01-x'), ('workflow_dispatch', 'refs/heads/merge/A01'),
                           ('pull_request', 'refs/pull/1/merge'), ('schedule', 'refs/heads/main')):
            with self.subTest(event=event, ref=ref):
                self.assertEqual(self.decide(event, ref), {'android': 'true', 'docs_only': 'false'})

    def test_code_moved_into_docs_is_not_docs_only(self):
        self.git('mv', 'apps/mobile/lib/main.dart', 'docs/main.dart')
        self.commit('move code into docs')
        # Rename detection would list only docs/main.dart.
        self.assertEqual(self.git('diff', '--name-only', 'origin/main', 'HEAD').split(), ['docs/main.dart'])
        self.assertEqual(self.decide()['docs_only'], 'false')

    def test_docs_renamed_within_docs_is_docs_only(self):
        (self.repo / 'technical-planning').mkdir()
        self.git('mv', 'docs/guide.md', 'technical-planning/guide.md')
        self.commit('move docs')
        self.assertEqual(self.decide()['docs_only'], 'true')

    def test_spec_and_code_are_not_docs(self):
        for path in ('spec/10.md', '.claude/settings.json', 'apps/mobile/lib/main.dart'):
            with self.subTest(path=path):
                self.git('reset', '-q', '--hard', 'origin/main')
                self.write(path, 'changed\n')
                self.commit('change ' + path)
                self.assertEqual(self.decide()['docs_only'], 'false')

    def test_newline_in_a_docs_path(self):
        self.write('docs/a\nb.md', 'odd\n')
        self.commit('odd name')
        self.assertEqual(self.decide()['docs_only'], 'true')

    def test_empty_diff_is_not_docs_only(self):
        self.assertEqual(self.decide()['docs_only'], 'false')


if __name__ == '__main__':
    unittest.main()
