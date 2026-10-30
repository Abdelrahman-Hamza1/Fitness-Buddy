import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/body/weigh_in_check.dart';
import 'package:fb_domain/src/body/weigh_in_ops.dart';
import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/time/clock.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/units/units.dart';

/// One row of the multi-row weight history entry (A15b D17): a date, a
/// typed value and its unit, and the Keep the user gave a flagged row.
final class WeighInBatchRow {
  /// A row; [date] and [value] stay `null` until typed.
  const new({required this.unit, this.date, this.value, this.keep});

  /// The day it was weighed, or `null` while not picked.
  final LocalDate? date;

  /// The typed number, or `null` while empty. User content.
  final double? value;

  /// The typed unit.
  final MassUnit unit;

  /// The Keep the user accepted for an excluded row
  /// ([WeighInRowResult.keepToken]), or `null`. A Keep counts only while
  /// the row is flagged for exactly the same reason against exactly the
  /// same reference, so editing the row, or the earlier row or stored
  /// weigh-in it was checked against, clears it.
  final WeighInKeep? keep;

  @override
  bool operator ==(Object other) =>
      other is WeighInBatchRow &&
      other.date == date &&
      other.value == value &&
      other.unit == unit &&
      other.keep == keep;

  @override
  int get hashCode => Object.hash(date, value, unit, keep);

  /// Never the value.
  @override
  String toString() => 'WeighInBatchRow($date, ${unit.code})';
}

/// What [WeighInBatchCheck] found about a row (A15b D17).
enum WeighInRowFlag {
  /// Blocking: no date or no value.
  incomplete,

  /// Blocking: outside 20–500 kg after conversion, or before 1970.
  outOfRange,

  /// Blocking: dated after today.
  future,

  /// Excluded until kept: a stored weigh-in, or an earlier row, on the same
  /// date within [WeighInBatchCheck.duplicateKg].
  duplicate,

  /// Excluded until kept: a unit mix-up or a large jump ([WeighInCheck]).
  implausible,

  /// Info: a stored weigh-in that date with another value; the row stays
  /// included and the day's earliest weigh-in feeds the trend (WB-003).
  sameDay,
}

/// The exact reason an excluded row was flagged: what a Keep accepts (the
/// flag, the row's date, value and unit, and the reference: a stored
/// weigh-in as stored, an earlier row by position and typed content).
/// Opaque; compared by value; stable while the clock moves.
final class WeighInKeep {
  const new _(this._reason);

  final Object _reason;

  @override
  bool operator ==(Object other) =>
      other is WeighInKeep && other._reason == _reason;

  @override
  int get hashCode => _reason.hashCode;

  @override
  String toString() => 'WeighInKeep';
}

/// The check of one row (A15b D17).
final class WeighInRowResult {
  const new _({
    required this.index,
    this.draft,
    this.blocking,
    this.exclusion,
    this.implausible,
    this.reference,
    this.duplicateOfRow,
    this.sameDay = false,
    this.keepToken,
    this.kept = false,
  });

  /// The row's position in the checked list.
  final int index;

  /// What would be saved, or `null` when [blocking] is
  /// [WeighInRowFlag.incomplete].
  final WeighInDraft? draft;

  /// [WeighInRowFlag.incomplete], [WeighInRowFlag.outOfRange] or
  /// [WeighInRowFlag.future] (Save is disabled), else `null`.
  final WeighInRowFlag? blocking;

  /// [WeighInRowFlag.duplicate] or [WeighInRowFlag.implausible] (left out
  /// until kept), else `null`.
  final WeighInRowFlag? exclusion;

  /// The [WeighInCheck] finding ([LikelyOtherUnit] or [LargeChange]) when
  /// [exclusion] is [WeighInRowFlag.implausible].
  final WeighInCheckResult? implausible;

  /// What the row was compared with for [exclusion]: a stored weigh-in, or
  /// an earlier row as a weigh-in (its value, date and time).
  final WeighIn? reference;

  /// The earlier row's index when [exclusion] is a duplicate of a row,
  /// else `null`.
  final int? duplicateOfRow;

  /// Whether the [WeighInRowFlag.sameDay] info applies.
  final bool sameDay;

  /// What a Keep stores ([WeighInBatchRow.keep]), when [exclusion] is set.
  final WeighInKeep? keepToken;

  /// Whether the row's Keep matches [keepToken].
  final bool kept;

  /// Whether the row is saved.
  bool get included =>
      draft != null && blocking == null && (exclusion == null || kept);

  /// Every flag that applies, the blocking one first.
  List<WeighInRowFlag> get flags => [
    ?blocking,
    ?exclusion,
    if (sameDay) WeighInRowFlag.sameDay,
  ];

