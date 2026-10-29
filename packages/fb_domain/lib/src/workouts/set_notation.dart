import 'package:fb_domain/src/units/units.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';

/// How a parsed load relates to the lifter (WO-004, WO-031).
enum LoadKind {
  /// A plain weight (`80`): the bar, the stack or one dumbbell.
  weight,

  /// Added to bodyweight (`+10`): weighted dips, pull-ups.
  added,

  /// Assistance taken off bodyweight (`-20`): assisted machines.
  assistance,
}

/// One set read from a shorthand notation (WO-031).
///
/// [kg] is the typed weight converted exactly; for a dumbbell exercise it is
/// the weight of one dumbbell, never doubled (WO-005). The parser doesn't
/// know the exercise: the caller checks [values] against its type.
final class ParsedSet {
  /// A set as parsed.
  const new({
    this.reps,
    this.inputWeight,
    this.unit,
    this.load,
    this.durationSeconds,
    this.distanceMeters,
  });

  /// Repetitions, if the notation had them.
  final int? reps;

  /// The weight as typed, without its sign.
  final double? inputWeight;

  /// The unit [inputWeight] is in.
  final MassUnit? unit;

  /// What the weight means.
  final LoadKind? load;

  /// Duration in seconds (time and cardio sets).
  final int? durationSeconds;

  /// Distance in metres (cardio sets).
  final double? distanceMeters;

  /// The weight in kg, converted exactly from [inputWeight] and [unit].
  double? get kg {
    final weight = inputWeight;
    final unit = this.unit;
    if (weight == null || unit == null) return null;
    return weight * unit.grams / MassUnit.kilogram.grams;
  }

  /// The canonical values to store (WO-004).
  SetValues get values => SetValues(
    reps: reps,
    kg: kg,
    durationSeconds: durationSeconds,
    distanceMeters: distanceMeters,
  );

  @override
  bool operator ==(Object other) =>
      other is ParsedSet &&
      other.reps == reps &&
      other.inputWeight == inputWeight &&
      other.unit == unit &&
      other.load == load &&
      other.durationSeconds == durationSeconds &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(
    reps,
    inputWeight,
    unit,
    load,
    durationSeconds,
    distanceMeters,
  );

  @override
  String toString() =>
      'ParsedSet(reps: $reps, w: $inputWeight ${unit?.code}, $load, '
      's: $durationSeconds, m: $distanceMeters)';
}

/// Why a notation couldn't be read. Content-free.
enum SetNotationIssue {
  /// Nothing after the exercise name.
  empty,

  /// The text doesn't match any supported shape.
  unrecognized,

  /// Both kg and lb appear.
  mixedUnits,

  /// A count, weight, duration or distance is out of range.
  outOfRange,
}

/// The outcome of [SetNotationParser.parse].
sealed class SetNotationResult {
  const new();
}

/// A notation that was read.
final class SetNotationParsed extends SetNotationResult {
  /// [sets] in order, with the free text before them as [name].
  const new({required this.sets, this.name});

  /// The text before the first number (an exercise name to match), trimmed
  /// and lower-cased, or `null`.
  final String? name;

  /// The sets, in order, at least one.
  final List<ParsedSet> sets;
}

/// A notation that couldn't be read.
final class SetNotationRejected extends SetNotationResult {
  /// Rejected for [issue].
  const new(this.issue);

  /// Why.
  final SetNotationIssue issue;
}

