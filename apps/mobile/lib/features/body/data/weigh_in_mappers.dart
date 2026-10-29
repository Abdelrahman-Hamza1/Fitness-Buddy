import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// A stored row the domain can't read (corrupt, or from an incompatible
/// client). Never echoes the row.
final class WeighInMappingError implements Exception {
  /// A fixed, content-free failure.
  const new();

  @override
  String toString() => 'WeighInMappingError';
}

/// The domain weigh-in of [row]. Throws [WeighInMappingError] for a row it
/// can't read (an unknown unit, a malformed date, or a kg or typed value
/// outside the read bound [WeighInBounds.isReadableKg]; all possible only
/// via sync).
WeighIn weighInOf(WeighInRow row) {
  final unit = MassUnit.fromCode(row.inputUnit);
  if (unit == null || !WeighInInput.units.contains(unit)) {
    throw const WeighInMappingError();
  }
  if (!WeighInBounds.isReadableKg(row.kg) ||
      !WeighInBounds.isReadableKg(row.inputValue * unit.grams / 1000)) {
    throw const WeighInMappingError();
  }
  try {
    return WeighIn(
      id: row.id,
      version: row.version,
      time: EntryTime(
        DateTime.fromMillisecondsSinceEpoch(row.measuredAtUtc, isUtc: true),
        row.tzOffsetMin,
      ),
      localDate: LocalDate.parse(row.localDate),
      kg: row.kg,
      input: WeighInInput(row.inputValue, unit),
      note: row.note,
      preferredForDay: row.preferredForDay,
    );
  } on Object {
    // ArgumentError / FormatException carry the stored text: drop them.
    throw const WeighInMappingError();
  }
}

/// The content columns of [draft] (A14 D6): kg rounded once, the input as
/// typed, the local date from the draft's own offset. Leaves
/// `preferred_for_day` alone; the handler sets it.
WeighInsCompanion weighInColumns(WeighInDraft draft) => WeighInsCompanion(
  measuredAtUtc: Value(draft.time.occurredAtUtc.millisecondsSinceEpoch),
  tzOffsetMin: Value(draft.time.tzOffsetMin),
  localDate: Value(draft.localDate.toString()),
  kg: Value(draft.kg),
  inputValue: Value(draft.input.value),
  inputUnit: Value(draft.input.unit.code),
  note: Value(draft.note),
);
