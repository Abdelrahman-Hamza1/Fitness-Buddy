import 'dart:math' as math;

import 'package:fb_design_system/fb_design_system.dart'
    show NumberPadBackspace, NumberPadBuffer, NumberPadKey;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/application/weigh_in_actions.dart';

/// Why the weigh-in sheet can't save yet (A14 D6, D8). Content-free: the
/// sheet maps each to its hint.
enum WeighInFormIssue {
  /// Nothing typed.
  empty,

  /// Outside 20–500 kg after conversion: Save off; the range hint shows
  /// once more digits can't fix it ([WeighInFormState.showRangeHint]).
  outOfRange,

  /// After now (beyond the clock-skew tolerance).
  future,

  /// Before 1970-01-01T00:00Z (A14 PA9).
  tooEarly,

  /// The note is over [WeighInBounds.noteMax] code points.
  noteTooLong,

  /// The note has a control character.
  noteInvalid,
}

/// What the sheet hands to [WeighInActions] once a save may go ahead.
final class WeighInSubmission {
  /// [draft], for a new weigh-in or for [editing], with the day's trend
  /// choice [trend] when the user changed it.
  const new({required this.draft, this.editing, this.trend});

  /// What is saved.
  final WeighInDraft draft;

  /// The weigh-in being edited, at the version shown; `null` to log.
  final WeighIn? editing;

  /// The trend choice to apply in the same change set, or `null`.
  final WeighInTrendPick? trend;

  @override
  String toString() => 'WeighInSubmission';
}

/// The weigh-in sheet's state (WB-001, WB-003, WB-005, A14 D8): what was
/// typed, in which unit, when, the note and the trend switch, plus the live
/// weigh-ins it is checked against. Immutable and pure: every edit returns
/// a new state; time comes in as a parameter.
///
/// The value is never converted: a unit switch relabels the typed number
/// (TG-002, LC-011). The prefill (the latest weigh-in, or the edited one)
/// is replaced by the first digit typed. Weigh-ins whose kg the app can't
/// read ([WeighIn.isReadable], possible only via sync) are left out.
final class WeighInFormState {
  const new _({
    required this.unit,
    required this.time,
    required this.weighIns,
    this.editing,
    this.buffer = '',
    this.prefilled = false,
    this.note = '',
    this.useForTrend,
    this.confirming,
  });

  /// A new weigh-in at [time] in [unit], prefilled with the latest of
  /// [weighIns] in [unit]: its typed value when the units match, else
  /// converted to one decimal.
  factory log({
    required List<WeighIn> weighIns,
    required MassUnit unit,
    required EntryTime time,
  }) {
    final readable = _readable(weighIns);
    final latest = _latest(readable);
    final text = latest == null ? '' : _prefill(latest, unit);
    return WeighInFormState._(
      unit: unit,
      time: time,
      weighIns: readable,
      buffer: text,
      prefilled: text.isNotEmpty,
    );
  }

  /// An edit of [editing], filled with its value and unit as typed, its
  /// time and its note.
  factory edit(WeighIn editing, {required List<WeighIn> weighIns}) {
    final text = _bufferText(editing.input.value);
    return WeighInFormState._(
      editing: editing,
      unit: editing.input.unit,
      time: editing.time,
      weighIns: _readable(weighIns),
      buffer: text ?? '',
      prefilled: text != null,
      note: editing.note ?? '',
    );
  }

  /// The pad's limits (A14 D6): 4 digits and 1 decimal.
  static const int maxDigits = 4;

  /// See [maxDigits].
  static const int maxDecimals = 1;

  /// An ID that sorts after every real one, for a weigh-in not saved yet
  /// (equal times break ties by ID, and a new row's UUIDv7 is the newest).
  static const String _unsavedId = 'ffffffff-ffff-7fff-bfff-ffffffffffff';

  /// The weigh-in being edited, at the version shown; `null` when logging.
  final WeighIn? editing;

  /// The pad text, `.` as the decimal point.
  final String buffer;

  /// The buffer still holds the prefill: the first digit replaces it.
  final bool prefilled;

  /// The unit the number means.
  final MassUnit unit;

  /// When it was measured.
  final EntryTime time;

  /// The note as typed (trimmed when saved).
  final String note;

  /// The trend switch as the user set it; `null` while untouched (it then
  /// shows [defaultForTrend]).
  final bool? useForTrend;

  /// The live weigh-ins (the edited one included). Unmodifiable.
  final List<WeighIn> weighIns;

  /// The unusual value the sheet asks about (WB-005), or `null`.
  final WeighInCheckResult? confirming;

  /// Whether this edits a stored weigh-in.
  bool get isEdit => editing != null;

  /// The typed number, or `null` while empty.
  double? get value => buffer.isEmpty ? null : double.tryParse(buffer);

