import 'dart:convert';
import 'dart:io';

import 'package:fb_trace/src/release_overrides.dart';
import 'package:fb_trace/src/requirement.dart';
import 'package:path/path.dart' as p;

/// Top-level spec files that define no requirements.
const Set<String> skippedSpecFiles = {
  'README.md',
  'decisions.md',
  'glossary.md',
};

/// The requirements and warnings found in one spec file.
class SpecFile {
  /// Creates the parse result of one file.
  const new(this.requirements, this.warnings);

  /// Requirements in file order.
  final List<Requirement> requirements;

  /// Problems that don't stop the report (e.g. an unknown release tag).
  final List<String> warnings;
}

/// All requirements of the spec, with the problems found while reading it.
class Spec {
  /// Creates a spec.
  const new({
    required this.requirements,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Requirements in spec order (file name, then line).
  final List<Requirement> requirements;

  /// Problems that make the spec invalid (duplicate IDs).
  final List<String> errors;

  /// Problems that don't stop the report.
  final List<String> warnings;
}

/// Finds requirement definitions in one spec Markdown file.
///
/// Two forms define a requirement:
/// - a bullet whose bold text is the ID, optionally followed *immediately* by
///   a release tag: ``- **AI-012** `[R1]` Text``. A tag later in the line is
///   prose and doesn't count;
/// - a table row whose first cell is the ID (`| NT-001 | … | R1 |`). Its
///   release comes from the table's "Release" column, if it has one.
///
/// IDs anywhere else (prose, other table cells) are references, not
/// definitions. Test cases like `T01` are not IDs.
class SpecParser {
  /// Creates a parser.
  const new();

  static final _bullet = RegExp(
    '^\\s*[-*]\\s+\\*\\*($idPattern)\\*\\*\\s*'
    r'(?:`\[([^\]`]*)\]`)?'
    r'(.*)$',
  );
  static final _cellSeparator = RegExp(r'(?<!\\)\|');
  static final _separatorCell = RegExp(r'^:?-+:?$');

  /// Parses [text], the content of the spec file named [fileName].
  ///
  /// [fileName] is used as-is in locations, so pass the repo-relative path
  /// (e.g. `spec/17-notifications.md`).
  SpecFile parse(String fileName, String text) {
    final requirements = <Requirement>[];
    final warnings = <String>[];

    // Header cells of the current table block, null outside a table.
    List<String>? header;
    int? releaseColumn;

    for (final (index, line) in LineSplitter.split(text).indexed) {
      final lineNumber = index + 1;
      final location = '$fileName:$lineNumber';

      if (!line.trimLeft().startsWith('|')) {
        header = null;
        releaseColumn = null;
        final bullet = _bullet.firstMatch(line);
        if (bullet == null) continue;
        final id = bullet[1]!;
        final tag = bullet[2];
        var release = Release.untagged;
        if (tag != null) {
          final known = Release.fromTag(tag);
          if (known == null) {
            warnings.add(
              '$location: $id has an unknown release tag "[$tag]", '
              'counted as untagged',
            );
          } else {
            release = known;
          }
        }
        requirements.add(
          Requirement(
            id: id,
            release: release,
            file: fileName,
            line: lineNumber,
            title: _plain(bullet[3]!),
          ),
        );
        continue;
      }

      final cells = _cells(line);
      if (header == null) {
        header = cells;
        final column = cells.indexWhere(
          (cell) => _plain(cell).toLowerCase() == 'release',
        );
        releaseColumn = column < 0 ? null : column;
        continue;
      }
      if (cells.every(_separatorCell.hasMatch)) continue;

      final id = _plain(cells.first);
      if (!exactId.hasMatch(id)) continue;

      var release = Release.untagged;
      if (releaseColumn != null) {
        final value = releaseColumn < cells.length
            ? _plain(cells[releaseColumn]).replaceAll(RegExp(r'[`\[\]]'), '')
            : '';
        final known = Release.fromTag(value);
        if (known == null) {
          warnings.add(
            '$location: $id has an unknown value "$value" in the Release '
            'column, counted as untagged',
          );
        } else {
          release = known;
        }
      }
      requirements.add(
        Requirement(
          id: id,
          release: release,
          file: fileName,
          line: lineNumber,
          title: cells.length > 1 ? _plain(cells[1]) : '',
        ),
      );
    }
    return SpecFile(requirements, warnings);
  }

  /// The cells of a table row, trimmed, without the outer pipes.
  static List<String> _cells(String line) {
    var row = line.trim();
    if (row.startsWith('|')) row = row.substring(1);
    if (row.endsWith('|') && !row.endsWith(r'\|')) {
      row = row.substring(0, row.length - 1);
    }
    return [for (final cell in row.split(_cellSeparator)) cell.trim()];
  }

  /// [text] without bold markers and surrounding whitespace.
  static String _plain(String text) => text.replaceAll('**', '').trim();
}

/// Combines parsed [files] into one [Spec].
///
/// A requirement ID defined twice is an error that names both locations.
/// [overrides] then set the release of untagged IDs (see [applyOverrides]).
Spec combineSpecFiles(
  List<SpecFile> files, {
  Map<String, ReleaseOverride> overrides = releaseOverrides,
}) {
  final requirements = <Requirement>[];
  final errors = <String>[];
  final firstById = <String, Requirement>{};
  for (final file in files) {
    for (final requirement in file.requirements) {
      final first = firstById[requirement.id];
      if (first != null) {
        errors.add(
          'Duplicate ID ${requirement.id}: defined at ${first.location} '
          'and ${requirement.location}',
        );
        continue;
      }
      firstById[requirement.id] = requirement;
      requirements.add(requirement);
    }
  }
  final overridden = applyOverrides(requirements, overrides);
  return Spec(
    requirements: overridden.requirements,
    errors: errors,
    warnings: [
      for (final file in files) ...file.warnings,
      ...overridden.warnings,
    ],
  );
}

/// Reads the requirements from the top-level `spec/*.md` files under [root].
///
/// Subfolders (`research/`, `questions/`) and [skippedSpecFiles] are not
/// read. Files are parsed in name order, so the result is deterministic.
/// Throws a [FileSystemException] if `spec/` doesn't exist.
Spec readSpec(
  String root, {
  Map<String, ReleaseOverride> overrides = releaseOverrides,
}) {
  final specDir = Directory(p.join(root, 'spec'));
  final paths = [
    for (final entity in specDir.listSync(followLinks: false))
      if (entity is File &&
          entity.path.endsWith('.md') &&
          !skippedSpecFiles.contains(p.basename(entity.path)))
        entity.path,
  ]..sort();
  const parser = SpecParser();
  return combineSpecFiles([
    for (final path in paths)
      parser.parse('spec/${p.basename(path)}', File(path).readAsStringSync()),
  ], overrides: overrides);
}
