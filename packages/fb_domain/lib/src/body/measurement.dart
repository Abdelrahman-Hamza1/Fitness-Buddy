import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/units/units.dart';

/// The kinds of body measurement (WB-040, A15b D13). The codes are a closed
/// wire enum (TD-080): a new built-in kind is a new `measurement` schema
/// version, server validator first.
enum MeasurementKind {
  /// Waist circumference.
  waist('waist'),

  /// Chest circumference.
  chest('chest'),

  /// Hip circumference.
  hips('hips'),

  /// Upper-arm circumference (one value; a custom "Left arm" covers sides).
  arm('arm'),

  /// Thigh circumference.
  thigh('thigh'),

  /// Neck circumference.
  neck('neck'),

  /// Body fat, in percent, entered by hand (WB-042).
  bodyFat('bodyFat'),

  /// A user-named length (a `measurement_types` row).
  custom('custom');

  new(this.code);

  /// The built-in kinds in display order: every kind but [custom].
  static const List<MeasurementKind> builtIns = [
    waist,
    chest,
    hips,
    arm,
    thigh,
    neck,
    bodyFat,
  ];

  /// The stable wire and storage code.
  final String code;

  /// Whether it is a length (cm/in). Only [bodyFat] is a percent.
  bool get isLength => this != bodyFat;

  /// The kind whose [code] is exactly [code], or `null`.
  static MeasurementKind? fromCode(String code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// The units a measurement can be typed in (TD-017: the input is kept next
/// to the canonical value).
enum MeasurementUnit {
  /// Centimetres, the canonical length unit.
  cm('cm', 1),

  /// Inches (exact, 2.54 cm).
  inch('in', 2.54),

  /// Percent, body fat only.
  percent('percent', 1);

  new(this.code, this.factor);

  /// The stable wire and storage code.
  final String code;

  /// Canonical units (cm, or %) in one of this unit.
  final double factor;

  /// Whether it is a length unit.
  bool get isLength => this != percent;

  /// The length unit of [unit] (cm for metric, inches for imperial).
  static MeasurementUnit ofLength(LengthUnit unit) =>
      unit == LengthUnit.inch ? inch : cm;

  /// The unit whose [code] is exactly [code], or `null`.
  static MeasurementUnit? fromCode(String code) {
    for (final unit in values) {
      if (unit.code == code) return unit;
    }
    return null;
  }
}

/// Which measurement series: a built-in [kind], or a custom type by ID
/// (A15b D15). A plain value: [MeasurementDraft.validate] checks that a
/// custom kind has a type and a built-in one hasn't (wire rule M1).
final class MeasurementTypeRef {
  /// [kind] with [customTypeId]. Throws an `ArgumentError` when
  /// [customTypeId] isn't a lowercase canonical UUID.
  new({required this.kind, this.customTypeId}) {
    if (customTypeId case final id?) checkUuid(id, 'customTypeId');
  }

  /// A built-in [kind]. Throws an `ArgumentError` for [MeasurementKind.custom].
  new builtIn(MeasurementKind kind) : this(kind: _checkBuiltIn(kind));

  /// The custom type [customTypeId].
  new custom(String customTypeId)
    : this(kind: MeasurementKind.custom, customTypeId: customTypeId);

  /// The kind.
  final MeasurementKind kind;

  /// The custom type's ID, for [MeasurementKind.custom]; else `null`.
  final String? customTypeId;

  /// Whether the kind and the type ID agree (wire rule M1).
  bool get isConsistent =>
      (kind == MeasurementKind.custom) == (customTypeId != null);

  /// A stable key for routes and providers: the kind's code (`waist`), or
  /// `custom-<uuid>`.
  String get key => switch (customTypeId) {
    final id? when kind == MeasurementKind.custom => '$_customPrefix$id',
    _ => kind.code,
  };

  /// The ref whose [key] is [key], or `null` for anything else.
  static MeasurementTypeRef? parse(String key) {
    if (key.startsWith(_customPrefix)) {
      final id = key.substring(_customPrefix.length);
      return isUuid(id) ? MeasurementTypeRef.custom(id) : null;
    }
    final kind = MeasurementKind.fromCode(key);
    return kind == null || kind == MeasurementKind.custom
        ? null
        : MeasurementTypeRef.builtIn(kind);
  }

  static const String _customPrefix = 'custom-';

  static MeasurementKind _checkBuiltIn(MeasurementKind kind) {
    if (kind == MeasurementKind.custom) {
      throw ArgumentError.value(kind, 'kind', 'must be a built-in kind');
    }
    return kind;
  }

  @override
  bool operator ==(Object other) =>
      other is MeasurementTypeRef &&
      other.kind == kind &&
      other.customTypeId == customTypeId;

  @override
  int get hashCode => Object.hash(kind, customTypeId);

  /// The key (a kind code or a type ID, never a name).
  @override
  String toString() => 'MeasurementTypeRef($key)';
}

/// The limits of a new measurement (A15b D15). They apply to local writes
/// only: rows read from sync are never rejected for them.
abstract final class MeasurementBounds {
  /// The shortest length, in cm, after conversion.
  static const double minCm = 10;

  /// The longest length, in cm, after conversion.
  static const double maxCm = 300;

  /// The lowest body fat, in %.
  static const double minPercent = 2;

  /// The highest body fat, in %.
  static const double maxPercent = 75;

  /// How far after now a measured time may be (clock skew).
  static const Duration futureTolerance = Duration(minutes: 5);

  /// The largest stored value the app reads (the wire's maximum).
  static const double readMax = 1000000;

  /// The smallest value with one decimal in [unit] that is in range
  /// (10.0 cm, 4.0 in, 2.0 %), for the range hint.
  static double minIn(MeasurementUnit unit) =>
      ((unit.isLength ? minCm : minPercent) / unit.factor * 10).ceil() / 10;

  /// The largest value with one decimal in [unit] that is in range
  /// (300.0 cm, 118.1 in, 75.0 %), for the range hint.
  static double maxIn(MeasurementUnit unit) =>
      ((unit.isLength ? maxCm : maxPercent) / unit.factor * 10).floor() / 10;
}

/// Why a measurement draft can't be saved (A15b D15). Content-free: the
/// app maps each to an ARB string.
enum MeasurementIssue {
  /// A custom kind without a type, or a built-in kind with one (M1).
  customWithoutType,

  /// The unit doesn't fit the kind: percent on a length, cm/in on body fat
  /// (M2).
  unit,

  /// The value is not finite, or outside 10–300 cm / 2–75 % after
  /// conversion.
  outOfRange,

  /// The measured time is before 1970-01-01T00:00Z (the wire's minimum).
  time,
}

/// The number the user typed and its unit (TD-017).
final class MeasurementInput {
  /// [value] in [unit]. Checked by [MeasurementDraft.validate], not here.
  const new(this.value, this.unit);

  /// The typed number. User content.
  final double value;

  /// The typed unit.
  final MeasurementUnit unit;

  /// [value] in cm (or %), rounded once to storage precision
  /// (36.5 in → 92.71 cm). Throws an `ArgumentError` for a non-finite or
  /// huge value ([MeasurementDraft.validate] reports those first).
  double get canonical => StoragePrecision.round(value * unit.factor);

  @override
  bool operator ==(Object other) =>
      other is MeasurementInput && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);

  /// The unit only, never the value.
  @override
  String toString() => 'MeasurementInput(${unit.code})';
}

/// What the measurement form saves (WB-040, A15b D15).
final class MeasurementDraft {
  /// [input] of [type] measured at [time]. Checked by [validate], not here.
  const new({required this.type, required this.time, required this.input});