/// Reads set shorthand (WO-031, A36 D2). Pure; also cross-checks what the
/// model returned (AQ-03).
///
/// Shapes (after an optional exercise name, `x` = `x`/`×`/`*`):
/// `3x8 80`, `3x8@80`, `3x8` · `80x8x3` (weight × reps × sets) ·
/// `8,8,7 @80` · `80x8, 85x6, 85x5` · `+10 3x8`, `3x8 +10` (added load),
/// `-20 3x8` (assistance) · `80 3x8` · `3 sets of 8 at 80` · durations
/// `60s`, `3x45s`, `30 min`, `30 min 5 km`. Units `kg`/`lb` anywhere, else
/// the default unit. `AxB` without a weight is sets × reps when A ≤ 10 and
/// has no unit, sign or decimal, else weight × reps (`80x8`); a unit marks
/// a weight (`5kgx8`) and `N sets of R` is always sets × reps.
abstract final class SetNotationParser {
  /// Reads [text]; weights without a unit are in [defaultUnit].
  static SetNotationResult parse(
    String text, {
    MassUnit defaultUnit = MassUnit.kilogram,
  }) {
    var s = text
        .toLowerCase()
        .replaceAll(RegExp('[×*]'), 'x')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final start = RegExp(r'(?:^|\s)[+\-]?\d').firstMatch(s);
    if (start == null) return const SetNotationRejected(SetNotationIssue.empty);
    final name = s.substring(0, start.start).trim();
    s = s.substring(start.start).trim();

    final duration = _parseDuration(s);
    if (duration != null) {
      return duration.isEmpty ? _outOfRange : _done(name, duration);
    }

    // Units: remember them, and mark the number they follow as a weight
    // (`w`), so `5kgx8` stays one 5 kg set of 8.
    final units = <MassUnit>{};
    s = s.replaceAllMapped(_unitWord, (m) {
      units.add(m[2]!.startsWith('k') ? MassUnit.kilogram : MassUnit.pound);
      return '${m[1]}w';
    });
    if (units.length > 1) {
      return const SetNotationRejected(SetNotationIssue.mixedUnits);
    }
    final unit = units.isEmpty ? defaultUnit : units.single;
    if (unit != MassUnit.kilogram && unit != MassUnit.pound) {
      throw ArgumentError.value(defaultUnit, 'defaultUnit', 'kg or lb only');
    }
    s = s
        // `N sets of R` is always sets × reps: its own operator `#`.
        .replaceAll(RegExp(r'\s*\bsets? of\b\s*'), ' # ')
        .replaceAll(RegExp(r'\breps?\b'), ' ')
        .replaceAll(RegExp(r'\bat\b'), '@')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final sets = <ParsedSet>[];
    final list = _repsList.firstMatch(s);
    if (list != null) {
      final load = list[2] == null ? null : _Load.of(list[2]!);
      for (final reps in list[1]!.split(',')) {
        final set = _set(int.parse(reps.trim()), load, unit);
        if (set == null) return _outOfRange;
        sets.add(set);
      }
      return _done(name, sets);
    }
    for (final group in s.split(',')) {
      final parsed = _group(group.trim(), unit);
      if (parsed == null) {
        return const SetNotationRejected(SetNotationIssue.unrecognized);
      }
      if (parsed.isEmpty) return _outOfRange;
      sets.addAll(parsed);
    }
    return _done(name, sets);
  }

  static const _num = r'\d+(?:\.\d+)?';
  // A weight: optional sign, number, optional `w` (it had a unit).
  static const _load = '[+\\-]?$_num(?:w)?';
  static const _sep = r'(?:\s*@\s*|\s+)';

  static final _unitWord = RegExp(
    // Not followed by a letter, except the `x` of `80kgx8x3`.
    r'(\d)\s*(kgs?|kilos?|kilograms?|lbs?|pounds?)(?![a-wyz])',
  );
  static final _repsList = RegExp(
    '^(\\d+(?:\\s*,\\s*\\d+)+)(?:$_sep($_load))?\$',
  );
  static final _weightRepsSets = RegExp(
    '^($_num(?:w)?)\\s*x\\s*(\\d+)\\s*x\\s*($_num(?:w)?)\$',
  );
  static final _setsRepsLoad = RegExp(
    '^(\\d+)\\s*(x|#)\\s*(\\d+)(?:$_sep($_load))?\$',
  );
  static final _loadSetsReps = RegExp(
    '^(?:@\\s*)?($_load)\\s+(\\d+)\\s*x\\s*(\\d+)\$',
  );
  static final _loadReps = RegExp('^($_load)\\s*x\\s*(\\d+)\$');
  static final _repsOnly = RegExp(r'^(\d+)$');

  static final _durationShape = RegExp(
    r'^(?:(\d+)\s*x\s*)?(\d+(?:\.\d+)?)\s*'
    r'(s|secs?|seconds?|min|mins|minutes?|h|hrs?|hours?)\b'
    r'(?:\s+(\d+(?:\.\d+)?)\s*(km|m)\b)?$',
  );

  static const _outOfRange = SetNotationRejected(SetNotationIssue.outOfRange);

  static SetNotationResult _done(String name, List<ParsedSet> sets) {
    if (sets.isEmpty) return const SetNotationRejected(SetNotationIssue.empty);
    if (sets.length > WorkoutSetBounds.maxSets) return _outOfRange;
    return SetNotationParsed(
      sets: List.unmodifiable(sets),
      name: name.isEmpty ? null : name,
    );
  }