  @override
  String toString() =>
      'WeighInRowResult($index, ${flags.map((f) => f.name).join(',')}'
      '${kept ? ', kept' : ''})';
}

/// The check of every row (A15b D17).
final class WeighInBatchResult {
  new _(Iterable<WeighInRowResult> rows, Iterable<WeighInDraft> included)
    : rows = List.unmodifiable(rows),
      included = List.unmodifiable(included);

  /// One result per row, in the rows' order. Unmodifiable.
  final List<WeighInRowResult> rows;

  /// The drafts to save, in date order. Unmodifiable.
  final List<WeighInDraft> included;

  /// Whether a row blocks Save.
  bool get hasBlocking => rows.any((row) => row.blocking != null);

  /// Whether Save is enabled: no blocking row, at least one included row
  /// and at most [WeighInBatchCheck.maxRows].
  bool get canSave =>
      !hasBlocking &&
      included.isNotEmpty &&
      included.length <= WeighInBatchCheck.maxRows;

  @override
  String toString() =>
      'WeighInBatchResult(${rows.length} rows, ${included.length} included)';
}

/// The checks of the multi-row weight history entry (WB-005, WB-031,
/// A15b D17). A29 reuses it for the paste import.
abstract final class WeighInBatchCheck {
  /// The most rows one save holds (one change set).
  static const int maxRows = ChangeSet.maxOps;

  /// A row within this many kg of a weigh-in on the same date is a
  /// duplicate.
  static const double duplicateKg = 0.05;

  static const double _tolerance = 1e-9;

  /// Checks [rows] against [existing] (live weigh-ins; unreadable rows are
  /// ignored) on [today]; [timeFor] gives a row's measured time
  /// ([WeighInBatch.timeFor]).
  ///
  /// Rows are checked in date order (ties by position). A row is:
  /// - **blocked** when it has no date or value ([WeighInRowFlag.incomplete]),
  ///   is out of range or before 1970 ([WeighInRowFlag.outOfRange]) or is
  ///   dated after [today] ([WeighInRowFlag.future]);
  /// - **excluded until kept** when it duplicates a stored weigh-in or an
  ///   earlier included row on its date ([WeighInRowFlag.duplicate]), or
  ///   when [WeighInCheck] against the stored weigh-ins and the earlier
  ///   included rows finds a unit mix-up or a large jump
  ///   ([WeighInRowFlag.implausible]);
  /// - **informed** when a stored weigh-in that date has another value
  ///   ([WeighInRowFlag.sameDay]).
  ///
  /// Kept rows count as references for later rows.
  static WeighInBatchResult check({
    required List<WeighInBatchRow> rows,
    required Iterable<WeighIn> existing,
    required LocalDate today,
    required EntryTime Function(LocalDate date) timeFor,
  }) {
    final stored = [
      for (final weighIn in existing)
        if (weighIn.isReadable) weighIn,
    ];
    final results = List<WeighInRowResult?>.filled(rows.length, null);
    final dated = <int>[];
    for (final (i, row) in rows.indexed) {
      if (row.date == null || row.value == null) {
        results[i] = WeighInRowResult._(
          index: i,
          blocking: WeighInRowFlag.incomplete,
        );
      } else {
        dated.add(i);
      }
    }
    dated.sort((a, b) {
      final byDate = rows[a].date!.compareTo(rows[b].date!);
      return byDate != 0 ? byDate : a.compareTo(b);
    });

    final earlier = <WeighIn>[];
    final included = <WeighInDraft>[];
    for (final i in dated) {
      final row = rows[i];
      final date = row.date!;
      final draft = WeighInDraft(
        time: timeFor(date),
        input: WeighInInput(row.value!, row.unit),
      );
      final blocking = draft.validate() != null
          ? WeighInRowFlag.outOfRange
          : date.isAfter(today)
          ? WeighInRowFlag.future
          : null;
      if (blocking != null) {
        results[i] = WeighInRowResult._(
          index: i,
          draft: draft,
          blocking: blocking,
        );
        continue;
      }
      final kg = draft.kg;
      final sameDate = [
        for (final weighIn in stored)
          if (weighIn.localDate == date) weighIn,
      ];
      final duplicate = _firstWithin(sameDate, kg);
      final duplicateRow = duplicate == null
          ? _firstWithin([
              for (final weighIn in earlier)
                if (weighIn.localDate == date) weighIn,
            ], kg)
          : null;
      WeighInRowFlag? exclusion;
      WeighInCheckResult? finding;
      WeighIn? reference;
      if (duplicate ?? duplicateRow case final match?) {
        exclusion = WeighInRowFlag.duplicate;
        reference = match;
      } else {
        final result = WeighInCheck.check(
          candidate: draft,
          others: [...stored, ...earlier],
        );
        switch (result) {
          case LikelyOtherUnit(reference: final ref) ||
              LargeChange(reference: final ref):
            exclusion = WeighInRowFlag.implausible;
            finding = result;
            reference = ref;
          case Plausible():
            break;
        }
      }
      final keepToken = exclusion == null
          ? null
          : WeighInKeep._((
              exclusion,
              date,
              row.value,
              row.unit,
              _referenceKey(reference!),
              _findingKey(finding),
            ));
      final result = WeighInRowResult._(
        index: i,
        draft: draft,
        exclusion: exclusion,
        implausible: finding,
        reference: reference,
        duplicateOfRow: duplicateRow == null ? null : _rowIndex(duplicateRow),
        sameDay: exclusion != WeighInRowFlag.duplicate && sameDate.isNotEmpty,
        keepToken: keepToken,
        kept: keepToken != null && row.keep == keepToken,
      );
      results[i] = result;
      if (result.included) {
        included.add(draft);
        earlier.add(
          WeighIn(
            id: _rowId(i),
            version: 1,
            time: draft.time,
            localDate: date,
            kg: kg,
            input: draft.input,
          ),
        );
      }
    }
    return WeighInBatchResult._(results.nonNulls, included);
  }

