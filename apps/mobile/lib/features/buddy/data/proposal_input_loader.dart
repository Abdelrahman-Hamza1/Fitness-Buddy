import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_api_client/fb_api_client.dart' show ClientConfig;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/diary.dart' show DiaryReads;
import 'package:fb_mobile/features/foods/foods.dart' show personalFoodOf;
import 'package:fb_text/fb_text.dart';

/// Read-only, one-shot local adapter. The request owns every subsequent fact;
/// recompute has no reference to this loader, database or configuration port.
final class ProposalInputLoader {
  /// Config is a synchronous snapshot of the already-loaded ClientConfig.
  const new(this._db, {required this._catalog, required this._config});
  final AppDatabase _db;
  final OfflineCatalog _catalog;
  final ClientConfig Function() _config;

  /// Restore with facts read from the current personal rows and installed pack.
  /// Draft keys only select reads; serialized facts never verify themselves.
  Future<ProposalBuildResult> restore({
    required Map<String, Object?> message,
    required Iterable<Map<String, Object?>> cards,
    required EntryTime referenceTime,
  }) async {
    final bounded = ProposalDraftCodec.validateRestoreInput(message, cards);
    if (bounded.issue case final issue?) return ProposalResult.failure(issue);
    final rows = [
      for (final row in bounded.value!)
        jsonDecode(jsonEncode(row)) as Map<String, Object?>,
    ];
    final budget = jsonDecode(jsonEncode(message)) as Map<String, Object?>;
    final keys = <String>{};
    for (final row in rows) {
      if (row['foods'] case final List<Object?> foods) {
        for (final food in foods) {
          if (food is List<Object?> &&
              food.isNotEmpty &&
              food.first is String) {
            keys.add(food.first! as String);
          }
        }
      }
    }
    return await _loadSnapshot(
      interpretation: const {},
      restoreKeys: keys,
      referenceTime: referenceTime,
      build: (facts, context, config, json) => ProposalDraftCodec.restore(
        budget,
        rows,
        context: context,
        trustedFacts: TrustedFoodFacts(
          foods: {...facts.catalog, ...facts.personal},
          yields: context.yields,
        ),
      ),
    );
  }

  /// Load before computation; never refresh config, contact a server or write.
  Future<ProposalResult<ProposalRequest>> load({
    required Map<String, Object?> interpretation,
    required String messageId,
    required ProposalIdSource idSource,
    required EntryTime referenceTime,
    SlotMode mode = SlotMode.normal,
    int confirmedRevision = 0,
  }) => _loadSnapshot(
    interpretation: interpretation,
    referenceTime: referenceTime,
    mode: mode,
    confirmedRevision: confirmedRevision,
    build: (facts, context, config, json) {
      final request = ProposalRequest(
        interpretation: json,
        messageId: messageId,
        idSource: idSource,
        context: context,
        facts: facts,
        policy: ProposalPolicy.fromThresholds(config.thresholds),
      );
      if (request.interpretation.issue case final issue?) {
        return ProposalResult.failure(issue);
      }
      return ProposalResult.success(request);
    },
  );

  /// A fresh, read-only context at [referenceTime]: current slots, yields
  /// and confirmed totals, for recomputing open cards after a confirm or an
  /// undo (A22 D12) so a confirmed sibling counts once through confirmed
  /// intake. `null` when it can't be read (never content-bearing).
  /// [days] adds the confirmed totals of cards on other days (day hints).
  Future<ProposalContext?> refreshContext({
    required EntryTime referenceTime,
    SlotMode mode = SlotMode.normal,
    int confirmedRevision = 0,
    Set<LocalDate> days = const {},
  }) async => (await _loadSnapshot<ProposalContext>(
    interpretation: const {},
    referenceTime: referenceTime,
    mode: mode,
    confirmedRevision: confirmedRevision,
    days: days,
    build: (_, context, _, _) => ProposalResult.success(context),
  )).value;

