import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/units/units.dart';

/// The limits of a new weigh-in (WB-003, A14 D6). They apply to local
/// writes only: rows read from sync are never rejected.
abstract final class WeighInBounds {
  /// The lightest weigh-in, in kg, after conversion.
  static const double minKg = 20;

  /// The heaviest weigh-in, in kg, after conversion.
  static const double maxKg = 500;

  /// The longest note, in Unicode code points (the wire's `maxLength`
  /// unit), after trimming.
  static const int noteMax = 200;

  /// How far after now a measured time may be (clock skew), see
  /// [WeighInDraft.isInFuture].
  static const Duration futureTolerance = Duration(minutes: 5);

  /// The largest stored kg the app reads (a sanity bound for synced rows,
  /// far above [maxKg]); see [isReadableKg].
  static const double readMaxKg = 1000000;

  /// Whether a stored [kg] is one the app can read: finite, above 0 and at
  /// most [readMaxKg]. Rows outside it (possible only via sync) are left
  /// out of the trend, the checks and the lists.
  static bool isReadableKg(double kg) =>
      kg.isFinite && kg > 0 && kg <= readMaxKg;

  /// The smallest value with one decimal in [unit] that is in range
  /// (20.0 kg, 44.1 lb), for the range hint.
  static double minIn(MassUnit unit) =>
      (minKg * _gramsPerKg / unit.grams * 10).ceil() / 10;

  /// The largest value with one decimal in [unit] that is in range
  /// (500.0 kg, 1,102.3 lb), for the range hint.
  static double maxIn(MassUnit unit) =>
      (maxKg * _gramsPerKg / unit.grams * 10).floor() / 10;
}

const double _gramsPerKg = 1000;

/// Why a weigh-in draft can't be saved (A14 D6). Content-free: the app maps
/// each to an ARB string.
enum WeighInIssue {
  /// The unit isn't kg or lb.
  unit,

  /// The value is not finite, or outside 20–500 kg after conversion.
  outOfRange,

  /// The note is longer than [WeighInBounds.noteMax].
  noteTooLong,

  /// The note has a control character (`\p{Cc}`).
  noteInvalid,

  /// The measured time is before 1970-01-01T00:00Z (the wire's minimum).
  time,
}

/// The number the user typed and its unit (TD-017: the original input is
/// kept next to the canonical kg).
final class WeighInInput {
  /// [value] in [unit]. Checked by [validate], not here.
  const new(this.value, this.unit);

  /// The units a weigh-in can be typed in.
  static const Set<MassUnit> units = {MassUnit.kilogram, MassUnit.pound};

  /// The typed number. User content.
  final double value;

  /// The typed unit.
  final MassUnit unit;

  /// [value] in kg, rounded once to storage precision (214 lb → 97.07 kg).
  /// Throws an `ArgumentError` when [validate] would report `outOfRange` for
  /// a non-finite or huge value.
  double get kg => StoragePrecision.round(value * unit.grams / _gramsPerKg);

  /// `null` when the input can be stored, else the issue: [WeighInIssue.unit]
  /// or [WeighInIssue.outOfRange].
  WeighInIssue? validate() {
    if (!units.contains(unit)) return WeighInIssue.unit;
    final raw = value * unit.grams / _gramsPerKg;
    // The margin keeps huge values away from the rounding's limit.
    if (!raw.isFinite ||
        raw < WeighInBounds.minKg - 1 ||
        raw > WeighInBounds.maxKg + 1) {
      return WeighInIssue.outOfRange;
    }
    final rounded = kg;
    return rounded < WeighInBounds.minKg || rounded > WeighInBounds.maxKg
        ? WeighInIssue.outOfRange
        : null;
  }

  @override
  bool operator ==(Object other) =>
      other is WeighInInput && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);

  /// The unit only, never the value.
  @override
  String toString() => 'WeighInInput(${unit.code})';
}

/// What the weigh-in pad saves (WB-001, WB-003, A14 D6).
final class WeighInDraft {
  /// [input] measured at [time], with an optional [note] (trimmed; empty
  /// becomes `null`). Checked by [validate], not here.
  new({required this.time, required this.input, String? note})
    : note = _normalizeNote(note);

  /// When it was measured, with the zone offset in effect there.
  final EntryTime time;

  /// The typed value and unit.
  final WeighInInput input;

  /// The note ("after Eid"), or `null`. User content.
  final String? note;

  /// The canonical kg, see [WeighInInput.kg].
  double get kg => input.kg;

  /// The day it belongs to, from the stored offset (DY-002).
  LocalDate get localDate => time.localDate;

