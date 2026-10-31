import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/targets/goals.dart';
import 'package:fb_domain/src/targets/macros.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/targets/target_rules.dart';
import 'package:fb_domain/src/targets/target_settings.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/units/units.dart';

/// The stable wire tag of each [GoalExpression] (A12 README, A13 D2).
enum GoalExpressionKind {
  /// [TargetDateGoal]: `targetKg` + `targetDate`.
  targetDate,

  /// [TargetRateGoal]: `targetKg` + positive `kgPerWeek`.
  targetRate,

  /// [WeeklyGoal]: signed `kgPerWeek`.
  weekly,

  /// [MonthlyGoal]: signed `monthKg` + `month`.
  monthly;

  /// The tag of [expression].
  static GoalExpressionKind of(GoalExpression expression) =>
      switch (expression) {
        TargetDateGoal() => targetDate,
        TargetRateGoal() => targetRate,
        WeeklyGoal() => weekly,
        MonthlyGoal() => monthly,
      };
}

/// How the user typed their height (TD-017: typed input is kept). The wire
/// code is [code].
enum HeightInputUnit {
  /// Centimetres.
  centimeter('cm'),

  /// Feet and inches.
  feetInches('ft_in');

  new(this.code);

  /// The stable wire code.
  final String code;

  /// The unit with wire [code], or null.
  static HeightInputUnit? ofCode(String code) {
    for (final unit in values) {
      if (unit.code == code) return unit;
    }
    return null;
  }
}

/// The body-weight units a goal can be typed in (TD-017), by [MassUnit]
/// wire code: `kg` and `lb`.
abstract final class GoalWeightUnits {
  /// The accepted units.
  static const List<MassUnit> values = [MassUnit.kilogram, MassUnit.pound];

  /// The unit with wire [code], or null.
  static MassUnit? ofCode(String code) {
    for (final unit in values) {
      if (unit.code == code) return unit;
    }
    return null;
  }
}

/// The camelCase content fields of the three sync payloads (A13 D2/D3),
/// in column order. Sync metadata (`createdAtMs`, `origin`,
/// `editedByUser`) and the row ID travel outside these maps.
abstract final class TargetWireFields {
  /// `profile` content fields.
  static const List<String> profile = [
    'sex',
    'birthYear',
    'heightCm',
    'heightInputUnit',
    'activity',
  ];

  /// `goalPhase` content fields.
  static const List<String> goalPhase = [
    'revision',
    'name',
    'startDate',
    'endDate',
    'goalType',
    'expressionKind',
    'targetKg',
    'targetDate',
    'kgPerWeek',
    'monthKg',
    'month',
    'weightInputUnit',
  ];

  /// The seven nullable weekday factor fields (NULL = the suggestion, PA5,
  /// D-090). The names keep the original v1 `shift*` wire names.
  static const Map<DayOfWeek, String> shifts = {
    DayOfWeek.monday: 'shiftMon',
    DayOfWeek.tuesday: 'shiftTue',
    DayOfWeek.wednesday: 'shiftWed',
    DayOfWeek.thursday: 'shiftThu',
    DayOfWeek.friday: 'shiftFri',
    DayOfWeek.saturday: 'shiftSat',
    DayOfWeek.sunday: 'shiftSun',
  };

  /// The three macro overrides, each a `{value, isPercent}` pair.
  static const List<String> macros = ['protein', 'fat', 'carbs'];

  /// `targetSettings` content fields.
  static const List<String> targetSettings = [
    'revision',
    'effectiveFrom',
    'mode',
    'rebalancing',
    'baseKcal',
    'manual',
    'acknowledged',
    'basisWeightKg',
    'shiftMon',
    'shiftTue',
    'shiftWed',
    'shiftThu',
    'shiftFri',
    'shiftSat',
    'shiftSun',
    'proteinValue',
    'proteinIsPercent',
    'fatValue',
    'fatIsPercent',
    'carbsValue',
    'carbsIsPercent',
    'fiberG',
    'caloriesProteinOnly',
  ];
}