  // `null` when [s] isn't a duration; an empty list when it is but out of
  // range.
  static List<ParsedSet>? _parseDuration(String s) {
    final m = _durationShape.firstMatch(s);
    if (m == null) return null;
    final count = m[1] == null ? 1 : int.parse(m[1]!);
    final amount = double.parse(m[2]!);
    final unit = m[3]!;
    final factor = unit.startsWith('h')
        ? 3600
        : unit.startsWith('m')
        ? 60
        : 1;
    final seconds = (amount * factor).round();
    final distance = m[4] == null
        ? null
        : double.parse(m[4]!) * (m[5] == 'km' ? 1000 : 1);
    if (count < 1 ||
        count > WorkoutSetBounds.maxSets ||
        seconds < 1 ||
        seconds > WorkoutSetBounds.maxDurationSeconds ||
        (distance != null &&
            (distance <= 0 || distance > WorkoutSetBounds.maxDistanceMeters))) {
      return const [];
    }
    return List.filled(
      count,
      ParsedSet(durationSeconds: seconds, distanceMeters: distance),
    );
  }

  // `null` when unrecognized, an empty list when out of range.
  static List<ParsedSet>? _group(String g, MassUnit unit) {
    if (_weightRepsSets.firstMatch(g) case final m?) {
      final first = m[1]!;
      final reps = int.parse(m[2]!);
      final last = m[3]!;
      // `3x8x80` / `3x8x80kg`: sets × reps × weight, when the last is marked
      // as a weight or can't be a set count and the first is a plain count.
      final firstPlain = RegExp(r'^\d+$').hasMatch(first);
      final lastPlain = RegExp(r'^\d+$').hasMatch(last);
      if (firstPlain &&
          (last.endsWith('w') ||
              (!lastPlain && !first.endsWith('w')) ||
              (lastPlain && int.parse(last) > WorkoutSetBounds.maxSets))) {
        return _repeat(int.parse(first), reps, _Load.of(last), unit);
      }
      if (!lastPlain) return null;
      return _repeat(int.parse(last), reps, _Load.of(first), unit);
    }
    if (_setsRepsLoad.firstMatch(g) case final m?) {
      final a = int.parse(m[1]!);
      final b = int.parse(m[3]!);
      if (m[4] != null) return _repeat(a, b, _Load.of(m[4]!), unit);
      // Only a genuinely bare `AxB` (no unit, sign or decimal) is ambiguous.
      if (m[2] == '#' || a <= 10) return _repeat(a, b, null, unit);
      return _repeat(1, b, _Load.of(m[1]!), unit);
    }
    if (_loadSetsReps.firstMatch(g) case final m?) {
      return _repeat(int.parse(m[2]!), int.parse(m[3]!), _Load.of(m[1]!), unit);
    }
    if (_loadReps.firstMatch(g) case final m?) {
      return _repeat(1, int.parse(m[2]!), _Load.of(m[1]!), unit);
    }
    if (_repsOnly.firstMatch(g) case final m?) {
      return _repeat(1, int.parse(m[1]!), null, unit);
    }
    return null;
  }

  static List<ParsedSet> _repeat(
    int count,
    int reps,
    _Load? load,
    MassUnit unit,
  ) {
    if (count < 1 || count > WorkoutSetBounds.maxSets) return const [];
    final set = _set(reps, load, unit);
    return set == null ? const [] : List.filled(count, set);
  }

  static ParsedSet? _set(int reps, _Load? load, MassUnit unit) {
    if (reps < WorkoutSetBounds.minReps || reps > WorkoutSetBounds.maxReps) {
      return null;
    }
    if (load == null) return ParsedSet(reps: reps);
    final kg = load.value * unit.grams / MassUnit.kilogram.grams;
    if (kg > WorkoutSetBounds.maxKg ||
        (load.kind == LoadKind.weight && kg <= 0)) {
      return null;
    }
    return ParsedSet(
      reps: reps,
      inputWeight: load.value,
      unit: unit,
      load: load.kind,
    );
  }
}

final class _Load {
  const new(this.value, this.kind);

  factory of(String token) {
    final kind = switch (token[0]) {
      '+' => LoadKind.added,
      '-' => LoadKind.assistance,
      _ => LoadKind.weight,
    };
    var digits = kind == LoadKind.weight ? token : token.substring(1);
    if (digits.endsWith('w')) digits = digits.substring(0, digits.length - 1);
    return _Load(double.parse(digits), kind);
  }

  final double value;
  final LoadKind kind;
}
