import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_text/fb_text.dart';

/// Reads the attached offline catalog pack (A05 D10): a food by ID, by
/// barcode, or by a text query (English, Arabic or Arabizi), and the yield
/// factors.
///
/// Read-only and local. While no pack is attached (first run before the
/// install finished, or an install that failed) every read finds nothing, so
/// callers show personal foods and history only.
final class OfflineCatalog {
  /// Reads the `catalog` schema of [_db]. A pack SQLite can't read (a corrupt
  /// file) counts as absent; [onError] hears about it once, with the error
  /// only (no paths).
  new(this._db, {this.onError});

  final AppDatabase _db;

  /// Told once when a read fails (a pack SQLite can't read).
  final void Function(Object error)? onError;
  bool _reported = false;

  Future<T> _guard<T>(Future<T> Function() read, T absent) async {
    try {
      return await read();
    } on Exception catch (error) {
      if (!_reported) {
        _reported = true;
        onError?.call(error);
      }
      return absent;
    }
  }

  static const String _schema = AppDatabase.catalogSchema;

  /// The food with catalog ID [id], or `null`. A dish ID gives its default
  /// variant.
  Future<CatalogFood?> byId(String id) => _guard(() => _byId(id), null);

  Future<CatalogFood?> _byId(String id) async {
    if (!await _db.isCatalogAttached()) return null;
    final foods = await _foodsWhere(
      'f.id = ? OR f.id = (SELECT default_variant_id FROM $_schema.dishes '
      'WHERE id = ?)',
      [Variable.withString(id), Variable.withString(id)],
    );
    return foods.firstOrNull;
  }

  /// The food with barcode [code], or `null` (the pack has no barcodes yet).
  Future<CatalogFood?> byBarcode(String code) =>
      _guard(() => _byBarcode(code), null);

  Future<CatalogFood?> _byBarcode(String code) async {
    if (code.isEmpty || !await _db.isCatalogAttached()) return null;
    final foods = await _foodsWhere(
      'f.id = (SELECT food_id FROM $_schema.barcodes WHERE code = ?)',
      [Variable.withString(code)],
    );
    return foods.firstOrNull;
  }

  /// Foods whose names match [text], best first (at most [limit]).
  ///
  /// The text is reduced with `normalizeKey`. Words of three or more
  /// characters go through the trigram index; shorter ones (the Arabic `رز`)
  /// match a name that is exactly that word. More matched words rank first,
  /// then the better text match. A dish gives its default variant. A07 owns
  /// the final ranking.
  Future<List<CatalogFood>> search(String text, {int limit = 20}) =>
      _guard(() => _search(text, limit), const []);