  /// The series.
  final MeasurementTypeRef type;

  /// When it was measured, with the zone offset in effect there (DY-002).
  final EntryTime time;

  /// The typed value and unit.
  final MeasurementInput input;

  /// The canonical value (cm, or % for body fat), see
  /// [MeasurementInput.canonical].
  double get value => input.canonical;

  /// The day it belongs to, from the stored offset (DY-002).
  LocalDate get localDate => time.localDate;

  /// `null` when the draft can be saved, else the first issue: the type
  /// (M1), the unit (M2), the range, then the time.
  MeasurementIssue? validate() {
    if (!type.isConsistent) return MeasurementIssue.customWithoutType;
    final isLength = type.kind.isLength;
    if (input.unit.isLength != isLength) return MeasurementIssue.unit;
    final raw = input.value * input.unit.factor;
    final (min, max) = isLength
        ? (MeasurementBounds.minCm, MeasurementBounds.maxCm)
        : (MeasurementBounds.minPercent, MeasurementBounds.maxPercent);
    // The margin keeps huge values away from the rounding's limit.
    if (!raw.isFinite || raw < min - 1 || raw > max + 1) {
      return MeasurementIssue.outOfRange;
    }
    final rounded = value;
    if (rounded < min || rounded > max) return MeasurementIssue.outOfRange;
    if (time.occurredAtUtc.millisecondsSinceEpoch < 0) {
      return MeasurementIssue.time;
    }
    return null;
  }