/// The stored profile: one natural-key row (`profile:self`, TD-070). Body
/// weight is not stored here: weigh-ins are its only source (TD-090).
/// Sensitive: [toString] shows no values.
final class ProfileRecord {
  /// Canonical cm; validation is [TargetRules], not this constructor.
  const new({
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.heightInputUnit,
    required this.activity,
  });

  /// Decodes a wire map, or null when [TargetRules.wire] rejects it.
  static ProfileRecord? fromWire(Map<String, Object?> wire) {
    if (TargetRules.wire.profile(wire).isNotEmpty) return null;
    return ProfileRecord(
      sex: FormulaSex.values.byName(wire['sex']! as String),
      birthYear: wire['birthYear']! as int,
      heightCm: _double(wire['heightCm'])!,
      heightInputUnit: HeightInputUnit.ofCode(
        wire['heightInputUnit']! as String,
      )!,
      activity: ActivityLevel.values.byName(wire['activity']! as String),
    );
  }

  /// Formula sex.
  final FormulaSex sex;

  /// Birth year only (A12: age is evaluation year minus this).
  final int birthYear;

  /// Height, cm.
  final double heightCm;

  /// How the height was typed; display and editing use it (TD-017).
  final HeightInputUnit heightInputUnit;

  /// Activity category.
  final ActivityLevel activity;

  /// The engine profile at [weightKg] (the trend or basis weight, D6).
  TargetProfile toProfile(double weightKg) => TargetProfile(
    sex: sex,
    birthYear: birthYear,
    heightCm: heightCm,
    weightKg: weightKg,
    activity: activity,
  );

  /// A copy with the given fields replaced.
  ProfileRecord copyWith({
    FormulaSex? sex,
    int? birthYear,
    double? heightCm,
    HeightInputUnit? heightInputUnit,
    ActivityLevel? activity,
  }) => ProfileRecord(
    sex: sex ?? this.sex,
    birthYear: birthYear ?? this.birthYear,
    heightCm: heightCm ?? this.heightCm,
    heightInputUnit: heightInputUnit ?? this.heightInputUnit,
    activity: activity ?? this.activity,
  );

  /// The content fields, keyed by [TargetWireFields.profile].
  Map<String, Object?> toWire() => {
    'sex': sex.name,
    'birthYear': birthYear,
    'heightCm': heightCm,
    'heightInputUnit': heightInputUnit.code,
    'activity': activity.name,
  };

  @override
  bool operator ==(Object other) =>
      other is ProfileRecord && _sameWire(other.toWire(), toWire());

  @override
  int get hashCode => Object.hashAll(toWire().values);

  @override
  String toString() => 'ProfileRecord';
}

/// One stored goal phase row (TG-012). [revision] is the A12 domain
/// revision, separate from the storage row version. A null [name] means the
/// app's default label. Sensitive: [toString] shows no values.
final class GoalPhaseRecord {
  /// Validation is [TargetRules], not this constructor.
  const new({
    required this.id,
    required this.revision,
    required this.start,
    required this.type,
    required this.expression,
    required this.weightInputUnit,
    this.name,
    this.end,
  });

  /// Decodes a wire map for row [id], or null when [id] isn't a UUIDv7 or
  /// [TargetRules.wire] rejects the map.
  static GoalPhaseRecord? fromWire(String id, Map<String, Object?> wire) {
    if (!isUuidV7(id) || TargetRules.wire.goalPhase(wire).isNotEmpty) {
      return null;
    }
    final targetKg = _double(wire['targetKg']);
    final kgPerWeek = _double(wire['kgPerWeek']);
    final expression = switch (GoalExpressionKind.values.byName(
      wire['expressionKind']! as String,
    )) {
      GoalExpressionKind.targetDate => GoalExpression.targetDate(
        targetKg!,
        _date(wire['targetDate'])!,
      ),
      GoalExpressionKind.targetRate => GoalExpression.targetRate(
        targetKg!,
        kgPerWeek!,
      ),
      GoalExpressionKind.weekly => GoalExpression.weekly(kgPerWeek!),
      GoalExpressionKind.monthly => GoalExpression.monthly(
        _double(wire['monthKg'])!,
        _date(wire['month'])!,
      ),
    };
    return GoalPhaseRecord(
      id: id,
      revision: wire['revision']! as int,
      name: wire['name'] as String?,
      start: _date(wire['startDate'])!,
      end: _date(wire['endDate']),
      type: GoalType.values.byName(wire['goalType']! as String),
      expression: expression,
      weightInputUnit: GoalWeightUnits.ofCode(
        wire['weightInputUnit']! as String,
      )!,
    );
  }

