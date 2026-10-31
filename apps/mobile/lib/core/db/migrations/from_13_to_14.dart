import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';
import 'package:fb_mobile/core/db/write_guard.dart';

/// Schema v13 → v14 (A53 D2, D-090, TD-112): data only. The `shift_*`
/// columns of `target_settings` change meaning from weekday **weights**
/// (a larger share of the same weekly budget) to weekday **factors** of the
/// daily suggestion. Every live row with a weight is rewritten so each
/// day's number stays what the old engine planned:
/// factor = planned ÷ the base the plan used (raised to the floor).
///
/// The old allocation is copied here (frozen): weekly mode spread
/// `base × 7` by weight within ±25 % of the base and above the floor (the
/// floor from the stored profile at the row's basis weight on its
/// effective date; no profile → no floor). Fixed mode ignored weights, so
/// a fixed row's weights are cleared. A factor of 1 is stored as NULL.
///
/// A rewritten row gets a later HLC (counter + 1, same device) and the
/// next `version`, so the outbox trigger captures it and sync pushes the
/// converted values.
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`).
Future<void> from13To14(Migrator m, Schema14 schema) =>
    runAuthorizedWrite(() async {
      final db = m.database;
      final profile = await _profile(db);
      final rows = await db
          .customSelect(
            'SELECT id, updated_hlc, version, effective_from, mode, base_kcal, '
            'manual, acknowledged, basis_weight_kg, ${_columns.join(', ')} '
            'FROM target_settings WHERE deleted_at IS NULL AND '
            '(${_columns.map((c) => '$c IS NOT NULL').join(' OR ')})',
          )
          .get();
      String? latest;
      for (final row in rows) {
        final factors = v13Factors(
          weights: [for (final c in _columns) row.read<double?>(c)],
          baseKcal: row.read<double>('base_kcal'),
          fixed: row.read<String>('mode') == 'fixed',
          manualAcknowledged:
              row.read<bool>('manual') && row.read<bool>('acknowledged'),
          floorKcal: _floor(
            profile,
            row.read<double>('basis_weight_kg'),
            LocalDate.tryParse(row.read<String>('effective_from')),
          ),
        );
        final hlc = _next(row.read<String>('updated_hlc'));
        if (hlc == null) continue;
        if (latest == null || hlc.compareTo(latest) > 0) latest = hlc;
        await db.customUpdate(
          'UPDATE target_settings SET '
          '${[for (final c in _columns) '$c = ?'].join(', ')}, '
          'updated_hlc = ?, version = version + 1 WHERE id = ?',
          variables: [
            for (final f in factors) Variable<double>(f),
            Variable<String>(hlc),
            Variable<String>(row.read<String>('id')),
          ],
          updates: {schema.targetSettings},
        );
      }
      // The clock continues after the HLCs given here, so a later local
      // write never reuses one (the outbox trigger needs a changed HLC).
      if (latest != null) {
        await db.customStatement(
          "INSERT INTO sync_state (key, value) VALUES ('hlc.last', ?) "
          'ON CONFLICT (key) DO UPDATE SET value = excluded.value '
          'WHERE excluded.value > sync_state.value',
          [latest],
        );
      }
      // Server history older than this still holds v13 weights; restoring
      // such a version converts it (core/sync/legacy_target_factors.dart).
      await db.customStatement(
        "INSERT INTO sync_state (key, value) VALUES ('$dayFactorsSinceKey', ?) "
        'ON CONFLICT (key) DO NOTHING',
        ['${DateTime.now().toUtc().millisecondsSinceEpoch}'],
      );
    });

/// The `sync_state` key holding when this install started storing factors
/// (UTC ms).
const String dayFactorsSinceKey = 'targets.dayFactorsSinceMs';

/// The weekday columns, Monday first (the `DayOfWeek` order).
const List<String> _columns = [
  'shift_mon',
  'shift_tue',
  'shift_wed',
  'shift_thu',
  'shift_fri',
  'shift_sat',
  'shift_sun',
];

/// The v13 engine's planned days as v14 factors (NULL = the suggestion),
/// Monday first. [weights] are the stored v13 weights (NULL, or outside
/// 0.001–1000, = 1.0); [floorKcal] null when unknown.
List<double?> v13Factors({
  required List<double?> weights,
  required double baseKcal,
  required bool fixed,
  required bool manualAcknowledged,
  double? floorKcal,
}) {
  if (fixed) return List.filled(7, null);
  final floor = floorKcal ?? 0;
  // v13 `toPlan`: a base below the floor is raised to it (a below-floor
  // base may only stay when acknowledged manual fixed, handled above).
  final base = baseKcal < floor && !manualAcknowledged ? floor : baseKcal;
  final w = [
    for (final weight in weights)
      if (weight == null || !weight.isFinite || weight < .001 || weight > 1000)
        1.0
      else
        weight,
  ];
  final planned = _v13Allocate(
    base * 7,
    w,
    math.max(floor, base * .75),
    base * 1.25,
  );
  return [
    for (final kcal in planned)
      if ((kcal / base - 1).abs() < 1e-9) null else kcal / base,
  ];
}

// The v13 `WeeklyBudget._allocate`, unchanged.
List<double> _v13Allocate(
  double budget,
  List<double> weights,
  double lower,
  double upper,
) {
  final feasible = budget.clamp(lower * weights.length, upper * weights.length);
  final maxWeight = weights.reduce(math.max);
  final normalized = [for (final w in weights) w / maxWeight];
  var lo = 0.0;
  var hi = upper / normalized.reduce(math.min);
  for (var i = 0; i < 80; i++) {
    final multiplier = (lo + hi) / 2;
    final total = normalized.fold<double>(
      0,
      (sum, w) => sum + (multiplier * w).clamp(lower, upper),
    );
    if (total < feasible) {
      lo = multiplier;
    } else {
      hi = multiplier;
    }
  }
  return [for (final w in normalized) ((lo + hi) / 2 * w).clamp(lower, upper)];
}

Future<ProfileRecord?> _profile(DatabaseConnectionUser db) async {
  final row = await db
      .customSelect(
        'SELECT sex, birth_year, height_cm, height_input_unit, activity '
        'FROM profile WHERE deleted_at IS NULL LIMIT 1',
      )
      .getSingleOrNull();
  if (row == null) return null;
  return ProfileRecord.fromWire({
    'sex': row.read<String>('sex'),
    'birthYear': row.read<int>('birth_year'),
    'heightCm': row.read<double>('height_cm'),
    'heightInputUnit': row.read<String>('height_input_unit'),
    'activity': row.read<String>('activity'),
  });
}

double? _floor(ProfileRecord? profile, double weightKg, LocalDate? date) {
  if (profile == null || date == null) return null;
  try {
    return TargetCalculator.floor(profile.toProfile(weightKg), date);
  }
  // An implausible stored value: convert without a floor.
  // ignore: avoid_catching_errors
  on ArgumentError {
    return null;
  }
}

/// [hlc] one counter step later (same wall time and device), or null when
/// it can't be read.
String? _next(String hlc) {
  final parsed = Hlc.tryParse(hlc);
  if (parsed == null) return null;
  final next = parsed.counter < Hlc.maxCounter
      ? Hlc(
          wallMs: parsed.wallMs,
          counter: parsed.counter + 1,
          deviceId: parsed.deviceId,
        )
      : Hlc(wallMs: parsed.wallMs + 1, counter: 0, deviceId: parsed.deviceId);
  return '$next';
}
