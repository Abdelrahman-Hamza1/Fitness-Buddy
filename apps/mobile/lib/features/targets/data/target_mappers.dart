import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/target_tables.dart';

/// The row ID of the one profile row (TD-070).
String get profileRowId => naturalId(profileEntity, 'self');

/// The SQL column of wire field [field] (`basisWeightKg` → `basis_weight_kg`).
/// The tables mirror `TargetWireFields` 1:1 (A13 D2, PA8).
String columnOfWireField(String field) =>
    field.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// The wire map of [row]: [fields] read from its columns, unchanged.
Map<String, Object?> wireOfRow(Insertable<Object?> row, List<String> fields) {
  final columns = row.toColumns(false);
  return {
    for (final field in fields)
      field: switch (columns[columnOfWireField(field)]) {
        Variable(:final value) => value,
        _ => null,
      },
  };
}

/// [row]'s profile, or null when the wire rules reject it (a synced row
/// this version can't read; skipped, never thrown or logged).
ProfileRecord? profileOf(ProfileRow row) =>
    ProfileRecord.fromWire(wireOfRow(row, TargetWireFields.profile));

/// [row]'s goal phase, or null when it can't be read.
GoalPhaseRecord? goalPhaseOf(GoalPhaseRow row) => GoalPhaseRecord.fromWire(
  row.id,
  wireOfRow(row, TargetWireFields.goalPhase),
);

/// [row]'s settings version, or null when it can't be read. A shift weight
/// the wire rules reject (negative, non-finite) reads as NULL (1.0) instead
/// of losing the whole version; a wire-valid one the engine can't use is
/// kept and also reads as 1.0 (`TargetSettingsRecord.weights`).
TargetSettingsRecord? targetSettingsOf(TargetSettingsRow row) {
  final wire = wireOfRow(row, TargetWireFields.targetSettings);
  for (final field in TargetWireFields.shifts.values) {
    final weight = wire[field] as double?;
    // The wire's technical bound for a weight (0 … TargetLimits.maxNumber).
    if (weight != null &&
        !(weight.isFinite && weight >= 0 && weight <= TargetLimits.maxNumber)) {
      wire[field] = null;
    }
  }
  return TargetSettingsRecord.fromWire(row.id, wire);
}

/// The content columns of [record] for the profile row.
ProfilesCompanion profileColumns(ProfileRecord record) => ProfilesCompanion(
  id: Value(profileRowId),
  sex: Value(record.sex.name),
  birthYear: Value(record.birthYear),
  heightCm: Value(record.heightCm),
  heightInputUnit: Value(record.heightInputUnit.code),
  activity: Value(record.activity.name),
);

/// The content columns (with `id`) of [record].
GoalPhasesCompanion goalPhaseColumns(GoalPhaseRecord record) {
  final w = record.toWire();
  return GoalPhasesCompanion(
    id: Value(record.id),
    revision: Value(record.revision),
    name: Value(record.name),
    startDate: Value(w['startDate']! as String),
    endDate: Value(w['endDate'] as String?),
    goalType: Value(record.type.name),
    expressionKind: Value(w['expressionKind']! as String),
    targetKg: Value(w['targetKg'] as double?),
    targetDate: Value(w['targetDate'] as String?),
    kgPerWeek: Value(w['kgPerWeek'] as double?),
    monthKg: Value(w['monthKg'] as double?),
    month: Value(w['month'] as String?),
    weightInputUnit: Value(record.weightInputUnit.code),
  );
}

/// The content columns (with `id`) of [record].
TargetSettingsRowsCompanion targetSettingsColumns(TargetSettingsRecord record) {
  final w = record.toWire();
  double? real(String field) => w[field] as double?;
  bool? flag(String field) => w[field] as bool?;
  return TargetSettingsRowsCompanion(
    id: Value(record.id),
    revision: Value(record.revision),
    effectiveFrom: Value('${record.effectiveFrom}'),
    mode: Value(record.mode.name),
    rebalancing: Value(record.rebalancing),
    baseKcal: Value(record.baseKcal),
    manual: Value(record.manual),
    acknowledged: Value(record.acknowledged),
    basisWeightKg: Value(record.basisWeightKg),
    shiftMon: Value(real('shiftMon')),
    shiftTue: Value(real('shiftTue')),
    shiftWed: Value(real('shiftWed')),
    shiftThu: Value(real('shiftThu')),
    shiftFri: Value(real('shiftFri')),
    shiftSat: Value(real('shiftSat')),
    shiftSun: Value(real('shiftSun')),
    proteinValue: Value(real('proteinValue')),
    proteinIsPercent: Value(flag('proteinIsPercent')),
    fatValue: Value(real('fatValue')),
    fatIsPercent: Value(flag('fatIsPercent')),
    carbsValue: Value(real('carbsValue')),
    carbsIsPercent: Value(flag('carbsIsPercent')),
    fiberG: Value(real('fiberG')),
    caloriesProteinOnly: Value(record.macros.caloriesProteinOnly),
  );
}