  /// Stands in for a null or blank [name] in [toPhase]. Never displayed:
  /// look the record up by ID for its name.
  static const String placeholderName = 'goal';

  /// Row ID (UUIDv7).
  final String id;

  /// Domain revision (≥ 1).
  final int revision;

  /// User title, or null for the default label. Never logged.
  final String? name;

  /// Inclusive first day.
  final LocalDate start;

  /// Inclusive last day, or null while open.
  final LocalDate? end;

  /// Goal direction.
  final GoalType type;

  /// The user's original expression (canonical kg).
  final GoalExpression expression;

  /// The unit the goal's weights or rates were typed in, `kg` or `lb`
  /// (TD-017); display and editing use it.
  final MassUnit weightInputUnit;

  /// The A12 phase for [GoalHistory]; a null or blank name becomes
  /// [placeholderName].
  GoalPhase toPhase() => GoalPhase(
    id: id,
    name: name == null || name!.trim().isEmpty ? placeholderName : name!,
    version: revision,
    start: start,
    end: end,
    type: type,
    expression: expression,
  );

  /// A copy with the given non-null fields replaced.
  GoalPhaseRecord copyWith({
    String? id,
    int? revision,
    LocalDate? start,
    GoalType? type,
    GoalExpression? expression,
    MassUnit? weightInputUnit,
  }) => GoalPhaseRecord(
    id: id ?? this.id,
    revision: revision ?? this.revision,
    name: name,
    start: start ?? this.start,
    end: end,
    type: type ?? this.type,
    expression: expression ?? this.expression,
    weightInputUnit: weightInputUnit ?? this.weightInputUnit,
  );

  /// A copy with [name] (null: the default label).
  GoalPhaseRecord withName(String? name) => GoalPhaseRecord(
    id: id,
    revision: revision,
    name: name,
    start: start,
    end: end,
    type: type,
    expression: expression,
    weightInputUnit: weightInputUnit,
  );

  /// A copy with [end] (null: open).
  GoalPhaseRecord withEnd(LocalDate? end) => GoalPhaseRecord(
    id: id,
    revision: revision,
    name: name,
    start: start,
    end: end,
    type: type,
    expression: expression,
    weightInputUnit: weightInputUnit,
  );

