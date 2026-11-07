import 'package:fb_domain/src/body/measurement.dart';
import 'package:fb_domain/src/body/measurement_ops.dart';
import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/body/weigh_in_batch.dart';
import 'package:fb_domain/src/body/weigh_in_ops.dart';
import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/proposals/day_hint.dart';
import 'package:fb_domain/src/proposals/proposal_input.dart'
    show ProposalIdSource;
import 'package:fb_domain/src/records/record_plan.dart';
import 'package:fb_domain/src/records/record_request.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/units/units.dart';

/// A measurement card's figures (A69 D4).
final class MeasurementView {
  /// The figures.
  const new({required this.draft, this.previous});

  /// The measurement.
  final MeasurementDraft draft;

  /// The latest earlier value of that type (canonical: cm or %).
  final double? previous;

  /// The change against [previous], canonical.
  double? get delta => previous == null ? null : draft.value - previous!;

  @override
  String toString() => 'MeasurementView';
}

/// Why an import row is flagged (A69 D5, WB-031). Codes only.
enum ImportFlag {
  /// No date could be read: blocked.
  unclearDate,

  /// No number: blocked.
  noValue,

  /// The unit can't be a weight or that measurement: blocked.
  unknownUnit,

  /// Out of the allowed range: blocked.
  outOfRange,

  /// Dated after today: blocked.
  future,

  /// "110k" read as kg: excluded until accepted.
  unitInferred,

  /// No unit written; the profile's unit was used: excluded until accepted.
  unitMissing,

  /// The same value is already stored that day (or an earlier row has it):
  /// excluded until accepted.
  duplicate,

  /// An implausible jump or a likely unit mix-up: excluded until accepted.
  implausible,

  /// Another value is stored that day (informational).
  sameDay,
}

/// The flags that block a row (it can't be accepted).
const Set<ImportFlag> blockingImportFlags = {
  ImportFlag.unclearDate,
  ImportFlag.noValue,
  ImportFlag.unknownUnit,
  ImportFlag.outOfRange,
  ImportFlag.future,
};

/// The flags that exclude a row until the user accepts it.
const Set<ImportFlag> excludingImportFlags = {
  ImportFlag.unitInferred,
  ImportFlag.unitMissing,
  ImportFlag.duplicate,
  ImportFlag.implausible,
};

/// One row of the import review table.
final class ImportRowView {
  /// The row.
  const new({
    required this.index,
    required this.original,
    required this.flags,
    required this.included,
    required this.accepted,
    this.date,
    this.value,
    this.unit,
  });

  /// Its position in the pasted text.
  final int index;

  /// The literal text. User content.
  final String original;

  /// The day, when readable.
  final LocalDate? date;

  /// The number as read.
  final double? value;

  /// The unit it was read in (`kg`, `lb`, `cm`, `in`, `percent`).
  final String? unit;

  /// Its flags.
  final Set<ImportFlag> flags;

  /// Whether the confirm imports it.
  final bool included;

  /// Whether the user accepted its flags.
  final bool accepted;

  /// Whether a flag blocks it.
  bool get blocked => flags.any(blockingImportFlags.contains);

  /// Whether the user can include it by accepting.
  bool get canAccept => !blocked && flags.any(excludingImportFlags.contains);

  @override
  String toString() => 'ImportRowView($index)';
}

/// The import review table (WB-031).
final class ImportView {
  /// The table.
  const new({required this.rows, this.measurementKind});

  /// `null` for weights, else the measurement kind.
  final MeasurementKind? measurementKind;

  /// The rows, in pasted order.
  final List<ImportRowView> rows;

  /// How many rows the confirm imports.
  int get includedCount => rows.where((r) => r.included).length;

  @override
  String toString() => 'ImportView(${rows.length})';
}

LocalDate? _day(String? hint, RecordFacts f) =>
    hint == null ? f.now.localDate : DayHint.resolve(hint, f.now.localDate);

