import 'package:fb_domain/fb_domain.dart';

/// One row of the weight history as typed (A15b D17).
final class WeightHistoryRow {
  const new _({
    required this.key,
    required this.unit,
    this.date,
    this.text = '',
    this.keep,
  });

  /// A stable identity for the row's widgets (its text field).
  final int key;

  /// The day, or `null` until picked.
  final LocalDate? date;

  /// The value as typed (digits with `.`, `,` or the Arabic decimal mark).
  /// User content.
  final String text;

  /// The unit the value means.
  final MassUnit unit;

  /// The Keep the user gave this row's flag, or `null`.
  final WeighInKeep? keep;

  /// The typed number, or `null` while empty or not a number.
  double? get value => parseWeightHistoryNumber(text);

  /// Whether anything was typed or picked.
  bool get isTouched => date != null || text.trim().isNotEmpty;

  /// The row for [WeighInBatchCheck].
  WeighInBatchRow get batchRow =>
      WeighInBatchRow(unit: unit, date: date, value: value, keep: keep);

  WeightHistoryRow _editedIf(
    int key,
    WeightHistoryRow Function(WeightHistoryRow row) change,
  ) => this.key == key ? change(this) : this;

  WeightHistoryRow _inUnit(MassUnit unit) =>
      this.unit == unit ? this : _copy(unit: unit);

  WeightHistoryRow _copy({
    LocalDate? date,
    String? text,
    MassUnit? unit,
    WeighInKeep? keep,
  }) => WeightHistoryRow._(
    key: key,
    date: date ?? this.date,
    text: text ?? this.text,
    unit: unit ?? this.unit,
    keep: keep,
  );

  /// Never the value.
  @override
  String toString() => 'WeightHistoryRow($key, $date, ${unit.code})';
}

/// The weight history form (WB-001, WB-005, WB-031, A15b D17): the rows,
/// their units and Keeps. Immutable and pure: every edit returns a new
/// state; "today" comes in as a parameter. The checks are
/// [WeighInBatchCheck]'s.
///
/// Editing a row's date, value or unit clears its Keep (the check's Keep
/// token also changes when what it was checked against changes).
final class WeightHistoryForm {
  const new _({required this.unit, required this.rows, required this.nextKey});

  /// One empty row in [unit] (the unit setting's body unit).
  factory start(MassUnit unit) => WeightHistoryForm._(
    unit: unit,
    rows: [WeightHistoryRow._(key: 0, unit: unit)],
    nextKey: 1,
  );

  /// The unit of new rows (the unit chips).
  final MassUnit unit;

  /// The rows, in the order shown. Never empty.
  final List<WeightHistoryRow> rows;

  /// The key the next new row gets.
  final int nextKey;

  /// Whether leaving would lose something typed (UX-052).
  bool get isDirty => rows.any((row) => row.isTouched);

  /// Whether another row fits in one save ([WeighInBatchCheck.maxRows]).
  bool get canAddRow => rows.length < WeighInBatchCheck.maxRows;

  /// The rows for [WeighInBatchCheck].
  List<WeighInBatchRow> get batchRows => [for (final r in rows) r.batchRow];

  /// The checks of every row against the stored [existing] weigh-ins.
  WeighInBatchResult check({
    required Iterable<WeighIn> existing,
    required LocalDate today,
    required EntryTime Function(LocalDate date) timeFor,
  }) => WeighInBatchCheck.check(
    rows: batchRows,
    existing: existing,
    today: today,
    timeFor: timeFor,
  );

  /// A new row at the end, dated 7 days after the last row (at most
  /// [today]); undated when the last row has no date.
  WeightHistoryForm addRow(LocalDate today) {
    if (!canAddRow) return this;
    final date = switch (rows.last.date?.plusDays(7)) {
      final next? when next.isAfter(today) => today,
      final next => next,
    };
    return _with([
      ...rows,
      WeightHistoryRow._(key: nextKey, unit: unit, date: date),
    ], next: nextKey + 1);
  }

  /// Without row [key]; removing the only row leaves one empty row.
  WeightHistoryForm remove(int key) {
    final left = [
      for (final row in rows)
        if (row.key != key) row,
    ];
    if (left.isNotEmpty) return _with(left);
    return _with([
      WeightHistoryRow._(key: nextKey, unit: unit),
    ], next: nextKey + 1);
  }

  /// Row [key] on [date] (its Keep cleared).
  WeightHistoryForm withDate(int key, LocalDate date) =>
      _edit(key, (row) => row.date == date ? row : row._copy(date: date));

  /// Row [key] with [text] typed (its Keep cleared when the text changed).
  WeightHistoryForm withText(int key, String text) =>
      _edit(key, (row) => row.text == text ? row : row._copy(text: text));

  /// Row [key] in [unit] ("Use lb", its Keep cleared).
  WeightHistoryForm withRowUnit(int key, MassUnit unit) =>
      _edit(key, (row) => row._inUnit(unit));

  /// Every row, and new ones, in [unit] (the unit chips). The numbers are
  /// relabelled, never converted (LC-011); changed rows lose their Keep.
  WeightHistoryForm withUnit(MassUnit unit) => WeightHistoryForm._(
    unit: unit,
    rows: [for (final row in rows) row._inUnit(unit)],
    nextKey: nextKey,
  );

  /// Row [key] kept despite its flag ([WeighInRowResult.keepToken]).
  WeightHistoryForm keep(int key, WeighInKeep token) =>
      _edit(key, (row) => row._copy(keep: token));

  WeightHistoryForm _edit(
    int key,
    WeightHistoryRow Function(WeightHistoryRow row) change,
  ) => _with([for (final row in rows) row._editedIf(key, change)]);

  WeightHistoryForm _with(List<WeightHistoryRow> rows, {int? next}) =>
      WeightHistoryForm._(
        unit: unit,
        rows: List.unmodifiable(rows),
        nextKey: next ?? nextKey,
      );

  @override
  String toString() => 'WeightHistoryForm(${rows.length} rows)';
}

/// Reads a typed nonnegative number: decimal point, comma or the Arabic
/// decimal mark, Western, Arabic-Indic and Persian digits (what
/// `FbNumberField` lets through). `null` for anything else.
double? parseWeightHistoryNumber(String text) {
  var value = text.trim();
  for (var i = 0; i < 10; i++) {
    value = value
        .replaceAll(String.fromCharCode(0x660 + i), '$i')
        .replaceAll(String.fromCharCode(0x6f0 + i), '$i');
  }
  value = value.replaceAll(',', '.').replaceAll('٫', '.');
  if (!_number.hasMatch(value)) return null;
  final number = double.tryParse(value);
  return number == null || !number.isFinite ? null : number;
}

final RegExp _number = RegExp(r'^(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$');