  /// The typed number in [unit], or `null` while empty. While an edit's
  /// prefill is untouched (same unit) it is the stored input exactly, so a
  /// note or time change doesn't round 97.25 to the pad's 97.3.
  WeighInInput? get input {
    final stored = editing?.input;
    if (prefilled && stored != null && stored.unit == unit) return stored;
    return switch (value) {
      final v? => WeighInInput(v, unit),
      null => null,
    };
  }

  /// What would be saved, or `null` while empty. Not validated.
  WeighInDraft? get draft => switch (input) {
    final i? => WeighInDraft(time: time, input: i, note: note),
    null => null,
  };

  /// The chosen day.
  LocalDate get date => time.localDate;

  /// An edit that moves the weigh-in to another day: the move clears its
  /// trend preference, so the switch is hidden (A14 D3, PA6).
  bool get dateMoved => editing != null && editing!.localDate != date;

  /// The other live weigh-ins on [date], by measured time.
  List<WeighIn> get sameDay => [
    for (final w in weighIns)
      if (w.localDate == date && w.id != editing?.id) w,
  ]..sort(_byTime);

  /// The weigh-in the trend uses for [date] now, as stored (the edited one
  /// included), or `null` without any.
  WeighIn? get usedForTrendNow {
    final day = [
      for (final w in weighIns)
        if (w.localDate == date) w,
    ];
    return day.isEmpty ? null : DayChoice.of(day).single;
  }

  /// Whether the "Use this weigh-in for the trend" switch shows: another
  /// weigh-in on the day, and not an edit that moves days.
  bool get showTrendSwitch => sameDay.isNotEmpty && !dateMoved;

  /// Whether this weigh-in would be the day's trend choice with no explicit
  /// pick (WB-003: the preferred one, else the earliest).
  bool get defaultForTrend {
    final self = WeighIn(
      id: editing?.id ?? _unsavedId,
      version: 1,
      time: time,
      localDate: date,
      kg: 0,
      input: WeighInInput(0, unit),
      preferredForDay: !dateMoved && (editing?.preferredForDay ?? false),
    );
    return DayChoice.of([...sameDay, self]).single.id == self.id;
  }

  /// The switch's value.
  bool get forTrend => useForTrend ?? defaultForTrend;

  /// The trend choice a save applies, or `null` when it is the default.
  WeighInTrendPick? get trendPick =>
      showTrendSwitch && forTrend != defaultForTrend
      ? WeighInTrendPick(useThis: forTrend, dayOthers: sameDay)
      : null;

  /// The first reason Save is off at [nowUtc], or `null`.
  WeighInFormIssue? issueAt(DateTime nowUtc) {
    final draft = this.draft;
    if (draft == null) return WeighInFormIssue.empty;
    final issue = switch (draft.validate()) {
      null => null,
      WeighInIssue.unit ||
      WeighInIssue.outOfRange => WeighInFormIssue.outOfRange,
      WeighInIssue.time => WeighInFormIssue.tooEarly,
      WeighInIssue.noteTooLong => WeighInFormIssue.noteTooLong,
      WeighInIssue.noteInvalid => WeighInFormIssue.noteInvalid,
    };
    if (issue != null) return issue;
    return draft.isInFuture(nowUtc) ? WeighInFormIssue.future : null;
  }

  /// Whether the range hint shows (A14 m2): the value is out of range and
  /// more digits can't bring it in (it is above the maximum, or below the
  /// minimum with the decimals started or every digit used). "1" or "19"
  /// can still become "190": no hint while typing.
  bool get showRangeHint {
    final v = value;
    if (v == null || input?.validate() != WeighInIssue.outOfRange) {
      return false;
    }
    final canGrow = !buffer.contains('.') && buffer.length < maxDigits;
    return !(v < WeighInBounds.minIn(unit) && canGrow);
  }

  /// The implausible-value check of the typed value (WB-005), the edited
  /// weigh-in left out.
  WeighInCheckResult get check => switch (draft) {
    final d? => WeighInCheck.check(
      candidate: d,
      others: weighIns,
      editingId: editing?.id,
    ),
    null => const Plausible(),
  };

  /// A pad key: the first digit or point replaces the prefill; backspace
  /// edits it. Closes a confirmation.
  WeighInFormState key(NumberPadKey key) {
    final start = prefilled && key is! NumberPadBackspace ? '' : buffer;
    final next = NumberPadBuffer(
      // The weigh-in limits, explicit: equal to the pad's defaults today.
      // ignore: avoid_redundant_argument_values
      maxDigits: maxDigits,
      // As above: the weigh-in's own limit, not the pad's default.
      // ignore: avoid_redundant_argument_values
      maxDecimals: maxDecimals,
      text: start,
    ).apply(key);
    return _copy(buffer: next.text, prefilled: false, clearConfirm: true);
  }

  /// The number now means [unit]; it is not converted (TG-002).
  WeighInFormState withUnit(MassUnit unit) =>
      unit == this.unit ? this : _copy(unit: unit, clearConfirm: true);