/// The time a past body value gets: 08:00 local (as the weight history),
/// today the message's time.
EntryTime _timeOn(LocalDate date, RecordFacts f) => date == f.now.localDate
    ? f.now
    : EntryTime.local(LocalTime(8).on(date), f.now.tzOffsetMin);

/// Plans a measurement card (A69 D4).
RecordPlan planMeasurement(
  MeasurementRecord r,
  RecordFacts f,
  ProposalIdSource ids,
) {
  final kind = MeasurementKind.fromCode(r.kindCode);
  final unit = MeasurementUnit.fromCode(r.unit);
  if (kind == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
  if (unit == null || unit.isLength != kind.isLength) {
    return RecordPlan.failed(r.kind, RecordIssue.unsupportedUnit);
  }
  final MeasurementTypeRef type;
  if (kind == MeasurementKind.custom) {
    final id = r.customTypeId;
    if (id == null || !f.customMeasurementTypes.contains(id)) {
      return RecordPlan.failed(r.kind, RecordIssue.notFound);
    }
    type = MeasurementTypeRef.custom(id);
  } else {
    type = MeasurementTypeRef.builtIn(kind);
  }
  final date = _day(r.when.dateHint, f);
  if (date == null || date.isAfter(f.now.localDate)) {
    return RecordPlan.failed(r.kind, RecordIssue.invalid);
  }
  final draft = MeasurementDraft(
    type: type,
    time: date == f.now.localDate ? f.now : f.now.onDate(date),
    input: MeasurementInput(r.value, unit),
  );
  if (draft.validate() != null) {
    return RecordPlan.failed(r.kind, RecordIssue.invalid);
  }
  final earlier = [
    for (final m in f.measurements)
      if (m.type == type && !m.localDate.isAfter(date)) m,
  ]..sort((a, b) => a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc));
  return RecordPlan(
    RecordView(
      kind: r.kind,
      date: date,
      notes: {if (r.when.timeHint != null) RecordNote.timeIgnored},
      measurement: MeasurementView(
        draft: draft,
        previous: earlier.isEmpty ? null : earlier.last.value,
      ),
    ),
    [CreateMeasurement(ids.next(), draft)],
  );
}

/// The unit [written] means for a weight: the unit, and whether it was
/// inferred ("110k"); `null` unit = not a weight unit.
(MassUnit?, ImportFlag?) _massUnit(String? written, MassUnit fallback) {
  final w = written?.trim().toLowerCase().replaceAll('.', '');
  if (w == null || w.isEmpty) return (fallback, ImportFlag.unitMissing);
  return switch (w) {
    'kg' ||
    'kgs' ||
    'kilogram' ||
    'kilograms' ||
    'كغ' ||
    'كجم' => (MassUnit.kilogram, null),
    'k' ||
    'kilo' ||
    'kilos' ||
    'كيلو' ||
    'ك' => (MassUnit.kilogram, ImportFlag.unitInferred),
    'lb' || 'lbs' || 'pound' || 'pounds' => (MassUnit.pound, null),
    _ => (null, ImportFlag.unknownUnit),
  };
}

/// The unit [written] means for measurement [kind].
(MeasurementUnit?, ImportFlag?) _lengthUnit(
  String? written,
  MeasurementKind kind,
  MeasurementUnit fallback,
) {
  final w = written?.trim().toLowerCase().replaceAll('.', '');
  if (!kind.isLength) {
    return w == null || w.isEmpty || w == '%' || w == 'percent'
        ? (MeasurementUnit.percent, null)
        : (null, ImportFlag.unknownUnit);
  }
  if (w == null || w.isEmpty) return (fallback, ImportFlag.unitMissing);
  return switch (w) {
    'cm' || 'سم' => (MeasurementUnit.cm, null),
    'in' || 'inch' || 'inches' || '"' || "''" => (MeasurementUnit.inch, null),
    _ => (null, ImportFlag.unknownUnit),
  };
}

