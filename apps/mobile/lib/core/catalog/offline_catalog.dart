import 'dart:async';
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
  new(this._db, {this.onError}) {
    _packSub = packChanges.listen((_) => _readiness = null);
  }

  final AppDatabase _db;
  late final StreamSubscription<void> _packSub;
  Future<bool>? _readiness;

  // Initial attachment is awaited once. Swaps invalidate this before the
  // search session refreshes, avoiding readiness SQL on every keystroke.
  Future<bool> _isReady() => _readiness ??= _db.isCatalogAttached();

  /// Releases the pack invalidation subscription.
  void dispose() => unawaited(_packSub.cancel());

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

  /// Pack swap invalidations; initial attachment is covered by the eager
  /// search-session refresh after the database opens.
  Stream<void> get packChanges => _db
      .tableUpdates(const TableUpdateQuery.onTableName('catalog_pack'))
      .map((_) {});

  /// The food with catalog ID [id], or `null`. A dish ID gives its default
  /// variant.
  Future<CatalogFood?> byId(String id) => _guard(() => _byId(id), null);

  Future<CatalogFood?> _byId(String id) async {
    if (!await _isReady()) return null;
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
    if (code.isEmpty || !await _isReady()) return null;
    final foods = await _foodsWhere(
      'f.id = (SELECT food_id FROM $_schema.barcodes WHERE code = ?)',
      [Variable.withString(code)],
    );
    return foods.firstOrNull;
  }

  /// Foods whose names match all of [text]'s tokens, best first.
  /// Uses the same ordered, batched path as A07, without fuzzy or history.
  /// The legacy API returns at most [limit] rows and a dish's default variant;
  /// the search service owns final merging, ranking and quantity handling.
  Future<List<CatalogFood>> search(String text, {int limit = 20}) =>
      _guard(() => _search(text, limit), const []);

  Future<List<CatalogFood>> _search(String text, int limit) async {
    final key = normalizeKey(text);
    if (key.isEmpty || limit <= 0) return const [];
    final names = await candidateNames(CandidateQuery(key));
    final best = <String, MatchStrength>{};
    for (final name in names) {
      final strength = NameMatcher.match(key, key.split(' '), name.key);
      if (strength != null &&
          strength != MatchStrength.partial &&
          (!best.containsKey(name.targetId) ||
              strength.index > best[name.targetId]!.index)) {
        best[name.targetId] = strength;
      }
    }
    final order = best.keys.toList()
      ..sort((a, b) {
        final strength = best[b]!.index.compareTo(best[a]!.index);
        return strength != 0 ? strength : a.compareTo(b);
      });
    final foods = await foodsByIds(order);
    final seen = <String>{};
    return [
      for (final id in order)
        if (foods[id] case final variants?)
          for (final f in variants.where(
            (f) => f.dishId == null || f.isDefaultVariant,
          ))
            if (seen.add(f.id)) f,
    ].take(limit).toList();
  }

  static String _quote(String value) => "'${value.replaceAll("'", "''")}'";
  static String _like(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  static const _foodTarget =
      '(n.target_id IN (SELECT id FROM catalog.foods) '
      'OR n.target_id IN (SELECT id FROM catalog.dishes))';

  /// PA10: uncapped exact, then 500 prefixes, then the 300 best token rows.
  /// One SQL batch; token phrases use FTS while short words use word prefixes.
  Future<List<CatalogNameRow>> candidateNames(CandidateQuery query) => _guard(
    () async {
      if (query.key.isEmpty || !await _isReady()) return const [];
      final tokens = query.key.split(' ').where((t) => t.isNotEmpty).take(6);
      final conditions = <String>[];
      final hits = <String>[];
      for (final token in tokens) {
        final words = [token, ...?query.corrections[token]];
        final prefixes = [
          for (final word in words)
            "(' ' || n.key) LIKE ${_quote('% ${_like(word)}%')} ESCAPE '\\'",
        ];
        hits.add('(CASE WHEN (${prefixes.join(' OR ')}) THEN 1 ELSE 0 END)');
        for (final word in words) {
          conditions.add(
            word.runes.length < 3
                ? prefixes[words.indexOf(word)]
                : 'n.rowid IN (SELECT rowid FROM $_schema.names_fts '
                      'WHERE names_fts MATCH '
                      '${_quote('"${word.replaceAll('"', '""')}"')})',
          );
        }
      }
      final score = hits.isEmpty ? '0' : hits.join(' + ');
      final key = _quote(query.key);
      final tokenWhere = conditions.isEmpty ? '0' : conditions.join(' OR ');
      final rows = await _db
          .customSelect(
            'WITH exact AS ( '
            'SELECT n.rowid AS rid, n.*, $score AS word_hits, '
            '0 AS pass FROM $_schema.names n '
            'WHERE $_foodTarget AND n.key = $key), prefix AS ( '
            'SELECT n.rowid AS rid, n.*, $score AS word_hits, '
            '1 AS pass FROM $_schema.names n '
            'WHERE $_foodTarget AND n.key > $key AND n.key '
            '< $key || char(1114111) '
            'ORDER BY length(n.key), n.key, n.rowid LIMIT 500), token AS ( '
            'SELECT n.rowid AS rid, n.*, $score AS word_hits, '
            '2 AS pass FROM $_schema.names n '
            'WHERE $_foodTarget AND ($tokenWhere) '
            'ORDER BY word_hits DESC, length(n.key), n.key, n.rowid LIMIT 300) '
            'SELECT * FROM exact UNION ALL SELECT * FROM prefix '
            'UNION ALL SELECT * FROM token',
          )
          .get();
      final seen = <int>{};
      return [
        for (final r in rows)
          if (seen.add(r.read<int>('rid'))) _name(r),
      ];
    },
    const [],
  );

  CatalogNameRow _name(QueryRow r) => CatalogNameRow(
    rowid: r.read<int>('rid'),
    targetId: r.read<String>('target_id'),
    lang: r.read<String>('lang'),
    key: r.read<String>('key'),
    isDisplay: r.read<int>('is_display') == 1,
    wordHits: r.read<int>('word_hits'),
    pass: CandidatePass.values[r.read<int>('pass')],
  );

  /// History aliases, uncapped and indexed by target (PA1).
  Future<List<CatalogNameRow>> namesForTargets(Iterable<String> ids) => _guard(
    () async {
      if (!await _isReady()) return const [];
      final rows = await _db
          .customSelect(
            'SELECT rowid AS rid, *, 0 AS word_hits, 0 AS pass '
            'FROM $_schema.names WHERE target_id IN (SELECT '
            'value FROM json_each(?))',
            variables: [Variable.withString(jsonEncode(ids.toSet().toList()))],
          )
          .get();
      return rows.map(_name).toList();
    },
    const [],
  );

  /// Pack vocabulary is read only during refresh, never while typing.
  Future<List<String>> vocabularyKeys() => _guard(() async {
    if (!await _isReady()) return const [];
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT n.key FROM $_schema.names n WHERE $_foodTarget',
        )
        .get();
    return [for (final r in rows) r.read<String>('key')];
  }, const []);

  /// Two batched reads, including every variant of a dish (PA5, backlog #70).
  Future<Map<String, List<CatalogFood>>> foodsByIds(Iterable<String> ids) =>
      _guard(() async {
        final targets = ids.toSet();
        if (targets.isEmpty || !await _isReady()) return const {};
        final foods = await _foodsWhere(
          'f.id IN (SELECT value FROM json_each(?)) OR f.dish_id '
          'IN (SELECT value FROM json_each(?))',
          [
            Variable.withString(jsonEncode(targets.toList())),
            Variable.withString(jsonEncode(targets.toList())),
          ],
        );
        return {
          for (final id in targets)
            id: [
              for (final f in foods)
                if (f.id == id || f.dishId == id) f,
            ],
        };
      }, const {});

  /// All potential state siblings; compatibility is checked in the domain.
  Future<List<CatalogFood>> foodsInYieldGroup(String group) => _guard(() async {
    if (!await _isReady()) return const [];
    return await _foodsWhere('f.yield_group = ?', [Variable.withString(group)]);
  }, const []);

  /// The FD-060 yield factors of the pack (empty without a pack).
  Future<List<YieldFactor>> yieldFactors() => _guard(_yieldFactors, const []);

  Future<List<YieldFactor>> _yieldFactors() async {
    if (!await _isReady()) return const [];
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

  /// Optional reviewed cooking-fat classification; absence never infers roles.
  Future<Set<String>> cookingFatIds() => _guard(() async {
    final raw = await _meta('cooking_fat_ids');
    if (raw == null) return const <String>{};
    if (raw.length > 32768) throw const FormatException();
    final value = jsonDecode(raw);
    if (value is! List || value.any((v) => v is! String || v.isEmpty)) {
      throw const FormatException();
    }
    return Set.unmodifiable(value.cast<String>());
  }, const <String>{});

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
    if (!await _isReady()) return null;
    final rows = await _db
        .customSelect(
          'SELECT value FROM $_schema.meta WHERE key = ?',
          variables: [Variable.withString(key)],
        )
        .get();
    return rows.isEmpty ? null : rows.first.read<String>('value');
  }

  Future<List<CatalogFood>> _foodsWhere(
    String where,
    List<Variable<Object>> variables,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT f.*, (f.id = d.default_variant_id) AS is_default '
          'FROM $_schema.foods f '
          'LEFT JOIN $_schema.dishes d ON d.id = f.dish_id '
          'WHERE $where ORDER BY f.id',
          variables: variables,
        )
        .get();
    if (rows.isEmpty) return [];
    final servings = await _db
        .customSelect(
          'SELECT food_id, unit_code, g, ml, range_lo, range_hi '
          'FROM $_schema.servings '
          'WHERE food_id IN (SELECT value FROM json_each(?)) '
          'ORDER BY unit_code',
          variables: [
            Variable.withString(
              jsonEncode([for (final r in rows) r.read<String>('id')]),
            ),
          ],
        )
        .get();
    final units = <String, List<ServingUnit>>{};
    for (final s in servings) {
      final unit = s.read<double?>('g') != null
          ? ServingUnit.grams(s.read<String>('unit_code'), s.read<double>('g'))
          : ServingUnit.milliliters(
              s.read<String>('unit_code'),
              s.read<double>('ml'),
            );
      units.putIfAbsent(s.read<String>('food_id'), () => []).add(unit);
    }
    return [
      for (final r in rows)
        _food(r.data, units[r.read<String>('id')] ?? [], {
          for (final s in servings.where(
            (s) => s.read<String>('food_id') == r.read<String>('id'),
          ))
            if (s.read<double?>('range_lo') case final low?)
              s.read<String>('unit_code'): (low, s.read<double>('range_hi')),
        }),
    ];
  }

  CatalogFood _food(
    Map<String, Object?> row,
    List<ServingUnit> units,
    Map<String, (double, double)> ranges,
  ) => CatalogFood(
    id: row['id']! as String,
    kind: row['kind'] == 'basic'
        ? CatalogFoodKind.basic
        : CatalogFoodKind.variant,
    nameEn: row['name_en']! as String,
    nameAr: row['name_ar'] as String?,
    dishId: row['dish_id'] as String?,
    state: FoodState.fromCode(row['state']! as String) ?? FoodState.asSold,
    basis: row['basis'] == 'per_100ml'
        ? NutrientBasis.per100ml
        : NutrientBasis.per100g,
    nutrients: Nutrients(
      kcal: _num(row['kcal']),
      protein: _num(row['protein_g']),
      carbs: _num(row['carbs_g']),
      fat: _num(row['fat_g']),
      fiber: _num(row['fiber_g']),
      extras: _extras(row['extras_json'] as String?),
    ),
    servingUnits: units,
    servingRanges: Map.unmodifiable(ranges),
    nutrientsLow: _bounds(row, 'low'),
    nutrientsHigh: _bounds(row, 'high'),
    densityGramsPerMl: (row['density_g_per_ml'] as num?)?.toDouble(),
    yieldGroup: row['yield_group'] as String?,
    badge:
        CatalogBadge.fromSource(row['source']! as String) ??
        CatalogBadge.database,
    verified: row['verified'] == 1,
    isDraft: row['review_status'] == 'draft',
    packVersion: row['catalog_version']! as int,
    sanity: CatalogSanity.values.firstWhere(
      (s) => s.name == row['sanity'],
      orElse: () => CatalogSanity.ok,
    ),
    isDefaultVariant: row['is_default'] == 1,
  );

  static Nutrients? _bounds(Map<String, Object?> row, String suffix) =>
      row['kcal_$suffix'] == null
      ? null
      : Nutrients(
          kcal: _num(row['kcal_$suffix']),
          protein: _num(row['protein_$suffix']),
          carbs: _num(row['carbs_$suffix']),
          fat: _num(row['fat_$suffix']),
          fiber: _num(row['fiber_$suffix']),
        );

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
