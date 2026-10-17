import 'package:fb_text/fb_text.dart';
import 'package:sqlite3/sqlite3.dart';

/// One ranked result of [PackSearch.search]: a basic, a dish or a variant.
class PackHit {
  const new({
    required this.target,
    required this.name,
    required this.matchedTokens,
    required this.score,
    required this.kcalPer100,
    this.reviewStatus,
  });

  /// Catalog ID: `usda:...`, `ref:<dish>` or `ref:<dish>/<variant>`.
  final String target;

  /// The English display name when there is one, else the matched name.
  final String name;

  /// How many query tokens matched a name of this target.
  final int matchedTokens;
  final double score;
  final double? kcalPer100;

  /// `draft` or `reviewed` for dishes and their variants; `null` for basics.
  final String? reviewStatus;
}

/// Prototype search over the pack (A03 D9). A05 finalises the schema and A07
/// owns ranking; this only proves the names can be found.
///
/// The query is reduced with `normalizeKey`, split on spaces. Tokens of three
/// or more characters are looked up through the FTS5 trigram index; shorter
/// ones (such as the Arabic `رز`) can't match a trigram, so they match a name
/// whose whole key is exactly that token. Results are ordered by matched
/// tokens, then by bm25.
class PackSearch {
  new(this._db);

  /// Opens the pack at [path] read-only.
  factory open(String path) =>
      PackSearch(sqlite3.open(path, mode: OpenMode.readOnly));

  final Database _db;

  void close() => _db.close();

  /// Whether the pack was built with draft dishes (`meta.includes_drafts`).
  bool get includesDrafts => _meta('includes_drafts') == '1';

  String? _meta(String key) {
    final rows = _db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Map<String, String> get meta => {
    for (final r in _db.select('SELECT key, value FROM meta ORDER BY key'))
      r['key'] as String: r['value'] as String,
  };

  List<PackHit> search(String text, {int limit = 10}) {
    final key = normalizeKey(text);
    if (key.isEmpty) return const [];
    final tokens = key.split(' ').toSet().toList();
    final matched = <String, Set<String>>{};
    final scores = <String, double>{};
    final matchedName = <String, String>{};

    void note(String target, String token, double score, String name) {
      matched.putIfAbsent(target, () => {}).add(token);
      scores[target] = (scores[target] ?? 0) + score;
      matchedName.putIfAbsent(target, () => name);
    }

    for (final token in tokens) {
      if (token.runes.length < 3) {
        for (final r in _db.select(
          'SELECT target, name FROM names WHERE key = ?',
          [token],
        )) {
          note(r['target'] as String, token, 0, r['name'] as String);
        }
        continue;
      }
      // Best (lowest) bm25 per target for this token.
      final best = <String, double>{};
      final names = <String, String>{};
      for (final r in _db.select(
        'SELECT n.target AS target, n.name AS name, bm25(names_fts) AS rank '
        'FROM names_fts JOIN names n ON n.rowid = names_fts.rowid '
        'WHERE names_fts MATCH ?',
        ['"$token"'],
      )) {
        final t = r['target'] as String;
        final rank = (r['rank'] as num).toDouble();
        if (!best.containsKey(t) || rank < best[t]!) {
          best[t] = rank;
          names[t] = r['name'] as String;
        }
      }
      for (final e in best.entries) {
        note(e.key, token, -e.value, names[e.key]!);
      }
    }
    // A name equal to the whole query is the best possible match.
    for (final r in _db.select('SELECT target, name FROM names WHERE key = ?', [
      key,
    ])) {
      final t = r['target'] as String;
      scores[t] = (scores[t] ?? 0) + 1000;
      matched.putIfAbsent(t, () => {}).addAll(tokens);
      matchedName.putIfAbsent(t, () => r['name'] as String);
    }

    final order = scores.keys.toList()
      ..sort((a, b) {
        final byTokens = matched[b]!.length.compareTo(matched[a]!.length);
        if (byTokens != 0) return byTokens;
        final byScore = scores[b]!.compareTo(scores[a]!);
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    return [
      for (final t in order.take(limit)) _hit(t, matched, scores, matchedName),
    ];
  }

  /// `draft` or `reviewed` for a dish or variant ID; `null` for a basic.
  String? reviewStatus(String target) {
    final dishId = target.contains('/')
        ? target.substring(0, target.indexOf('/'))
        : target;
    final rows = _db.select('SELECT review_status FROM dishes WHERE id = ?', [
      dishId,
    ]);
    return rows.isEmpty ? null : rows.first['review_status'] as String;
  }

  PackHit _hit(
    String target,
    Map<String, Set<String>> matched,
    Map<String, double> scores,
    Map<String, String> matchedName,
  ) {
    final display = _db.select(
      "SELECT name FROM names WHERE target = ? AND lang = 'en' AND display = 1",
      [target],
    );
    final food = _db.select(
      'SELECT typ_kcal FROM foods WHERE id = ? OR id = '
      "(SELECT d.id || '/' || d.default_variant FROM dishes d WHERE d.id = ?)",
      [target, target],
    );
    return PackHit(
      target: target,
      name: display.isEmpty
          ? matchedName[target]!
          : display.first['name'] as String,
      matchedTokens: matched[target]!.length,
      score: scores[target]!,
      kcalPer100: food.isEmpty
          ? null
          : (food.first['typ_kcal'] as num).toDouble(),
      reviewStatus: reviewStatus(target),
    );
  }
}