  /// Whether the measured time is more than
  /// [MeasurementBounds.futureTolerance] after [nowUtc].
  bool isInFuture(DateTime nowUtc) =>
      time.occurredAtUtc.isAfter(nowUtc.add(MeasurementBounds.futureTolerance));

  @override
  bool operator ==(Object other) =>
      other is MeasurementDraft &&
      other.type == type &&
      other.time == time &&
      other.input == input;

  @override
  int get hashCode => Object.hash(type, time, input);

  /// Never the value.
  @override
  String toString() => 'MeasurementDraft(${type.key})';
}

/// A stored measurement, the read model (WB-040, A15b D13).
final class Measurement {
  /// The row [id] at [version]. Throws an `ArgumentError` for an invalid ID
  /// or version.
  new({
    required this.id,
    required this.version,
    required this.type,
    required this.time,
    required this.localDate,
    required this.value,
    required this.input,
  }) {
    checkUuid(id, 'id');
    checkRowVersion(version);
  }

  /// The row ID.
  final String id;

  /// The row version (optimistic concurrency).
  final int version;

  /// The series.
  final MeasurementTypeRef type;

  /// When it was measured.
  final EntryTime time;

  /// The stored day (`local_date`).
  final LocalDate localDate;

  /// The canonical value: cm, or % for body fat. User content.
  final double value;

  /// The value and unit as typed.
  final MeasurementInput input;

  /// The ID at the version this read saw, for ops.
  VersionedId get versionedId => VersionedId(id, version);

  /// Its content as a draft, e.g. to prefill the edit sheet.
  MeasurementDraft get draft =>
      MeasurementDraft(type: type, time: time, input: input);

  @override
  bool operator ==(Object other) =>
      other is Measurement &&
      other.id == id &&
      other.version == version &&
      other.type == type &&
      other.time == time &&
      other.localDate == localDate &&
      other.value == value &&
      other.input == input;

  @override
  int get hashCode =>
      Object.hash(id, version, type, time, localDate, value, input);

  /// Never the value.
  @override
  String toString() => 'Measurement($id@v$version)';
}

/// A user's own measurement type, a length (A15b D13).
final class MeasurementType {
  /// The row [id] at [version] named [name]. Throws an `ArgumentError` for
  /// an invalid ID or version.
  new({required this.id, required this.version, required this.name}) {
    checkUuid(id, 'id');
    checkRowVersion(version);
  }

  /// The row ID.
  final String id;

  /// The row version.
  final int version;

  /// The name ("Left arm"). User content.
  final String name;

  /// The series it names.
  MeasurementTypeRef get ref => MeasurementTypeRef.custom(id);

  /// The ID at the version this read saw, for ops.
  VersionedId get versionedId => VersionedId(id, version);

  @override
  bool operator ==(Object other) =>
      other is MeasurementType &&
      other.id == id &&
      other.version == version &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, version, name);

  /// Never the name.
  @override
  String toString() => 'MeasurementType($id@v$version)';
}

/// Why a custom type name can't be saved. Content-free.
enum CustomTypeNameIssue {
  /// Empty after trimming.
  empty,

  /// Longer than [CustomTypeName.maxLength] characters after trimming.
  tooLong,

  /// Has a control character (`\p{Cc}`).
  invalid,
}

/// The rules of a custom measurement type's name (A15b D15, PA15).
abstract final class CustomTypeName {
  /// The longest name, in Unicode code points, after trimming.
  static const int maxLength = 40;

  /// [name] as stored: trimmed.
  static String normalize(String name) => name.trim();

  /// `null` when [name] can be saved, else the issue. Format characters
  /// (`\p{Cf}`: ZWJ, RLM) are allowed.
  static CustomTypeNameIssue? validate(String name) {
    final trimmed = normalize(name);
    if (trimmed.isEmpty) return CustomTypeNameIssue.empty;
    if (trimmed.runes.length > maxLength) return CustomTypeNameIssue.tooLong;
    if (_controlCharacter.hasMatch(trimmed)) {
      return CustomTypeNameIssue.invalid;
    }
    return null;
  }

  /// The key live names are unique by: trimmed and lower-cased in Dart
  /// (not SQL `NOCASE`, which folds ASCII only).
  static String compareKey(String name) => normalize(name).toLowerCase();

  /// Whether [a] and [b] are the same name, ignoring case and outer spaces.
  static bool same(String a, String b) => compareKey(a) == compareKey(b);
}

final RegExp _controlCharacter = RegExp(r'\p{Cc}', unicode: true);