  /// `null` when the draft can be saved, else the first issue: the input
  /// ([WeighInInput.validate]), then the time, then the note.
  WeighInIssue? validate() {
    if (input.validate() case final issue?) return issue;
    if (time.occurredAtUtc.millisecondsSinceEpoch < 0) return WeighInIssue.time;
    if (note case final text?) {
      if (text.runes.length > WeighInBounds.noteMax) {
        return WeighInIssue.noteTooLong;
      }
      if (_controlCharacter.hasMatch(text)) return WeighInIssue.noteInvalid;
    }
    return null;
  }

  /// Whether the measured time is more than
  /// [WeighInBounds.futureTolerance] after [nowUtc] (a future weigh-in
  /// can't be saved).
  bool isInFuture(DateTime nowUtc) =>
      time.occurredAtUtc.isAfter(nowUtc.add(WeighInBounds.futureTolerance));

  @override
  bool operator ==(Object other) =>
      other is WeighInDraft &&
      other.time == time &&
      other.input == input &&
      other.note == note;

  @override
  int get hashCode => Object.hash(time, input, note);

  /// Never the value or the note.
  @override
  String toString() => 'WeighInDraft';
}

/// Only `\p{Cc}`: format characters (`\p{Cf}`: ZWJ in emoji, RLM/LRM in
/// mixed Arabic/English notes) are allowed (A14 PA8).
final RegExp _controlCharacter = RegExp(r'\p{Cc}', unicode: true);

String? _normalizeNote(String? note) {
  final trimmed = note?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// A stored weigh-in, the read model (WB-003, A14 D7).
///
/// Built from any stored row, synced ones included, so [kg] isn't checked
/// here (the trend and the checks skip rows whose kg isn't
/// [WeighInBounds.isReadableKg], see [isReadable]).
final class WeighIn {
  /// The row [id] at [version]. Throws an `ArgumentError` for an invalid ID
  /// or version.
  new({
    required this.id,
    required this.version,
    required this.time,
    required this.localDate,
    required this.kg,
    required this.input,
    this.note,
    this.preferredForDay = false,
  }) {
    checkUuid(id, 'id');
    checkRowVersion(version);
  }

  /// The row ID.
  final String id;

  /// The row version (optimistic concurrency).
  final int version;

  /// When it was measured.
  final EntryTime time;

  /// The stored day (`local_date`, from the stored offset).
  final LocalDate localDate;

  /// The canonical value in kg. User content.
  final double kg;

  /// The value and unit as typed.
  final WeighInInput input;

  /// The note, or `null`. User content.
  final String? note;

  /// Whether the user picked it for the trend on its day (WB-003, A14 D3).
  final bool preferredForDay;

  /// Whether [kg] is one the app can read ([WeighInBounds.isReadableKg]).
  bool get isReadable => WeighInBounds.isReadableKg(kg);

  /// The ID at the version this read saw, for ops.
  VersionedId get versionedId => VersionedId(id, version);

  /// Its content as a draft, e.g. to prefill the edit sheet.
  WeighInDraft get draft => WeighInDraft(time: time, input: input, note: note);

  @override
  bool operator ==(Object other) =>
      other is WeighIn &&
      other.id == id &&
      other.version == version &&
      other.time == time &&
      other.localDate == localDate &&
      other.kg == kg &&
      other.input == input &&
      other.note == note &&
      other.preferredForDay == preferredForDay;

  @override
  int get hashCode => Object.hash(
    id,
    version,
    time,
    localDate,
    kg,
    input,
    note,
    preferredForDay,
  );

  /// Never the value or the note.
  @override
  String toString() => 'WeighIn($id@v$version)';
}

/// The weigh-in each day contributes to the trend (WB-003, A14 D3).
abstract final class DayChoice {
  /// One weigh-in per `localDate`, sorted by date: the day's preferred one
  /// (the earliest preferred when a sync left several), else the earliest
  /// by measured time. Equal times break ties by ID.
  static List<WeighIn> of(Iterable<WeighIn> weighIns) {
    final byDay = <LocalDate, WeighIn>{};
    for (final weighIn in weighIns) {
      final current = byDay[weighIn.localDate];
      if (current == null || _precedes(weighIn, current)) {
        byDay[weighIn.localDate] = weighIn;
      }
    }
    final days = byDay.values.toList()
      ..sort((a, b) => a.localDate.compareTo(b.localDate));
    return List.unmodifiable(days);
  }

  static bool _precedes(WeighIn a, WeighIn b) {
    if (a.preferredForDay != b.preferredForDay) return a.preferredForDay;
    final byTime = a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc);
    return byTime != 0 ? byTime < 0 : a.id.compareTo(b.id) < 0;
  }
}