  Future<ProposalResult<T>> _loadSnapshot<T>({
    required Map<String, Object?> interpretation,
    required EntryTime referenceTime,
    required ProposalResult<T> Function(
      ProposalFacts,
      ProposalContext,
      ClientConfig,
      Map<String, Object?>,
    )
    build,
    Set<String> restoreKeys = const {},
    SlotMode mode = SlotMode.normal,
    int confirmedRevision = 0,
    Set<LocalDate> days = const {},
  }) async {
    try {
      final config = _config();
      final keys = {...restoreKeys};
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
        final aliases = <String, String>{};
        final yields = <YieldFactor>[];
        if (attached) {
          fats.addAll(await _catalog.cookingFatIds());
          final found = await _catalog.foodsByIds(keys);
          final all = <String, CatalogFood>{
            for (final variants in found.values)
              for (final f in variants) f.id: f,
          };
          final groups = {for (final f in all.values) ?f.yieldGroup};
          for (final group in groups) {
            for (final f in await _catalog.foodsInYieldGroup(group)) {
              all[f.id] = f;
            }
          }
          for (final f in all.values) {
            catalog[f.id] = _proposalFood(f);
          }
          // Dish IDs address their default variant; keep every concrete
          // variant available to subsequent offline substitutions.
          for (final e in found.entries) {
            if (!catalog.containsKey(e.key) && e.value.isNotEmpty) {
              final f = e.value.where((f) => f.isDefaultVariant).firstOrNull;
              if (f != null) aliases[e.key] = f.id;
            }
          }
          yields.addAll(await _catalog.yieldFactors());
        }
        final reads = DiaryReads(_db);
        // Only today/yesterday are resolved by v1; explicit later date edits
        // receive refreshed confirmed totals from the application context.
        final today = referenceTime.localDate;
        // Today, yesterday, and any other day a day hint names (B09 D8), so
        // a card for that day previews that day's confirmed intake.
        final named = {
          ...days,
          for (final hint in _dayHints(interpretation))
            ?DayHint.resolve(hint, today),
        }..removeWhere((d) => d == today || d == today.plusDays(-1));
        final totals = [
          ...await reads.dailyTotals(today.plusDays(-1), today),
          for (final day in named) ...await reads.dailyTotals(day, day),
        ];
        final context = ProposalContext(
          referenceTime: referenceTime,
          slots: await reads.slots(),
          yields: yields,
          mode: mode,
          normalize: normalizeKey,
          dayContext: ProposalDayContext(
            today: referenceTime.localDate,
            revision: confirmedRevision,
            confirmed: {
              referenceTime.localDate: Nutrients.zero,
              referenceTime.localDate.plusDays(-1): Nutrients.zero,
              for (final day in named) day: Nutrients.zero,
              for (final t in totals) t.date: t.totals,
            },
          ),
        );
        return build(
          ProposalFacts(
            personal: personal,
            catalog: catalog,
            catalogAliases: aliases,
            packAvailable: attached,
            cookingFatIds: fats,
          ),
          context,
          config,
          json,
        );
      });
    } on Exception {
      // Parser/SQL/row exceptions can contain user values or paths. They never
      // escape this adapter and no diagnostic callback receives their content.
      return const ProposalResult.failure(ProposalIssue.invalidInput);
    }
  }

  @override
  String toString() => 'ProposalInputLoader(redacted)';
}

/// The `dateHint`s of [interpretation]'s intents (bounded by the caller's
/// traversal above; malformed shapes yield nothing).
Iterable<String> _dayHints(Map<String, Object?> interpretation) sync* {
  final intents = interpretation['intents'];
  if (intents is! List<Object?>) return;
  for (final intent in intents.take(ProposalPolicyConstants.maxIntents)) {
    if (intent is Map<String, Object?> && intent['dateHint'] is String) {
      yield intent['dateHint']! as String;
    }
  }
}

final class _LoadFailure implements Exception {
  const new();
}

ProposalFood _proposalFood(CatalogFood f) => ProposalFood(
  key: f.id,
  names: FoodNames(f.nameEn, ar: f.nameAr),
  state: f.state,
  source: f.badge == CatalogBadge.reference ? .reference : .database,
  per100: f.nutrients,
  basis: f.basis,
  origin: .localCatalog,
  version: '${f.packVersion}',
  density: f.densityGramsPerMl,
  yieldGroup: f.yieldGroup,
  range: f.nutrientsLow == null
      ? null
      : ProposalRange(f.nutrientsLow!, f.nutrientsHigh!),
  servings: [
    for (final s in f.servingUnits)
      ProposalServing(
        s.code,
        s.amount,
        s.basis,
        f.servingRanges[s.code]?.$1,
        f.servingRanges[s.code]?.$2,
      ),
  ],
);
