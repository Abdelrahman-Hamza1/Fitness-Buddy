import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// A stored measurement or type the domain can't read (corrupt, or a synced
/// row that breaks the wire rules). Never echoes the row.
final class MeasurementMappingError implements Exception {
  /// A fixed, content-free failure.
  const new();

  @override
  String toString() => 'MeasurementMappingError';
}

/// The domain measurement of [row] (A15b D25). Throws
/// [MeasurementMappingError] for an unknown kind or unit, a wire-rule
/// mismatch (M1 custom type, M2 unit fits kind, M3 percent ≤ 100), a value
/// that isn't finite or is ≤ 0 or above 1e6, a malformed date or ID, or a
/// measured time whose wall clock is outside the years 1–9999; all possible
/// only via sync.
Measurement measurementOf(MeasurementRow row) {
  final kind = MeasurementKind.fromCode(row.kind);
  final unit = MeasurementUnit.fromCode(row.inputUnit);
  if (kind == null || unit == null) throw const MeasurementMappingError();
  final isCustom = kind == MeasurementKind.custom;
  // M1, M2.
  if (isCustom != (row.customTypeId != null) ||
      unit.isLength != kind.isLength) {
    throw const MeasurementMappingError();
  }
  if (!_readable(row.value) || !_readable(row.inputValue)) {
    throw const MeasurementMappingError();
  }
  // M3.
  if (!kind.isLength && (row.value > 100 || row.inputValue > 100)) {
    throw const MeasurementMappingError();
  }
  try {
    // The wall clock must be representable (years 1–9999): a synced
    // instant inside the wire bound can still fall outside it, and the
    // graph reads it (A15b review M1).
    final time = EntryTime(
      DateTime.fromMillisecondsSinceEpoch(row.measuredAtUtc, isUtc: true),
      row.tzOffsetMin,
    )..localDateTime;
    return Measurement(
      id: row.id,
      version: row.version,
      type: MeasurementTypeRef(kind: kind, customTypeId: row.customTypeId),
      time: time,
      localDate: LocalDate.parse(row.localDate),
      value: row.value,
      input: MeasurementInput(row.inputValue, unit),
    );
  } on Object {
    // ArgumentError / FormatException carry the stored text: drop them.
    throw const MeasurementMappingError();
  }
}

/// The domain type of [row]. Throws [MeasurementMappingError] for an empty
/// trimmed name or a malformed ID.
MeasurementType measurementTypeOf(MeasurementTypeRow row) {
  if (row.name.trim().isEmpty) throw const MeasurementMappingError();
  try {
    return MeasurementType(id: row.id, version: row.version, name: row.name);
  } on Object {
    throw const MeasurementMappingError();
  }
}

bool _readable(double value) =>
    value.isFinite && value > 0 && value <= MeasurementBounds.readMax;

/// The content columns of [draft] (A15b D13): the canonical value rounded
/// once, the input as typed, the local date from the draft's own offset.
MeasurementsCompanion measurementColumns(MeasurementDraft draft) =>
    MeasurementsCompanion(
      kind: Value(draft.type.kind.code),
      customTypeId: Value(draft.type.customTypeId),
      measuredAtUtc: Value(draft.time.occurredAtUtc.millisecondsSinceEpoch),
      tzOffsetMin: Value(draft.time.tzOffsetMin),
      localDate: Value(draft.localDate.toString()),
      value: Value(draft.value),
      inputValue: Value(draft.input.value),
      inputUnit: Value(draft.input.unit.code),
    );

/// The content columns of a type named [name] (stored trimmed).
MeasurementTypesCompanion measurementTypeColumns(String name) =>
    MeasurementTypesCompanion(name: Value(CustomTypeName.normalize(name)));
