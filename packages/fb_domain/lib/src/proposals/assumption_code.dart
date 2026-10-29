import 'package:fb_domain/src/food/food_state.dart';
import 'package:fb_domain/src/nutrition/yield.dart';
import 'package:fb_domain/src/proposals/proposal_input.dart'
    show ProposalChoiceOrigin;

/// A versioned assumption code stored in `Provenance.assumptions` (A21 PA3,
/// TD-084, A22 D17): the engine writes these and the app shows them as
/// localized text. One grammar, written and read here:
///
/// - `a1:yield:<fromState>:<toState>:<fromG>:<toG>`: a weighed state was
///   converted ([YieldAssumption]);
/// - `a1:oil:all|most`: how much of the cooking oil counts ([OilAssumption]);
/// - `a1:share:<n>/<d>`: the eaten share of a dish, decimals allowed
///   (`0.5/1`, `1/3`; [ShareAssumption]);
/// - `a1:origin:stated|savedDefault|fallback|userAdjusted`: where a choice
///   came from ([OriginAssumption]).
///
/// Anything else (an unknown kind or version, malformed fields, legacy raw
/// text) parses to null; the app then shows a generic label, never the raw
/// string.
sealed class AssumptionCode {
  const new _();

  /// The stored code.
  String get code;

  /// [raw] read back, or null when it isn't a known `a1:` code.
  static AssumptionCode? parse(String raw) {
    final parts = raw.split(':');
    if (parts.length < 3 || parts.first != 'a1') return null;
    final fields = parts.sublist(2);
    return switch (parts[1]) {
      'yield' => YieldAssumption._parse(fields),
      'oil' => OilAssumption._parse(fields),
      'share' => ShareAssumption._parse(fields),
      'origin' => OriginAssumption._parse(fields),
      _ => null,
    };
  }

  @override
  String toString() => code;
}

/// A weighed [fromState] amount counted as [toState] (yield conversion).
final class YieldAssumption extends AssumptionCode {
  /// [fromGrams] of [fromState] counted as [toGrams] of [toState].
  const new({
    required this.fromState,
    required this.toState,
    required this.fromGrams,
    required this.toGrams,
  }) : super._();

  /// The code of an engine yield note.
  factory of(YieldNote note) => YieldAssumption(
    fromState: note.fromState,
    toState: note.toState,
    fromGrams: note.fromAmount.grams,
    toGrams: note.toAmount.grams,
  );

  /// The state as weighed.
  final FoodState fromState;

  /// The state the nutrients are for.
  final FoodState toState;

  /// Grams as weighed.
  final double fromGrams;

  /// Grams counted.
  final double toGrams;

  static YieldAssumption? _parse(List<String> f) {
    if (f.length != 4) return null;
    final from = _state(f[0]);
    final to = _state(f[1]);
    final fromG = _positive(f[2]);
    final toG = _positive(f[3]);
    if (from == null || to == null || fromG == null || toG == null) {
      return null;
    }
    return YieldAssumption(
      fromState: from,
      toState: to,
      fromGrams: fromG,
      toGrams: toG,
    );
  }

  @override
  String get code =>
      'a1:yield:${fromState.code}:${toState.code}:$fromGrams:$toGrams';

  @override
  bool operator ==(Object other) =>
      other is YieldAssumption &&
      other.fromState == fromState &&
      other.toState == toState &&
      other.fromGrams == fromGrams &&
      other.toGrams == toGrams;

  @override
  int get hashCode => Object.hash(fromState, toState, fromGrams, toGrams);
}

/// How much of the cooking oil counts: [all], or most of it (some stays in
/// the pan).
final class OilAssumption extends AssumptionCode {
  /// All of the oil when [all], else most.
  const new({required this.all}) : super._();

  /// All of the oil counts.
  final bool all;

  static OilAssumption? _parse(List<String> f) => f.length != 1
      ? null
      : switch (f.single) {
          'all' => const OilAssumption(all: true),
          'most' => const OilAssumption(all: false),
          _ => null,
        };

  @override
  String get code => 'a1:oil:${all ? 'all' : 'most'}';

  @override
  bool operator ==(Object other) => other is OilAssumption && other.all == all;

  @override
  int get hashCode => all.hashCode;
}

/// The eaten share of a dish: [numerator] / [denominator] (≤ 1). The
/// engine writes a fraction as `<fraction>/1` and a split between people as
/// `1/<people>`.
final class ShareAssumption extends AssumptionCode {
  const new _(this.numerator, this.denominator, this._text) : super._();

  /// [fraction] of the dish (0 < fraction ≤ 1).
  new fraction(double fraction) : this._(fraction, 1, '$fraction/1');

  /// One of [people] equal shares.
  new people(int people) : this._(1, people.toDouble(), '1/$people');

  /// The share's numerator.
  final double numerator;

  /// The share's denominator.
  final double denominator;

  final String _text;

  /// The share as a fraction of the dish.
  double get share => numerator / denominator;

  static ShareAssumption? _parse(List<String> f) {
    if (f.length != 1) return null;
    final halves = f.single.split('/');
    if (halves.length != 2 ||
        !_decimal.hasMatch(halves[0]) ||
        !_decimal.hasMatch(halves[1])) {
      return null;
    }
    final n = _positive(halves[0]);
    final d = _positive(halves[1]);
    if (n == null || d == null || n > d) return null;
    return ShareAssumption._(n, d, f.single);
  }

  @override
  String get code => 'a1:share:$_text';

  @override
  bool operator ==(Object other) =>
      other is ShareAssumption &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);
}

/// Where a selected option came from.
final class OriginAssumption extends AssumptionCode {
  /// The [origin] code.
  const new(this.origin) : super._();

  /// The origin.
  final ProposalChoiceOrigin origin;

  static OriginAssumption? _parse(List<String> f) {
    if (f.length != 1) return null;
    for (final origin in ProposalChoiceOrigin.values) {
      if (origin.name == f.single) return OriginAssumption(origin);
    }
    return null;
  }

  @override
  String get code => 'a1:origin:${origin.name}';

  @override
  bool operator ==(Object other) =>
      other is OriginAssumption && other.origin == origin;

  @override
  int get hashCode => origin.hashCode;
}

FoodState? _state(String code) {
  for (final state in FoodState.values) {
    if (state.code == code) return state;
  }
  return null;
}

/// The one number grammar of the codes: plain decimals.
final _decimal = RegExp(r'^[0-9]+(\.[0-9]+)?$');

/// [text] as a number in (0, 100000], else null: an overlong or absurd
/// stored value shows the generic label instead of a huge or infinite
/// mass (A22a review).
double? _positive(String text) {
  if (!_decimal.hasMatch(text)) return null;
  final value = double.parse(text);
  return value.isFinite && value > 0 && value <= 100000 ? value : null;
}