/// Plans an import review table (A69 D5): what each row is, its flags,
/// and one create per included row.
RecordPlan planImport(
  ImportRowsRecord r,
  RecordFacts f,
  ProposalIdSource ids,
  RecordAdjust adjust,
) {
  if (r.rows.isEmpty) return RecordPlan.failed(r.kind, RecordIssue.invalid);
  final planned = r.isWeight
      ? _weights(r, f, ids, adjust)
      : _measurements(r, f, ids, adjust);
  if (planned == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
  final (views, ops) = planned;
  return RecordPlan(
    RecordView(
      kind: r.kind,
      imports: ImportView(
        rows: views,
        measurementKind: r.isWeight
            ? null
            : MeasurementKind.fromCode(r.measurementKind!),
      ),
    ),
    ops,
  );
}

(List<ImportRowView>, List<ChangeOp>) _weights(
  ImportRowsRecord r,
  RecordFacts f,
  ProposalIdSource ids,
  RecordAdjust adjust,
) {
  final today = f.now.localDate;
  final read = [
    for (final row in r.rows)
      (
        date: row.date == null ? null : LocalDate.tryParse(row.date!),
        value: row.value,
        unit: _massUnit(row.unit, f.massUnit),
      ),
  ];
  // Each row's own flags (date, value, unit).
  Set<ImportFlag> own(int i) => {
    if (read[i].date == null) ImportFlag.unclearDate,
    if (read[i].value == null) ImportFlag.noValue,
    ?read[i].unit.$2,
  };
  bool held(int i) =>
      own(i).any(blockingImportFlags.contains) ||
      (own(i).any(excludingImportFlags.contains) &&
          !adjust.accepted.contains(i));
  // The batch check over the rows that can count (held rows are passed
  // without a value, so they're never a reference); Keeps follow the
  // user's accepts, settled in at most three passes.
  var keeps = <int, WeighInKeep>{};
  late WeighInBatchResult result;
  for (var pass = 0; pass < 3; pass++) {
    result = WeighInBatchCheck.check(
      rows: [
        for (final (i, row) in read.indexed)
          WeighInBatchRow(
            unit: row.unit.$1 ?? MassUnit.kilogram,
            date: row.date,
            value: held(i) ? null : row.value,
            keep: keeps[i],
          ),
      ],
      existing: f.weighIns,
      today: today,
      timeFor: (d) => _timeOn(d, f),
    );
    final next = {
      for (final row in result.rows)
        if (row.keepToken case final token?
            when adjust.accepted.contains(row.index))
          row.index: token,
    };
    if (_sameKeeps(next, keeps)) break;
    keeps = next;
  }
  final byIndex = {for (final row in result.rows) row.index: row};
  final views = <ImportRowView>[];
  final included = <WeighInDraft>[];
  for (final (i, row) in read.indexed) {
    final checked = byIndex[i];
    final flags = {
      ...own(i),
      if (!held(i))
        for (final flag in checked?.flags ?? const <WeighInRowFlag>[])
          switch (flag) {
            WeighInRowFlag.incomplete => ImportFlag.noValue,
            WeighInRowFlag.outOfRange => ImportFlag.outOfRange,
            WeighInRowFlag.future => ImportFlag.future,
            WeighInRowFlag.duplicate => ImportFlag.duplicate,
            WeighInRowFlag.implausible => ImportFlag.implausible,
            WeighInRowFlag.sameDay => ImportFlag.sameDay,
          },
    };
    final isIncluded = !held(i) && (checked?.included ?? false);
    if (isIncluded) included.add(checked!.draft!);
    views.add(
      ImportRowView(
        index: i,
        original: r.rows[i].original,
        date: row.date,
        value: row.value,
        unit: row.unit.$1?.code,
        flags: flags,
        included: isIncluded,
        accepted: adjust.accepted.contains(i),
      ),
    );
  }
  return (
    views,
    included.isEmpty
        ? const <ChangeOp>[]
        : <ChangeOp>[for (final d in included) CreateWeighIn(ids.next(), d)],
  );
}

bool _sameKeeps(Map<int, WeighInKeep> a, Map<int, WeighInKeep> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// Most a measurement may move within [_jumpDays] before it is flagged.
const double _jumpShare = 0.15;
const double _jumpPercentPoints = 5;
const int _jumpDays = 14;
const double _sameValue = 0.1;

(List<ImportRowView>, List<ChangeOp>)? _measurements(
  ImportRowsRecord r,
  RecordFacts f,
  ProposalIdSource ids,
  RecordAdjust adjust,
) {
  final kind = MeasurementKind.fromCode(r.measurementKind ?? '');
  if (kind == null || kind == MeasurementKind.custom) return null;
  final type = MeasurementTypeRef.builtIn(kind);
  final today = f.now.localDate;
  final stored = [
    for (final m in f.measurements)
      if (m.type == type) (date: m.localDate, value: m.value),
  ];
  final order = [for (var i = 0; i < r.rows.length; i++) i];
  final dates = [
    for (final row in r.rows)
      if (row.date == null) null else LocalDate.tryParse(row.date!),
  ];
  order.sort((a, b) {
    final da = dates[a];
    final db = dates[b];
    if (da == null || db == null) return a.compareTo(b);
    final byDate = da.compareTo(db);
    return byDate != 0 ? byDate : a.compareTo(b);
  });
  final earlier = <({LocalDate date, double value})>[];
  final views = <int, ImportRowView>{};
  final drafts = <MeasurementDraft>[];
  for (final i in order) {
    final row = r.rows[i];
    final date = dates[i];
    final (unit, unitFlag) = _lengthUnit(row.unit, kind, f.lengthUnit);
    final flags = <ImportFlag>{
      if (date == null) ImportFlag.unclearDate,
      if (row.value == null) ImportFlag.noValue,
      ?unitFlag,
    };
    MeasurementDraft? draft;
    if (flags.every((x) => !blockingImportFlags.contains(x))) {
      draft = MeasurementDraft(
        type: type,
        time: _timeOn(date!, f),
        input: MeasurementInput(row.value!, unit!),
      );
      if (draft.validate() != null) flags.add(ImportFlag.outOfRange);
      if (date.isAfter(today)) flags.add(ImportFlag.future);
    }
    if (draft != null && !flags.any(blockingImportFlags.contains)) {
      final v = draft.value;
      final sameDay = [
        for (final m in [...stored, ...earlier])
          if (m.date == date) m,
      ];
      if (sameDay.any((m) => (m.value - v).abs() <= _sameValue + 1e-9)) {
        flags.add(ImportFlag.duplicate);
      } else if (sameDay.isNotEmpty) {
        flags.add(ImportFlag.sameDay);
      }
      final before = [
        for (final m in [...stored, ...earlier])
          if (!m.date.isAfter(date!) && m.date.daysUntil(date) <= _jumpDays) m,
      ]..sort((a, b) => a.date.compareTo(b.date));
      if (before.isNotEmpty && !flags.contains(ImportFlag.duplicate)) {
        final ref = before.last.value;
        final jump = kind.isLength
            ? (v - ref).abs() > ref * _jumpShare
            : (v - ref).abs() > _jumpPercentPoints;
        if (jump) flags.add(ImportFlag.implausible);
      }
    }
    final accepted = adjust.accepted.contains(i);
    final included =
        draft != null &&
        !flags.any(blockingImportFlags.contains) &&
        (accepted || !flags.any(excludingImportFlags.contains));
    if (included) {
      drafts.add(draft);
      earlier.add((date: date!, value: draft.value));
    }
    views[i] = ImportRowView(
      index: i,
      original: row.original,
      date: date,
      value: row.value,
      unit: unit?.code,
      flags: flags,
      included: included,
      accepted: accepted,
    );
  }
  return (
    [for (var i = 0; i < r.rows.length; i++) views[i]!],
    drafts.isEmpty
        ? const <ChangeOp>[]
        : <ChangeOp>[for (final d in drafts) CreateMeasurement(ids.next(), d)],
  );
}
