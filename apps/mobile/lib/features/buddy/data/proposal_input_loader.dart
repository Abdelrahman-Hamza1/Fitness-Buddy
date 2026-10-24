import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_api_client/fb_api_client.dart' show ClientConfig;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/diary.dart'
    show DiaryReads, nutrientsOf;
import 'package:fb_mobile/features/foods/foods.dart' show personalFoodOf;
import 'package:fb_text/fb_text.dart';

/// Read-only, one-shot local adapter. The request owns every subsequent fact;
/// recompute has no reference to this loader, database or configuration port.
final class ProposalInputLoader {
  /// Config is a synchronous snapshot of the already-loaded ClientConfig.
  const new(this._db, {required this._config});
  final AppDatabase _db;
  final ClientConfig Function() _config;

  /// Load before computation; never refresh config, contact a server or write.
  Future<ProposalResult<ProposalRequest>> load({
    required Map<String, Object?> interpretation,
    required String messageId,
    required ProposalIdSource idSource,
    required EntryTime referenceTime,
    required LocalDate today,
    SlotMode mode = SlotMode.normal,
    int confirmedRevision = 0,
  }) async {
    try {
      final config = _config();
      final keys = <String>{};
      var work = 0;
      void collect(Object? value, int depth) {
        if (depth > 32 || ++work > 524288) throw const _LoadFailure();
        if (value is Map<String, Object?>) {
          if (value.length > 64) throw const _LoadFailure();
          if (value['key'] case final String key) keys.add(key);
          for (final v in value.values) {
            collect(v, depth + 1);
          }
        } else if (value is List<Object?>) {
          if (value.length > 64) throw const _LoadFailure();
          for (final v in value) {
            collect(v, depth + 1);
          }
        } else if (value is String) {
          work += value.length;
        }
      }

      collect(interpretation, 0);
      if (keys.length > 200 || work > 524288) throw const _LoadFailure();
      // Freeze JSON before awaiting database reads; caller mutations cannot
      // change this snapshot.
      final json =
          jsonDecode(jsonEncode(interpretation)) as Map<String, Object?>;
      return await _db.readSnapshot(() async {
        final personal = <String, ProposalFood>{};
        if (keys.isNotEmpty) {
          final rows = await (_db.select(
            _db.personalFoods,
          )..where((t) => t.id.isIn(keys) & t.deletedAt.isNull())).get();
          for (final row in rows) {
            final food = personalFoodOf(row);
            final d = food.draft;
            personal[food.id] = ProposalFood(
              key: food.id,
              names: d.names,
              state: d.state,
              source: .yours,
              per100: d.per100,
              basis: d.basis,
              origin: .localPersonal,
              personalVersion: food.version,
              servings: [
                for (final s in d.servings)
                  ProposalServing(s.unit, s.amount, d.basis, null, null),
                if (d.entryServing case final s?)
                  if (!d.servings.any((v) => v.unit == s.unit))
                    ProposalServing(s.unit, s.amount, d.basis, null, null),
              ],
            );
          }
        }
        final attached = await _db.isCatalogAttached();
        final catalog = <String, ProposalFood>{};
        final fats = <String>{};
        final yields = <YieldFactor>[];
        if (attached) {
          final meta = await _db
              .customSelect(
                'SELECT value FROM catalog.meta WHERE key = ?',
                variables: [Variable.withString('cooking_fat_ids')],
              )
              .get();
          if (meta.isNotEmpty) {
            final text = meta.single.read<String>('value');
            if (text.length > 32768) throw const _LoadFailure();
            final value = jsonDecode(text);
            if (value is! List || value.any((v) => v is! String || v.isEmpty)) {
              throw const _LoadFailure();
            }
            fats.addAll(value.cast<String>());
          }
          final rows = await _db
              .customSelect(
                'SELECT * FROM catalog.foods WHERE id IN '
                '(SELECT value FROM json_each(?))',
                variables: [Variable.withString(jsonEncode(keys.toList()))],
              )
              .get();
          final servings = await _db
              .customSelect(
                'SELECT * FROM catalog.servings WHERE food_id IN '
                '(SELECT value FROM json_each(?)) ORDER BY food_id, unit_code',
                variables: [Variable.withString(jsonEncode(keys.toList()))],
              )
              .get();
          for (final r in rows) {
            final id = r.read<String>('id');
            final state = FoodState.fromCode(r.read<String>('state'));
            final source = switch (r.read<String>('source')) {
              'usda' => FoodSource.database,
              'reference' => FoodSource.reference,
              _ => throw const _LoadFailure(),
            };
            final basis = switch (r.read<String>('basis')) {
              'per_100g' => NutrientBasis.per100g,
              'per_100ml' => NutrientBasis.per100ml,
              _ => throw const _LoadFailure(),
            };
            if (state == null) throw const _LoadFailure();
            Nutrients nutrients(String suffix) => Nutrients(
              kcal: r.read<double>('kcal$suffix'),
              protein: r.read<double>(
                suffix.isEmpty ? 'protein_g' : 'protein$suffix',
              ),
              carbs: r.read<double>(
                suffix.isEmpty ? 'carbs_g' : 'carbs$suffix',
              ),
              fat: r.read<double>(suffix.isEmpty ? 'fat_g' : 'fat$suffix'),
              fiber: r.read<double>(
                suffix.isEmpty ? 'fiber_g' : 'fiber$suffix',
              ),
            );
            catalog[id] = ProposalFood(
              key: id,
              names: FoodNames(
                r.read<String>('name_en'),
                ar: r.read<String?>('name_ar'),
              ),
              state: state,
              source: source,
              per100: nutrientsOf(
                kcal: r.read<double>('kcal'),
                proteinG: r.read<double>('protein_g'),
                carbsG: r.read<double>('carbs_g'),
                fatG: r.read<double>('fat_g'),
                fiberG: r.read<double>('fiber_g'),
                extrasJson: r.read<String?>('extras_json'),
              ),
              basis: basis,
              origin: .localCatalog,
              version: '${r.read<int>('catalog_version')}',
              density: r.read<double?>('density_g_per_ml'),
              yieldGroup: r.read<String?>('yield_group'),
              range: r.read<double?>('kcal_low') == null
                  ? null
                  : ProposalRange(nutrients('_low'), nutrients('_high')),
              servings: [
                for (final s in servings.where(
                  (s) => s.read<String>('food_id') == id,
                ))
                  ProposalServing(
                    s.read<String>('unit_code'),
                    s.read<double?>('g') ?? s.read<double>('ml'),
                    s.read<double?>('g') == null ? .per100ml : .per100g,
                    s.read<double?>('range_lo'),
                    s.read<double?>('range_hi'),
                  ),
              ],
            );
          }
          for (final r
              in await _db.customSelect('SELECT * FROM catalog.yields').get()) {
            final from = FoodState.fromCode(r.read<String>('from_state'));
            final to = FoodState.fromCode(r.read<String>('to_state'));
            if (from == null || to == null) throw const _LoadFailure();
            yields.add(
              YieldFactor(
                group: r.read<String>('yield_group'),
                from: from,
                to: to,
                factor: r.read<double>('factor'),
              ),
            );
          }
        }
        final reads = DiaryReads(_db);
        // Only today/yesterday are resolved by v1; explicit later date edits
        // receive refreshed confirmed totals from the application context.
        final totals = await reads.dailyTotals(
          referenceTime.localDate.plusDays(-1),
          referenceTime.localDate,
        );
        final context = ProposalContext(
          referenceTime: referenceTime,
          slots: await reads.slots(),
          yields: yields,
          mode: mode,
          normalize: normalizeKey,
          dayContext: ProposalDayContext(
            today: today,
            revision: confirmedRevision,
            confirmed: {for (final t in totals) t.date: t.totals},
          ),
        );
        final request = ProposalRequest(
          interpretation: json,
          messageId: messageId,
          idSource: idSource,
          context: context,
          facts: ProposalFacts(
            personal: personal,
            catalog: catalog,
            packAvailable: attached,
            cookingFatIds: fats,
          ),
          policy: ProposalPolicy.fromThresholds(config.thresholds),
        );
        if (request.interpretation.issue case final issue?) {
          return ProposalResult<ProposalRequest>.failure(issue);
        }
        return ProposalResult.success(request);
      });
    } on Object {
      // Parser/SQL/row exceptions can contain user values or paths. They never
      // escape this adapter and no diagnostic callback receives their content.
      return const ProposalResult.failure(ProposalIssue.invalidInput);
    }
  }

  @override
  String toString() => 'ProposalInputLoader(redacted)';
}

final class _LoadFailure implements Exception {
  const new();
}
