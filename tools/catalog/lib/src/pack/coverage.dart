import 'package:fb_catalog/src/load/yaml_json.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/pack/pack_query.dart';
import 'package:yaml/yaml.dart';

/// One line of `data/must_cover.yaml`.
class MustCoverItem {
  const new({
    required this.id,
    required this.group,
    required this.names,
    required this.match,
  });

  final String id;
  final String group;
  final Names names;

  /// Catalog IDs (or prefixes) that count as this item.
  final List<String> match;

  /// Whether [target] is this item: equal to a match entry or a variant /
  /// longer slug of one (`ref:falafel` -> `ref:falafel/sandwich`,
  /// `ref:falafel_sandwich`).
  bool matches(String target) => match.any(
    (m) =>
        target == m || target.startsWith('$m/') || target.startsWith('${m}_'),
  );
}

/// The must-cover file is malformed.
class MustCoverException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses the text of `must_cover.yaml`:
///
/// ```yaml
/// groups:
///   - id: main
///     items:
///       - id: maqluba            # slug; matches ref:maqluba or usda:maqluba
///         names: {en: [..], ar: [..], arabizi: [..]}
///         match: [ref:maqluba]   # optional; replaces the default
/// ```
List<MustCoverItem> parseMustCover(
  String text, {
  String source = 'must_cover',
}) {
  final Object? doc;
  try {
    doc = yamlToPlain(loadYaml(text));
  } on YamlException catch (e) {
    throw MustCoverException('$source: ${e.message}');
  }
  if (doc is! Map || doc['groups'] is! List) {
    throw MustCoverException('$source: expected a `groups:` list');
  }
  final items = <MustCoverItem>[];
  final seen = <String>{};
  for (final group in doc['groups'] as List) {
    if (group is! Map || group['id'] is! String || group['items'] is! List) {
      throw MustCoverException('$source: each group needs `id` and `items`');
    }
    for (final item in group['items'] as List) {
      if (item is! Map || item['id'] is! String || item['names'] is! Map) {
        throw MustCoverException(
          '$source: group ${group['id']}: each item needs `id` and `names`',
        );
      }
      final id = item['id'] as String;
      if (!seen.add(id)) {
        throw MustCoverException('$source: duplicate item `$id`');
      }
      final rawNames = item['names'] as Map;
      final names = <String, List<String>>{};
      for (final lang in rawNames.keys) {
        if (!nameLanguages.contains(lang)) {
          throw MustCoverException('$source: `$id`: unknown language `$lang`');
        }
        names[lang as String] = [for (final n in rawNames[lang] as List) '$n'];
      }
      if ((names['en'] ?? const []).isEmpty) {
        throw MustCoverException('$source: `$id`: names.en is required');
      }
      final match = item['match'] is List
          ? [for (final m in item['match'] as List) '$m']
          : ['ref:$id', 'usda:$id'];
      items.add(
        MustCoverItem(
          id: id,
          group: group['id'] as String,
          names: names,
          match: match,
        ),
      );
    }
  }
  return items;
}

/// How an item stands in the pack.
enum CoverStatus { reviewed, draft, basic, missing }

class CoverRow {
  const new({
    required this.item,
    required this.status,
    required this.byLang,
    required this.target,
  });

  final MustCoverItem item;
  final CoverStatus status;

  /// Whether a name in that language found the item in the top results.
  final Map<String, bool> byLang;

  /// The best matching catalog ID, if any.
  final String? target;
}

/// Looks every name of every item up in the pack and reports whether it
/// resolves by English, Arabic and Arabizi names (top [top] hits).
List<CoverRow> measureCoverage(
  PackSearch search,
  List<MustCoverItem> items, {
  int top = 5,
}) {
  final rows = <CoverRow>[];
  for (final item in items) {
    final byLang = <String, bool>{};
    final found = <String>[];
    for (final lang in nameLanguages) {
      var ok = false;
      for (final name in item.names[lang] ?? const <String>[]) {
        for (final hit in search.search(name, limit: top)) {
          if (item.matches(hit.target)) {
            ok = true;
            found.add(hit.target);
            break;
          }
        }
        if (ok) break;
      }
      byLang[lang] = ok;
    }
    if (found.isEmpty) {
      rows.add(
        CoverRow(
          item: item,
          status: CoverStatus.missing,
          byLang: byLang,
          target: null,
        ),
      );
      continue;
    }
    // Prefer the plain dish / basic over its variants for the report.
    found.sort((a, b) {
      final byVariant = a.contains('/') == b.contains('/')
          ? 0
          : (a.contains('/') ? 1 : -1);
      return byVariant != 0 ? byVariant : a.length.compareTo(b.length);
    });
    final target = found.first;
    final status = target.startsWith('usda:')
        ? CoverStatus.basic
        : search.reviewStatus(target) == 'reviewed'
        ? CoverStatus.reviewed
        : CoverStatus.draft;
    rows.add(
      CoverRow(item: item, status: status, byLang: byLang, target: target),
    );
  }
  return rows;
}

/// The coverage table as Markdown text.
String formatCoverage(List<CoverRow> rows) {
  final b = StringBuffer()
    ..writeln('| Group | Item | EN | AR | Arabizi | Status | Target |')
    ..writeln('|---|---|---|---|---|---|---|');
  String mark({required bool ok}) => ok ? 'yes' : '-';
  for (final r in rows) {
    b.writeln(
      '| ${r.item.group} | ${r.item.id} | ${mark(ok: r.byLang['en']!)} | '
      '${mark(ok: r.byLang['ar']!)} | ${mark(ok: r.byLang['arabizi']!)} | '
      '${r.status.name} | ${r.target ?? ''} |',
    );
  }
  final counts = {
    for (final s in CoverStatus.values)
      s: rows.where((r) => r.status == s).length,
  };
  b
    ..writeln()
    ..write('Must-cover: ${rows.length} items');
  for (final s in CoverStatus.values) {
    b.write(', ${counts[s]} ${s.name}');
  }
  b.writeln();
  return b.toString();
}
