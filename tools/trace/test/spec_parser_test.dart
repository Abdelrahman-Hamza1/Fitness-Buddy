import 'package:fb_trace/fb_trace.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const _parser = SpecParser();

/// Parses [markdown] as `spec/zz.md` and returns its requirements by ID.
Map<String, Requirement> _parse(String markdown) => {
  for (final r in _parser.parse('spec/zz.md', markdown).requirements) r.id: r,
};

void main() {
  group('bullets:', () {
    test('AT-001 parses bullet IDs with release tags', () {
      final requirements = _parse('''
# Title

- **ZZ-001** `[R1]` First, with **bold** text.
- **ZZ-002** `[R2]` Second.
  * **ZZ-003** `[R3]` Nested star bullet.
- **ZZ-004** `[Later]` Some day.
''');

      expect(requirements.keys, ['ZZ-001', 'ZZ-002', 'ZZ-003', 'ZZ-004']);
      expect(
        [for (final r in requirements.values) r.release],
        [Release.r1, Release.r2, Release.r3, Release.later],
      );
      final first = requirements['ZZ-001']!;
      expect(first.location, 'spec/zz.md:3');
      expect(first.title, 'First, with bold text.');
    });

    test('AT-001 bullet without a tag is untagged (C-1 style)', () {
      final requirements = _parse('''
- **C-1** Flutter, iOS + Android phones (D-004).
- **ZZ-01** Solo developer.
''');

      expect(requirements['C-1']!.release, Release.untagged);
      expect(
        requirements['C-1']!.title,
        'Flutter, iOS + Android phones (D-004).',
      );
      expect(requirements['ZZ-01']!.release, Release.untagged);
    });
  });

  group('tables:', () {
    test(
      'AT-001 table rows take release from a Release column (NT-001 style)',
      () {
        final file = _parser.parse('spec/zz.md', '''
| ID | Reminder | Default | Release |
|---|---|---|---|
| NT-001 | **Log reminder**: fires at 21:00 | On | R1 |
| **ZZ-002** | Bold ID cell | Off | **R2** |
| ZZ-003 | Empty release cell | Off | |
''');
        final requirements = {for (final r in file.requirements) r.id: r};

        expect(requirements['NT-001']!.release, Release.r1);
        expect(requirements['NT-001']!.title, 'Log reminder: fires at 21:00');
        expect(requirements['NT-001']!.location, 'spec/zz.md:3');
        expect(requirements['ZZ-002']!.release, Release.r2);
        expect(requirements['ZZ-003']!.release, Release.untagged);
        expect(
          file.warnings.single,
          'spec/zz.md:5: ZZ-003 has an unknown value "" in the Release '
          'column, counted as untagged',
        );
      },
    );

    test(
      'AT-001 table rows without a Release column are untagged (UX-001 style)',
      () {
        final requirements = _parse('''
| ID | Action | Target |
|---|---|---|
| UX-001 | Open app → input bar ready to type | ≤ 2 s |
| UX-002 | Send a food message | R1 |
''');

        expect(requirements['UX-001']!.release, Release.untagged);
        expect(requirements['UX-002']!.release, Release.untagged);
      },
    );

    test('AT-001 table header resets between tables', () {
      final requirements = _parse('''
| ID | Thing | Release |
|---|---|---|
| ZZ-001 | Tagged | R2 |

| ID | Thing | Note |
|---|---|---|
| ZZ-002 | Untagged | R2 |
Some prose right after a table.
| ID | Release | Thing |
|---|---|---|
| ZZ-003 | R3 | Release in the second column |
''');

      expect(requirements['ZZ-001']!.release, Release.r2);
      expect(requirements['ZZ-002']!.release, Release.untagged);
      expect(requirements['ZZ-003']!.release, Release.r3);
    });
  });

  test('AT-001 ignores IDs in prose, non-first cells and T01 cases', () {
    final requirements = _parse('''
Prose mentions ZZ-001 and **ZZ-002** but defines nothing.
1. **ZZ-003** in a numbered list is not a bullet definition.
- Bullet whose bold text comes later: **ZZ-004**.
- **Not an ID** `[R1]`.

| # | Message | Expected |
|---|---|---|
| T01 | `fried egg` | Like ZZ-005. |
| Row | ZZ-006 | ZZ-007 |

| ZZ-008 | header rows are never requirements |
|---|---|
''');

    expect(requirements, isEmpty);
  });

  test('AT-001 duplicate ID is an error with both locations', () {
    final spec = combineSpecFiles([
      _parser.parse('spec/a.md', '- **ZZ-001** `[R1]` First.\n'),
      _parser.parse(
        'spec/b.md',
        'Intro.\n\n| ID | X |\n|---|---|\n'
            '| ZZ-001 | Again |\n',
      ),
    ], overrides: const {});

    expect(spec.errors, [
      'Duplicate ID ZZ-001: defined at spec/a.md:1 and spec/b.md:5',
    ]);
    expect(spec.requirements.single.location, 'spec/a.md:1');
  });

  group('overrides:', () {
    test(
      'AT-001 override maps UX-001 to R1; override on a tagged ID warns',
      () {
        final spec = combineSpecFiles(
          [
            _parser.parse(
              'spec/30.md',
              '| ID | Action | Target |\n|---|---|---|\n'
                  '| UX-001 | Open app | ≤ 2 s |\n',
            ),
            _parser.parse('spec/12.md', '- **ZZ-001** `[R2]` Tagged.\n'),
          ],
          overrides: {
            'UX-001': releaseOverrides['UX-001']!,
            'ZZ-001': const ReleaseOverride(Release.r1, 'test: tagged'),
            'ZZ-404': const ReleaseOverride(Release.r1, 'test: unknown'),
          },
        );
        final releases = {for (final r in spec.requirements) r.id: r.release};

        expect(releases, {'UX-001': Release.r1, 'ZZ-001': Release.r2});
        expect(spec.warnings, [
          'Override ZZ-001 -> R1 ignored: spec/12.md:1 already tags it R2',
          'Override ZZ-404 -> R1 ignored: no such ID in the spec',
        ]);
      },
    );
  });

  test('AT-001 reads only top-level spec files, skipping README, decisions '
      'and glossary', () {
    final root = tempRepo({
      'spec/10-a.md': '- **ZZ-001** `[R1]` Kept.\n',
      'spec/20-b.md': '- **ZZ-002** `[R2]` Kept too.\n',
      'spec/README.md': '- **ZZ-003** `[R1]` Index.\n',
      'spec/decisions.md': '- **ZZ-004** `[R1]` Decision.\n',
      'spec/glossary.md': '- **ZZ-005** `[R1]` Term.\n',
      'spec/notes.txt': '- **ZZ-006** `[R1]` Not Markdown.\n',
      'spec/research/r.md': '- **ZZ-007** `[R1]` Research.\n',
      'spec/questions/q.md': '- **ZZ-008** `[R1]` Question.\n',
    });

    final spec = readSpec(root, overrides: const {});

    expect(
      [for (final r in spec.requirements) r.location],
      ['spec/10-a.md:1', 'spec/20-b.md:1'],
    );
    expect(spec.errors, isEmpty);
    expect(spec.warnings, isEmpty);
  });
}