  /// The content fields, keyed by [TargetWireFields.goalPhase]; exactly the
  /// expression's own fields are non-null. `month` is the month's first day.
  Map<String, Object?> toWire() {
    final e = expression;
    return {
      'revision': revision,
      'name': name,
      'startDate': '$start',
      'endDate': end?.toString(),
      'goalType': type.name,
      'expressionKind': GoalExpressionKind.of(e).name,
      'targetKg': switch (e) {
        TargetDateGoal(:final targetKg) ||
        TargetRateGoal(:final targetKg) => targetKg,
        _ => null,
      },
      'targetDate': e is TargetDateGoal ? '${e.date}' : null,
      'kgPerWeek': switch (e) {
        TargetRateGoal(:final kgPerWeek) ||
        WeeklyGoal(:final kgPerWeek) => kgPerWeek,
        _ => null,
      },
      'monthKg': e is MonthlyGoal ? e.kg : null,
      'month': e is MonthlyGoal
          ? '${LocalDate(e.month.year, e.month.month, 1)}'
          : null,
      'weightInputUnit': weightInputUnit.code,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is GoalPhaseRecord &&
      other.id == id &&
      _sameWire(other.toWire(), toWire());

  @override
  int get hashCode => Object.hash(id, Object.hashAll(toWire().values));

  @override
  String toString() => 'GoalPhaseRecord(revision $revision)';
}

/// One effective-dated target settings version (D5, TD-089): the base
/// (generated or manual), the acknowledgement, the basis weight and the
/// preferences. Floors and daily targets are derived, never stored.
/// Sensitive: [toString] shows no values.
final class TargetSettingsRecord {
  /// Missing [dayFactors] days are NULL (the suggestion). Validation is
  /// [TargetRules].
  new({
    required this.id,
    required this.revision,
    required this.effectiveFrom,
    required this.baseKcal,
    required this.basisWeightKg,
    this.mode = TargetMode.weekly,
    this.rebalancing = true,
    this.manual = false,
    this.acknowledged = false,
    Map<DayOfWeek, double> dayFactors = const {},
    MacroSettings? macros,
  }) : dayFactors = Map.unmodifiable(dayFactors),
       macros = macros ?? MacroSettings();

  /// Decodes a wire map for row [id], or null when [id] isn't a UUIDv7 or
  /// [TargetRules.wire] rejects the map.
  static TargetSettingsRecord? fromWire(String id, Map<String, Object?> wire) {
    if (!isUuidV7(id) || TargetRules.wire.targetSettings(wire).isNotEmpty) {
      return null;
    }
    MacroOverride? macro(String name) {
      final value = _double(wire['${name}Value']);
      if (value == null) return null;
      return wire['${name}IsPercent']! as bool
          ? MacroOverride.percent(value)
          : MacroOverride.grams(value);
    }

    return TargetSettingsRecord(
      id: id,
      revision: wire['revision']! as int,
      effectiveFrom: _date(wire['effectiveFrom'])!,
      mode: TargetMode.values.byName(wire['mode']! as String),
      rebalancing: wire['rebalancing']! as bool,
      baseKcal: _double(wire['baseKcal'])!,
      manual: wire['manual']! as bool,
      acknowledged: wire['acknowledged']! as bool,
      basisWeightKg: _double(wire['basisWeightKg'])!,
      dayFactors: {
        for (final MapEntry(key: day, value: field)
            in TargetWireFields.shifts.entries)
          day: ?_double(wire[field]),
      },
      macros: MacroSettings(
        protein: macro('protein'),
        fat: macro('fat'),
        carbs: macro('carbs'),
        fiberGrams: _double(wire['fiberG']),
        caloriesProteinOnly: wire['caloriesProteinOnly']! as bool,
      ),
    );
  }

  /// Row ID (UUIDv7).
  final String id;

  /// Domain revision (≥ 1).
  final int revision;

  /// Inclusive first day this version applies.
  final LocalDate effectiveFrom;

  /// Weekly budget or the same every day.
  final TargetMode mode;

  /// Whether earlier intake rebalances the remaining days.
  final bool rebalancing;

  /// The stored daily base, unrounded (generated or manual).
  final double baseKcal;

  /// Whether [baseKcal] is the user's own target.
  final bool manual;

  /// Whether the user acknowledged a below-limit manual target (SF-012).
  final bool acknowledged;

  /// The weight the base was computed with (TG-021 reproduction, D5).
  final double basisWeightKg;

  /// Each weekday's number as a factor of the suggestion (D-090, A53 D1),
  /// stored in the `shift*` wire fields; a missing day is NULL (the
  /// suggestion). Unmodifiable.
  final Map<DayOfWeek, double> dayFactors;

  /// Macro preferences (TG-054).
  final MacroSettings macros;

  /// The A12 PA6 ordering key.
  SettingsVersionKey get key =>
      (id: id, revision: revision, effectiveFrom: effectiveFrom);

  /// The factors the engine uses: a NULL or unsupported (outside
  /// [TargetLimits.minDayFactor]–[TargetLimits.maxDayFactor], e.g. a synced
  /// outlier) factor reads as the suggestion.
  Map<DayOfWeek, double> get factors => {
    for (final MapEntry(key: day, value: factor) in dayFactors.entries)
      if (TargetLimits.isDayFactor(factor)) day: factor,
  };

  /// Whether a base below the floor may stand: an acknowledged manual fixed
  /// target (A12 PA1, SF-012).
  bool get mayStayBelowFloor =>
      manual && acknowledged && mode == TargetMode.fixed;

  /// The A12 plan against [floorKcal] (recomputed for the date, never
  /// stored). A base below the floor is raised to it unless
  /// [mayStayBelowFloor] (D6).
  TargetPlan toPlan(double floorKcal) => TargetPlan(
    baseKcal: baseKcal < floorKcal && !mayStayBelowFloor ? floorKcal : baseKcal,
    floorKcal: floorKcal,
    mode: mode,
    rebalancing: rebalancing,
    manual: manual,
    acknowledged: acknowledged,
    dayFactors: factors,
    macros: macros,
  );

  /// A copy with the given fields replaced. [dayFactors] replaces the whole
  /// map.
  TargetSettingsRecord copyWith({
    String? id,
    int? revision,
    LocalDate? effectiveFrom,
    TargetMode? mode,
    bool? rebalancing,
    double? baseKcal,
    bool? manual,
    bool? acknowledged,
    double? basisWeightKg,
    Map<DayOfWeek, double>? dayFactors,
    MacroSettings? macros,
  }) => TargetSettingsRecord(
    id: id ?? this.id,
    revision: revision ?? this.revision,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    mode: mode ?? this.mode,
    rebalancing: rebalancing ?? this.rebalancing,
    baseKcal: baseKcal ?? this.baseKcal,
    manual: manual ?? this.manual,
    acknowledged: acknowledged ?? this.acknowledged,
    basisWeightKg: basisWeightKg ?? this.basisWeightKg,
    dayFactors: dayFactors ?? this.dayFactors,
    macros: macros ?? this.macros,
  );

  /// The content fields, keyed by [TargetWireFields.targetSettings].
  Map<String, Object?> toWire() {
    final overrides = [macros.protein, macros.fat, macros.carbs];
    return {
      'revision': revision,
      'effectiveFrom': '$effectiveFrom',
      'mode': mode.name,
      'rebalancing': rebalancing,
      'baseKcal': baseKcal,
      'manual': manual,
      'acknowledged': acknowledged,
      'basisWeightKg': basisWeightKg,
      for (final MapEntry(key: day, value: field)
          in TargetWireFields.shifts.entries)
        field: dayFactors[day],
      for (final (i, name) in TargetWireFields.macros.indexed) ...{
        '${name}Value': overrides[i]?.value,
        '${name}IsPercent': overrides[i]?.isPercent,
      },
      'fiberG': macros.fiberGrams,
      'caloriesProteinOnly': macros.caloriesProteinOnly,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is TargetSettingsRecord &&
      other.id == id &&
      _sameWire(other.toWire(), toWire());

  @override
  int get hashCode => Object.hash(id, Object.hashAll(toWire().values));

  @override
  String toString() => 'TargetSettingsRecord(revision $revision)';
}

/// The D5 revision rule for a change effective today.
abstract final class TargetSettingsRevision {
  /// Applies [change] to [current] (the version in effect today, at row
  /// version [currentVersion]). When [current] is effective [today], the
  /// result revises that row (`revision + 1`, expected version); otherwise
  /// it is a new row [newId] effective [today] (revision 1, inserted)
  /// copying every field [change] leaves alone.
  static ({TargetSettingsRecord record, int? expectedVersion}) next({
    required TargetSettingsRecord current,
    required int currentVersion,
    required LocalDate today,
    required String newId,
    required TargetSettingsRecord Function(TargetSettingsRecord) change,
  }) {
    final changed = change(current);
    return current.effectiveFrom == today
        ? (
            record: changed.copyWith(
              id: current.id,
              revision: current.revision + 1,
              effectiveFrom: today,
            ),
            expectedVersion: currentVersion,
          )
        : (
            record: changed.copyWith(
              id: newId,
              revision: 1,
              effectiveFrom: today,
            ),
            expectedVersion: null,
          );
  }
}

double? _double(Object? value) => (value as num?)?.toDouble();

LocalDate? _date(Object? value) =>
    value == null ? null : LocalDate.parse(value as String);

bool _sameWire(Map<String, Object?> a, Map<String, Object?> b) =>
    a.length == b.length && a.keys.every((key) => a[key] == b[key]);
