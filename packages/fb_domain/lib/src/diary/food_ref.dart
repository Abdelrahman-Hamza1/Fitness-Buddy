/// What kind of food a diary entry was logged from (A06 D3). Stored as
/// `food_kind`. A27 adds `batch` as a new text value.
enum FoodRefKind {
  /// A food of the bundled catalog pack (generic, branded or reference dish).
  catalog('catalog'),

  /// One of the user's own foods.
  personal('personal'),

  /// An AI estimate with no food behind it (FD-010 "~ estimate").
  estimate('estimate');

  new(this.code);

  /// The stable code stored in `food_kind`.
  final String code;

  /// The kind whose [code] is exactly [code], or `null` for a code this
  /// version doesn't know (a newer app may have written it, e.g. `batch`).
  static FoodRefKind? fromCode(String code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// Which food an entry came from (A06 D3): the kind, an **opaque** stable
/// ID and, for catalog foods, the pack version at log time. Nothing in the
/// diary parses or joins on these: they serve "log again" and provenance.
/// The entry's values never come from the food again (FD-073).
final class FoodRef {
  /// A reference of [kind] to [id] at [version]. Only an estimate may have
  /// no [id]. [id] and [version] are non-empty when present. Throws an
  /// `ArgumentError` otherwise.
  new(this.kind, {this.id, this.version}) {
    if (id == null && kind != FoodRefKind.estimate) {
      throw ArgumentError.value(id, 'id', 'is required for ${kind.code}');
    }
    if (id?.isEmpty ?? false) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (version?.isEmpty ?? false) {
      throw ArgumentError.value(version, 'version', 'must not be empty');
    }
  }

  /// Catalog food [id] of the pack whose `catalog_version` is [version].
  new catalog(String id, {required String version})
    : this(FoodRefKind.catalog, id: id, version: version);

  /// The user's own food [id].
  new personal(String id) : this(FoodRefKind.personal, id: id);

  /// An AI estimate (no food behind it).
  new estimate() : this(FoodRefKind.estimate);

  /// The kind of food.
  final FoodRefKind kind;

  /// The food's opaque ID, or `null` for an estimate.
  final String? id;

  /// The opaque catalog pack version at log time, or `null`.
  final String? version;

  @override
  bool operator ==(Object other) =>
      other is FoodRef &&
      other.kind == kind &&
      other.id == id &&
      other.version == version;

  @override
  int get hashCode => Object.hash(kind, id, version);

  @override
  String toString() => 'FoodRef(${kind.code}, $id, $version)';
}