  Future<List<CatalogFood>> _search(String text, int limit) async {
    final key = normalizeKey(text);
    if (key.isEmpty || !await _db.isCatalogAttached()) return const [];
    final tokens = key.split(' ').toSet();
    final matched = <String, Set<String>>{};
    final score = <String, double>{};

    for (final token in tokens) {
      final best = <String, double>{};
      if (token.runes.length < 3) {
        for (final id in await _targets(
          'SELECT target_id AS t, 0.0 AS rank FROM $_schema.names '
          'WHERE key = ?',
          token,
        )) {
          best[id.$1] = 0;
        }
      } else {
        for (final (id, rank) in await _targets(
          'SELECT n.target_id AS t, f.rank AS rank FROM ( '
              'SELECT rowid AS rid, bm25(names_fts) AS rank '
              'FROM $_schema.names_fts WHERE names_fts MATCH ?) f '
              'JOIN $_schema.names n ON n.rowid = f.rid',
          '"${token.replaceAll('"', '""')}"',
        )) {
          if (!best.containsKey(id) || rank < best[id]!) best[id] = rank;
        }
      }
      for (final MapEntry(:key, :value) in best.entries) {
        matched.putIfAbsent(key, () => {}).add(token);
        score[key] = (score[key] ?? 0) - value;
      }
    }
    // A name equal to the whole query is the best match.
    for (final (id, _) in await _targets(
      'SELECT target_id AS t, 0.0 AS rank FROM $_schema.names WHERE key = ?',
      key,
    )) {
      matched.putIfAbsent(id, () => {}).addAll(tokens);
      score[id] = (score[id] ?? 0) + 1000;
    }

    final order = score.keys.toList()
      ..sort((a, b) {
        final byTokens = matched[b]!.length.compareTo(matched[a]!.length);
        if (byTokens != 0) return byTokens;
        final byScore = score[b]!.compareTo(score[a]!);
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    final result = <CatalogFood>[];
    final seen = <String>{};
    for (final target in order) {
      if (result.length >= limit) break;
      final food = await _byId(target);
      if (food != null && seen.add(food.id)) result.add(food);
    }
    return result;
  }

  /// The FD-060 yield factors of the pack (empty without a pack).
  Future<List<YieldFactor>> yieldFactors() => _guard(_yieldFactors, const []);

  Future<List<YieldFactor>> _yieldFactors() async {
    if (!await _db.isCatalogAttached()) return const [];
    final rows = await _db
        .customSelect(
          'SELECT yield_group, from_state, to_state, factor '
          'FROM $_schema.yields',
        )
        .get();
    return [
      for (final r in rows)
        if (FoodState.fromCode(r.read<String>('from_state')) case final from?)
          if (FoodState.fromCode(r.read<String>('to_state')) case final to?)
            YieldFactor(
              group: r.read<String>('yield_group'),
              from: from,
              to: to,
              factor: r.read<double>('factor'),
            ),
    ];
  }

  /// The pack's `catalog_version`, or `null` without a pack.
  Future<int?> packVersion() => _guard(() async {
    final v = await _meta('catalog_version');
    return v == null ? null : int.tryParse(v);
  }, null);

  /// The pack version and its data attribution (for the About screen), or
  /// `null` without a readable pack.
  Future<CatalogInfo?> info() => _guard(() async {
    final version = await packVersion();
    if (version == null) return null;
    final raw = await _meta('attribution');
    final decoded = raw == null ? const <Object?>[] : jsonDecode(raw);
    return CatalogInfo(
      packVersion: version,
      attribution: [
        if (decoded is List)
          for (final e in decoded)
            if (e is Map<String, Object?>) CatalogAttribution.fromJson(e),
      ],
    );
  }, null);

  Future<String?> _meta(String key) async {
    if (!await _db.isCatalogAttached()) return null;
    final rows = await _db
        .customSelect(
          'SELECT value FROM $_schema.meta WHERE key = ?',
          variables: [Variable.withString(key)],
        )
        .get();
    return rows.isEmpty ? null : rows.first.read<String>('value');
  }

  Future<List<(String, double)>> _targets(String sql, String arg) async {
    final rows = await _db
        .customSelect(sql, variables: [Variable.withString(arg)])
        .get();
    return [
      for (final r in rows) (r.read<String>('t'), r.read<double>('rank')),
    ];
  }

  Future<List<CatalogFood>> _foodsWhere(
    String where,
    List<Variable<Object>> variables,
  ) async {
    final version = await packVersion() ?? 0;
    final rows = await _db
        .customSelect(
          'SELECT f.* FROM $_schema.foods f WHERE $where ORDER BY f.id',
          variables: variables,
        )
        .get();
    return [for (final r in rows) await _food(r.data, version)];
  }

  Future<CatalogFood> _food(Map<String, Object?> row, int version) async {
    final id = row['id']! as String;
    final basis = row['basis'] == 'per_100ml'
        ? NutrientBasis.per100ml
        : NutrientBasis.per100g;
    final servings = await _db
        .customSelect(
          'SELECT unit_code, g, ml FROM $_schema.servings '
          'WHERE food_id = ? ORDER BY unit_code',
          variables: [Variable.withString(id)],
        )
        .get();
    return CatalogFood(
      id: id,
      kind: row['kind'] == 'basic'
          ? CatalogFoodKind.basic
          : CatalogFoodKind.variant,
      nameEn: row['name_en']! as String,
      nameAr: row['name_ar'] as String?,
      dishId: row['dish_id'] as String?,
      state: FoodState.fromCode(row['state']! as String) ?? FoodState.asSold,
      basis: basis,
      nutrients: Nutrients(
        kcal: _num(row['kcal']),
        protein: _num(row['protein_g']),
        carbs: _num(row['carbs_g']),
        fat: _num(row['fat_g']),
        fiber: _num(row['fiber_g']),
        extras: _extras(row['extras_json'] as String?),
      ),
      servingUnits: [
        for (final s in servings)
          if (s.read<double?>('g') case final g?)
            ServingUnit.grams(s.read<String>('unit_code'), g)
          else if (s.read<double?>('ml') case final ml?)
            ServingUnit.milliliters(s.read<String>('unit_code'), ml),
      ],
      densityGramsPerMl: (row['density_g_per_ml'] as num?)?.toDouble(),
      yieldGroup: row['yield_group'] as String?,
      badge:
          CatalogBadge.fromSource(row['source']! as String) ??
          CatalogBadge.database,
      verified: row['verified'] == 1,
      isDraft: row['review_status'] == 'draft',
      packVersion: version,
    );
  }

  static double _num(Object? v) => (v! as num).toDouble();

  static Map<NutrientKey, double> _extras(String? json) {
    if (json == null) return const {};
    final decoded = jsonDecode(json) as Map<String, Object?>;
    return {
      for (final e in decoded.entries)
        ?NutrientKey.fromCode(e.key): (e.value! as num).toDouble(),
    };
  }
}