  /// What a Keep remembers of [reference]: a stored weigh-in as it is
  /// (ID, version, value, time), an earlier row by its position and typed
  /// content only. A row's time isn't stable (today's follows the clock
  /// until 08:00), so it never enters the token (A15b review m3).
  static Object _referenceKey(WeighIn reference) => _isRowId(reference.id)
      ? (
          _rowIndex(reference),
          reference.localDate,
          reference.input.value,
          reference.input.unit,
        )
      : reference;

  /// The finding without its reference (already in [_referenceKey]).
  static Object? _findingKey(WeighInCheckResult? finding) => switch (finding) {
    LikelyOtherUnit(:final suggestedUnit, :final suggestedKg) => (
      suggestedUnit,
      suggestedKg,
    ),
    LargeChange(:final diffKg) => diffKg,
    _ => null,
  };

  static bool _isRowId(String id) => id.startsWith(_rowIdPrefix);

  static const String _rowIdPrefix = '00000000-0000-0000-0000-';

  static WeighIn? _firstWithin(List<WeighIn> candidates, double kg) {
    for (final weighIn in candidates) {
      if ((weighIn.kg - kg).abs() <= duplicateKg + _tolerance) return weighIn;
    }
    return null;
  }

  /// A row as a weigh-in reference gets a fixed nil-prefixed ID from its
  /// position, never a stored row's ID.
  static String _rowId(int index) =>
      '$_rowIdPrefix${index.toRadixString(16).padLeft(12, '0')}';

  static int _rowIndex(WeighIn row) =>
      int.parse(row.id.substring(row.id.length - 12), radix: 16);
}

/// Building the weight history's change set (WB-001, A15b D17).
abstract final class WeighInBatch {
  /// The local time a past weigh-in gets (08:00).
  static final LocalTime defaultTime = LocalTime(8);

  /// The measured time of a row on [date]: 08:00 local in the device zone
  /// at that date (DST-safe, [EntryTime.fromLocal]); on today, the earlier
  /// of 08:00 and now, so it is never in the future.
  static EntryTime timeFor(LocalDate date, Clock clock) {
    final now = EntryTime.now(clock);
    final morning = EntryTime.fromLocal(defaultTime.on(date), clock);
    return date == now.localDate &&
            now.occurredAtUtc.isBefore(morning.occurredAtUtc)
        ? now
        : morning;
  }

  /// One [CreateWeighIn] per draft, with the matching ID from [ids].
  /// Throws an `ArgumentError` when the lengths differ, or for none or
  /// more than [WeighInBatchCheck.maxRows].
  static List<CreateWeighIn> ops(List<WeighInDraft> drafts, List<String> ids) {
    if (drafts.length != ids.length) {
      throw ArgumentError.value(ids.length, 'ids', 'must match the drafts');
    }
    if (drafts.isEmpty || drafts.length > WeighInBatchCheck.maxRows) {
      throw ArgumentError.value(
        drafts.length,
        'drafts',
        'must be 1 to ${WeighInBatchCheck.maxRows}',
      );
    }
    return [
      for (final (i, draft) in drafts.indexed) CreateWeighIn(ids[i], draft),
    ];
  }
}