  /// The measured time. A new day resets the trend switch to its default.
  WeighInFormState withTime(EntryTime time) =>
      _copy(time: time, clearConfirm: true, clearTrend: time.localDate != date);

  /// The note as typed.
  WeighInFormState withNote(String note) => _copy(note: note);

  /// The trend switch.
  WeighInFormState withUseForTrend({required bool on}) =>
      _copy(useForTrend: on);

  /// New live weigh-ins (a reactive reload). What was typed stays.
  WeighInFormState withWeighIns(List<WeighIn> weighIns) =>
      _copy(weighIns: _readable(weighIns));

  /// "Reload" after a save was refused because the edited weigh-in changed
  /// (A14 m6, the diary's stale-entry pattern): the form over the weigh-in
  /// as stored now, at its new version. What the user changed stays (the
  /// typed value and unit, the time, the note); what they didn't change
  /// follows the stored row. `null` when it was deleted; unchanged when
  /// logging.
  WeighInFormState? reload() {
    final old = editing;
    if (old == null) return this;
    final stored = weighIns.where((w) => w.id == old.id).firstOrNull;
    if (stored == null) return null;
    final keepValue = !prefilled || unit != old.input.unit;
    final text = keepValue ? buffer : _bufferText(stored.input.value);
    return WeighInFormState._(
      editing: stored,
      unit: keepValue ? unit : stored.input.unit,
      time: time == old.time ? stored.time : time,
      weighIns: weighIns,
      buffer: text ?? '',
      prefilled: !keepValue && text != null,
      note: note == (old.note ?? '') ? stored.note ?? '' : note,
      useForTrend: useForTrend,
    );
  }

  /// Closes the confirmation and goes back to the pad ("Edit").
  WeighInFormState backToPad() => _copy(clearConfirm: true);

  /// Save tapped at [nowUtc]: nothing when Save is off; the confirmation
  /// when the value is unusual (WB-005); else the submission.
  (WeighInFormState, WeighInSubmission?) save(DateTime nowUtc) {
    if (issueAt(nowUtc) != null) return (this, null);
    if (confirming != null) return confirm();
    final result = check;
    if (result is! Plausible) return (_copy(confirming: result), null);
    return (this, _submission());
  }

  /// The confirmation answered with Save: saves as typed, or in the
  /// suggested unit when [otherUnit] ("Save as 214.0 lb"). Nothing without
  /// an open confirmation.
  (WeighInFormState, WeighInSubmission?) confirm({bool otherUnit = false}) {
    final asked = confirming;
    if (asked == null) return (this, null);
    final next = switch (asked) {
      LikelyOtherUnit(:final suggestedUnit) when otherUnit => _copy(
        unit: suggestedUnit,
        clearConfirm: true,
      ),
      _ => _copy(clearConfirm: true),
    };
    return (next, next._submission());
  }

  WeighInSubmission _submission() =>
      WeighInSubmission(draft: draft!, editing: editing, trend: trendPick);

  WeighInFormState _copy({
    String? buffer,
    bool? prefilled,
    MassUnit? unit,
    EntryTime? time,
    String? note,
    bool? useForTrend,
    List<WeighIn>? weighIns,
    WeighInCheckResult? confirming,
    bool clearConfirm = false,
    bool clearTrend = false,
  }) => WeighInFormState._(
    editing: editing,
    buffer: buffer ?? this.buffer,
    prefilled: prefilled ?? this.prefilled,
    unit: unit ?? this.unit,
    time: time ?? this.time,
    note: note ?? this.note,
    useForTrend: clearTrend ? null : useForTrend ?? this.useForTrend,
    weighIns: weighIns ?? this.weighIns,
    confirming: clearConfirm ? null : confirming ?? this.confirming,
  );

  @override
  String toString() => 'WeighInFormState(${editing?.id ?? 'new'})';

  static List<WeighIn> _readable(List<WeighIn> weighIns) =>
      List.unmodifiable(weighIns.where((weighIn) => weighIn.isReadable));

  static WeighIn? _latest(List<WeighIn> weighIns) {
    if (weighIns.isEmpty) return null;
    return ([...weighIns]..sort(_byTime)).last;
  }

  static int _byTime(WeighIn a, WeighIn b) {
    final byTime = a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  /// [latest] in [unit]: as typed when the units match, else converted.
  /// Empty when it doesn't fit the pad (a synced outlier).
  static String _prefill(WeighIn latest, MassUnit unit) {
    final value = latest.input.unit == unit
        ? latest.input.value
        : latest.kg * 1000 / unit.grams;
    return _bufferText(value) ?? '';
  }

  /// [value] as pad text with one decimal ("97.0"), or `null` when it isn't
  /// a positive number the pad can hold (at most [maxDigits] digits).
  static String? _bufferText(double value) {
    if (!value.isFinite || value <= 0 || value >= math.pow(10, maxDigits)) {
      return null;
    }
    final text = value.toStringAsFixed(maxDecimals);
    final digits = text.indexOf('.');
    return digits > maxDigits ? null : text;
  }
}
