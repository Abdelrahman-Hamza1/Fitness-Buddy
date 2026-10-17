/// The source badge of a logged item (FD-010, SC-4, `spec/11` §2). Stored
/// as `source`, separate from the food kind: a catalog food can be
/// `database` or `reference`.
enum FoodSource {
  /// ⓨ yours: personal foods, label scans, saved meals, batch dishes, values
  /// edited by the user.
  yours('yours'),

  /// ⓓ database: verified generic and branded food data.
  database('database'),

  /// ⓡ reference dish: reviewed recipes for local and mixed dishes.
  reference('reference'),

  /// ~ estimate: an AI estimate when nothing else matches.
  estimate('estimate');

  new(this.code);

  /// The stable code stored in `source`.
  final String code;

  /// The source whose [code] is exactly [code], or `null`.
  static FoodSource? fromCode(String code) {
    for (final source in values) {
      if (source.code == code) return source;
    }
    return null;
  }
}

/// The kcal range of an estimate (FD-010: "range shown").
final class EstimateRange {
  /// From [lowKcal] to [highKcal], both finite and not negative, low ≤ high.
  /// Throws an `ArgumentError` otherwise.
  new(this.lowKcal, this.highKcal) {
    for (final (value, name) in [
      (lowKcal, 'lowKcal'),
      (highKcal, 'highKcal'),
    ]) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError.value(value, name, 'must be finite and >= 0');
      }
    }
    if (lowKcal > highKcal) {
      throw ArgumentError.value(lowKcal, 'lowKcal', 'must be <= highKcal');
    }
  }

  /// The low end, kcal.
  final double lowKcal;

  /// The high end, kcal.
  final double highKcal;

  @override
  bool operator ==(Object other) =>
      other is EstimateRange &&
      other.lowKcal == lowKcal &&
      other.highKcal == highKcal;

  @override
  int get hashCode => Object.hash(lowKcal, highKcal);

  @override
  String toString() => 'EstimateRange(range)';
}

/// Where a logged item's values come from (A06 D5, `05` §1): the badge,
/// whether it is an estimate, its range and the assumptions behind it.
/// Whether the user edited the values (`edited_by_user`) is a row field the
/// ops set, not part of this.
final class Provenance {
  /// Values from [source]. An estimate [source] implies [isEstimate]; a
  /// [range] needs [isEstimate]. Throws an `ArgumentError` otherwise.
  new({
    required this.source,
    bool? isEstimate,
    this.range,
    Iterable<String> assumptions = const [],
  }) : isEstimate = isEstimate ?? source == FoodSource.estimate,
       assumptions = List.unmodifiable(assumptions) {
    if (source == FoodSource.estimate && !this.isEstimate) {
      throw ArgumentError.value(
        isEstimate,
        'isEstimate',
        'an estimate source is an estimate',
      );
    }
    if (range != null && !this.isEstimate) {
      throw ArgumentError('only an estimate has a range');
    }
  }

  /// The badge.
  final FoodSource source;

  /// Whether the values are estimated (always marked in the UI).
  final bool isEstimate;

  /// The estimate's kcal range, when it has one.
  final EstimateRange? range;

  /// The assumptions behind the values (AI-033 chips), in order. User and
  /// model text: never logged. Unmodifiable.
  final List<String> assumptions;

  @override
  bool operator ==(Object other) {
    if (other is! Provenance ||
        other.source != source ||
        other.isEstimate != isEstimate ||
        other.range != range ||
        other.assumptions.length != assumptions.length) {
      return false;
    }
    for (var i = 0; i < assumptions.length; i++) {
      if (other.assumptions[i] != assumptions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(source, isEstimate, range, Object.hashAll(assumptions));

  /// Without the assumptions' text.
  @override
  String toString() =>
      'Provenance(${source.code}${isEstimate ? ', estimate' : ''}'
      '${range == null ? '' : ', $range'}, '
      '${assumptions.length} assumptions)';
}
