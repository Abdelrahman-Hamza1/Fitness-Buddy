import 'package:fb_trace/fb_trace.dart';
import 'package:test/test.dart';

const _parser = SpecParser();

Spec _spec() => combineSpecFiles([
  _parser.parse('spec/10-a.md', '''
- **ZZ-001** `[R1]` Covered R1 requirement.
- **ZZ-002** `[R1]` Missing R1 requirement.
- **ZZ-003** `[R2]` Covered R2 requirement.
- **ZZ-004** An untagged requirement.
'''),
], overrides: const {});

void main() {
  final coverage = {
    'ZZ-001': {'packages/p/test/b_test.dart', 'packages/p/test/a_test.dart'},
    'ZZ-003': {'apps/app/test/c_test.dart'},
    'ZZ-999': {'tools/t/test/typo_test.dart'},
  };

  test('AT-001 report lists covered/missing per release, deterministic', () {
    String render(
      Map<String, Set<String>> coverage, {
      List<Release> releases = const [Release.r1],
      bool includeUntagged = false,
    }) => TraceReport(
      spec: _spec(),
      coverage: coverage,
      releases: releases,
      includeUntagged: includeUntagged,
    ).toMarkdown();
    // The same coverage, every map and set built in the reverse order.
    final reversed = {
      for (final id in coverage.keys.toList().reversed)
        id: {...coverage[id]!.toList().reversed},
    };
    expect(reversed.keys.first, isNot(coverage.keys.first));
    expect(reversed['ZZ-001']!.first, isNot(coverage['ZZ-001']!.first));

    final markdown = render(coverage);

    expect(render(reversed), markdown);
    expect(
      render(reversed, releases: Release.tagged, includeUntagged: true),
      render(coverage, releases: Release.tagged, includeUntagged: true),
    );
    expect(
      markdown,
      contains(
        '| Release | Total | Covered | Missing |\n'
        '|---|---:|---:|---:|\n'
        '| R1 | 2 | 1 | 1 |\n',
      ),
    );
    expect(
      markdown,
      contains(
        '## R1 missing (1)\n\n'
        '| ID | Spec | Title |\n'
        '|---|---|---|\n'
        '| ZZ-002 | spec/10-a.md:2 | Missing R1 requirement. |\n',
      ),
    );
    expect(
      markdown,
      contains(
        '## R1 covered (1)\n\n'
        '| ID | Spec | Title | Tests |\n'
        '|---|---|---|---|\n'
        '| ZZ-001 | spec/10-a.md:1 | Covered R1 requirement. | '
        'packages/p/test/a_test.dart, packages/p/test/b_test.dart |\n',
      ),
    );
    expect(markdown, isNot(contains('ZZ-003 |')));
    expect(markdown, isNot(contains('Untagged')));
  });

  test('AT-001 report with every release adds the untagged section', () {
    final report = TraceReport(
      spec: _spec(),
      coverage: coverage,
      releases: Release.tagged,
      includeUntagged: true,
    );

    expect(
      [for (final s in report.summaries) '$s'],
      [
        'R1: 2 total, 1 covered, 1 missing',
        'R2: 1 total, 1 covered, 0 missing',
        'R3: 0 total, 0 covered, 0 missing',
        'Later: 0 total, 0 covered, 0 missing',
        'Untagged: 1 total, 0 covered, 1 missing',
        'All: 4 total, 2 covered, 2 missing',
      ],
    );
    final markdown = report.toMarkdown();
    expect(markdown, contains('## R3 missing (0)\n\nNone.\n'));
    expect(
      markdown,
      contains(
        '## Untagged (1)\n\n'
        '| ID | Spec | Title | Tests |\n'
        '|---|---|---|---|\n'
        '| ZZ-004 | spec/10-a.md:4 | An untagged requirement. |  |\n',
      ),
    );
  });

  test('AT-001 reports unknown referenced IDs as warnings', () {
    final report = TraceReport(
      spec: _spec(),
      coverage: coverage,
      releases: const [Release.r1],
    );

    expect(report.warnings, [
      'Unknown ID ZZ-999 referenced by tests: tools/t/test/typo_test.dart',
    ]);
    expect(
      report.toMarkdown(),
      endsWith(
        '## Warnings (1)\n\n'
        '- Unknown ID ZZ-999 referenced by tests: '
        'tools/t/test/typo_test.dart\n',
      ),
    );
  });

  test('AT-001 report shortens titles to 80 characters and escapes pipes', () {
    final long = 'x' * 100;
    final spec = combineSpecFiles([
      _parser.parse(
        'spec/a.md',
        '- **ZZ-001** `[R1]` $long\n- **ZZ-002** `[R1]` a | b\n',
      ),
    ], overrides: const {});

    final markdown = TraceReport(
      spec: spec,
      coverage: const {},
      releases: const [Release.r1],
    ).toMarkdown();

    expect(markdown, contains('| ${'x' * 79}… |'));
    expect(markdown, contains(r'| a \| b |'));
  });
}
