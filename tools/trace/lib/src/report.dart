import 'package:fb_trace/src/requirement.dart';
import 'package:fb_trace/src/spec_parser.dart';

/// Longest title shown in a report table, in characters.
const int maxTitleLength = 80;

/// Coverage numbers for one release.
class ReleaseSummary {
  /// Creates a summary.
  const new(this.label, this.total, this.covered);

  /// The release label (`R1`, …, `Untagged`, `All`).
  final String label;

  /// Requirements in the release.
  final int total;

  /// Requirements with at least one covering test.
  final int covered;

  /// Requirements without a covering test.
  int get missing => total - covered;

  /// One line for logs: `R1: 319 total, 0 covered, 319 missing`.
  @override
  String toString() =>
      '$label: $total total, $covered covered, $missing missing';
}

/// The traceability report: spec requirements vs covering tests.
class TraceReport {
  /// Creates a report of [releases] (and the untagged requirements if
  /// [includeUntagged]) from [spec] and [coverage] (ID → covering files).
  new({
    required this.spec,
    required this.coverage,
    required this.releases,
    this.includeUntagged = false,
  });

  /// The parsed spec.
  final Spec spec;

  /// Covering test files per requirement ID, as found by the test scanner.
  final Map<String, Set<String>> coverage;

  /// The releases the report details.
  final List<Release> releases;

  /// Whether the report also lists the untagged requirements.
  final bool includeUntagged;

  /// The requirements of [release], in spec order.
  List<Requirement> requirementsOf(Release release) => [
    for (final r in spec.requirements)
      if (r.release == release) r,
  ];

  /// Coverage numbers per selected release, then for the untagged
  /// requirements and all of them together if [includeUntagged].
  List<ReleaseSummary> get summaries => [
    for (final release in releases) _summary(release.label, [release]),
    if (includeUntagged) ...[
      _summary(Release.untagged.label, [Release.untagged]),
      _summary('All', Release.values),
    ],
  ];

  /// Spec warnings, then one warning per test-referenced ID that is not in
  /// the spec (sorted by ID).
  List<String> get warnings {
    final known = {for (final r in spec.requirements) r.id};
    final unknown = coverage.keys.where((id) => !known.contains(id)).toList()
      ..sort();
    return [
      ...spec.warnings,
      for (final id in unknown)
        'Unknown ID $id referenced by tests: ${_sorted(coverage[id]!)}',
    ];
  }

  /// The report as deterministic Markdown (no timestamps, stable order).
  String toMarkdown() {
    final out = StringBuffer()
      ..writeln('# Requirement traceability')
      ..writeln()
      ..writeln(
        'Requirement IDs from `spec/*.md` vs the IDs that tests claim to '
        'cover (leading IDs in test names, `// covers:` lines, '
        '`[Trait("Req", …)]`).',
      )
      ..writeln()
      ..writeln('## Summary')
      ..writeln()
      ..writeln('| Release | Total | Covered | Missing |')
      ..writeln('|---|---:|---:|---:|');
    for (final s in summaries) {
      out.writeln('| ${s.label} | ${s.total} | ${s.covered} | ${s.missing} |');
    }

    for (final release in releases) {
      final requirements = requirementsOf(release);
      final missing = [
        for (final r in requirements)
          if (!_isCovered(r)) r,
      ];
      final covered = [
        for (final r in requirements)
          if (_isCovered(r)) r,
      ];
      _section(out, '${release.label} missing (${missing.length})');
      _table(out, missing, withTests: false);
      _section(out, '${release.label} covered (${covered.length})');
      _table(out, covered, withTests: true);
    }

    if (includeUntagged) {
      final untagged = requirementsOf(Release.untagged);
      _section(out, 'Untagged (${untagged.length})');
      _table(out, untagged, withTests: true);
    }

    final warnings = this.warnings;
    _section(out, 'Warnings (${warnings.length})');
    if (warnings.isEmpty) out.writeln('None.');
    for (final warning in warnings) {
      out.writeln('- $warning');
    }
    return out.toString();
  }

  ReleaseSummary _summary(String label, List<Release> included) {
    final requirements = [
      for (final r in spec.requirements)
        if (included.contains(r.release)) r,
    ];
    return ReleaseSummary(
      label,
      requirements.length,
      requirements.where(_isCovered).length,
    );
  }

  bool _isCovered(Requirement r) => coverage[r.id]?.isNotEmpty ?? false;

  void _section(StringBuffer out, String title) => out
    ..writeln()
    ..writeln('## $title')
    ..writeln();

  void _table(
    StringBuffer out,
    List<Requirement> requirements, {
    required bool withTests,
  }) {
    if (requirements.isEmpty) {
      out.writeln('None.');
      return;
    }
    out
      ..writeln(
        withTests ? '| ID | Spec | Title | Tests |' : '| ID | Spec | Title |',
      )
      ..writeln(withTests ? '|---|---|---|---|' : '|---|---|---|');
    for (final r in requirements) {
      final cells = [
        r.id,
        r.location,
        _cell(_shorten(r.title)),
        if (withTests) _cell(_sorted(coverage[r.id] ?? const {})),
      ];
      out.writeln('| ${cells.join(' | ')} |');
    }
  }

  static String _sorted(Set<String> files) =>
      (files.toList()..sort()).join(', ');

  static String _shorten(String title) {
    final runes = title.runes;
    if (runes.length <= maxTitleLength) return title;
    return '${String.fromCharCodes(runes.take(maxTitleLength - 1))}…';
  }

  /// Escapes the pipes that aren't escaped yet, so a cell stays one cell.
  static String _cell(String text) =>
      text.replaceAll(RegExp(r'(?<!\\)\|'), r'\|');
}
