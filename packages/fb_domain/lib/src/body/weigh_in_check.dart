import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/units/units.dart';

/// What [WeighInCheck.check] found. Content-free `toString`.
sealed class WeighInCheckResult {
  const new _();
}

/// Nothing unusual: save without asking.
final class Plausible extends WeighInCheckResult {
  /// The one value.
  const new() : super._();

  @override
  bool operator ==(Object other) => other is Plausible;

  @override
  int get hashCode => (Plausible).hashCode;

  @override
  String toString() => 'Plausible';
}

/// The number reads like the other unit (WB-005): 214 "kg" after 97 kg is
/// likely 214 lb.
final class LikelyOtherUnit extends WeighInCheckResult {
  /// [suggestedUnit] gives [suggestedKg], close to [reference].
  const new({
    required this.suggestedUnit,
    required this.suggestedKg,
    required this.reference,
  }) : super._();

  /// The unit the number likely meant.
  final MassUnit suggestedUnit;

  /// The typed number in [suggestedUnit], in kg (storage precision).
  final double suggestedKg;

  /// The weigh-in it was compared with.
  final WeighIn reference;

  @override
  bool operator ==(Object other) =>
      other is LikelyOtherUnit &&
      other.suggestedUnit == suggestedUnit &&
      other.suggestedKg == suggestedKg &&
      other.reference == reference;

  @override
  int get hashCode =>
      Object.hash(LikelyOtherUnit, suggestedUnit, suggestedKg, reference);

  @override
  String toString() => 'LikelyOtherUnit(${suggestedUnit.code})';
}

/// More than 3 % from a weigh-in within 7 days (WB-005).
final class LargeChange extends WeighInCheckResult {
  /// [diffKg] (new − reference) from [reference].
  const new({required this.reference, required this.diffKg}) : super._();

  /// The weigh-in it was compared with.
  final WeighIn reference;

  /// The new value minus the reference's, in kg (storage precision).
  final double diffKg;

  @override
  bool operator ==(Object other) =>
      other is LargeChange &&
      other.reference == reference &&
      other.diffKg == diffKg;

  @override
  int get hashCode => Object.hash(LargeChange, reference, diffKg);

  @override
  String toString() => 'LargeChange';
}

/// The implausible-value check before saving a weigh-in (WB-005, A14 D4).
/// A29 reuses it for chat and import rows.
abstract final class WeighInCheck {
  /// A reading in the other unit "matches" within this relative distance.
  static const double unitMatch = 0.05;

  /// …and the typed reading must be further than this from the reference.
  static const double unitMismatch = 0.25;

  /// A change above this relative size asks for confirmation (strictly
  /// more than 3 %).
  static const double largeChange = 0.03;

  /// The large-change reference must be at most this many days away (by
  /// local date).
  static const int largeChangeDays = 7;

  /// Absorbs binary noise at the thresholds (97.0 → 99.91 is 3.0 %).
  static const double _tolerance = 1e-9;

  /// Checks [candidate] against [others] (live weigh-ins; rows that aren't
  /// [WeighIn.isReadable] and the row [editingId], the one being edited,
  /// are ignored).
  ///
  /// 1. **Unit mix-up** against the nearest weigh-in in time (at or before
  ///    the candidate's time first, else the next later one): read in the
  ///    other unit the number is within ±5 % of it, read as typed more
  ///    than 25 % away.
  /// 2. **Large change** against the nearest earlier weigh-in at most 7
  ///    days back, else the nearest later one at most 7 days ahead (a
  ///    backfill): more than 3 % apart.
  ///
  /// A candidate whose input is invalid ([WeighInInput.validate]) is
  /// [Plausible] here: the bounds are its own message.
  static WeighInCheckResult check({
    required WeighInDraft candidate,
    required Iterable<WeighIn> others,
    String? editingId,
  }) {
    if (candidate.input.validate() != null) return const Plausible();
    final refs = [
      for (final weighIn in others)
        if (weighIn.id != editingId && weighIn.isReadable) weighIn,
    ]..sort(_byTime);
    final at = candidate.time.occurredAtUtc;
    final atOrBefore = refs.where((w) => !w.time.occurredAtUtc.isAfter(at));
    final after = refs.where((w) => w.time.occurredAtUtc.isAfter(at));
    final earlier = atOrBefore.isEmpty ? null : atOrBefore.last;
    final later = after.isEmpty ? null : after.first;
    final kg = candidate.kg;

    if (earlier ?? later case final nearest?) {
      final input = candidate.input;
      final otherUnit = input.unit == MassUnit.pound
          ? MassUnit.kilogram
          : MassUnit.pound;
      final other = WeighInInput(input.value, otherUnit);
      if (other.validate() == null &&
          _relative(other.kg, nearest.kg) <= unitMatch + _tolerance &&
          _relative(kg, nearest.kg) > unitMismatch + _tolerance) {
        return LikelyOtherUnit(
          suggestedUnit: otherUnit,
          suggestedKg: other.kg,
          reference: nearest,
        );
      }
    }

    final day = candidate.localDate;
    final reference =
        earlier != null && earlier.localDate.daysUntil(day) <= largeChangeDays
        ? earlier
        : later != null && day.daysUntil(later.localDate) <= largeChangeDays
        ? later
        : null;
    if (reference != null &&
        _relative(kg, reference.kg) > largeChange + _tolerance) {
      return LargeChange(
        reference: reference,
        diffKg: StoragePrecision.round(kg - reference.kg),
      );
    }
    return const Plausible();
  }

  static double _relative(double value, double reference) =>
      (value - reference).abs() / reference;

  static int _byTime(WeighIn a, WeighIn b) {
    final byTime = a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }
}
