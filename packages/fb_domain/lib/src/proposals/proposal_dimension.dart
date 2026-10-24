part of 'proposal_input.dart';

/// Shared ambiguity vocabulary for future proposal kinds.
enum ProposalDimensionKind {
  /// Stated versus matched food state.
  state,

  /// Added cooking fat.
  fat,

  /// Food/reference variant.
  variant,

  /// Portion size.
  portion,

  /// Fraction of stated oil retained.
  oilRetention,

  /// Fraction of a shared dish.
  share,
}

/// Source of a dimension selection.
enum ProposalChoiceOrigin {
  /// Stated in interpretation.
  stated,

  /// Supplied saved default.
  savedDefault,

  /// Visible deterministic fallback.
  fallback,

  /// Explicit card adjustment.
  userAdjusted,
}

/// Closed effect family; future kinds reuse the same chip/question structure.
sealed class ProposalEffect extends ProposalValue {
  const new();
}

/// Substitute actual candidate facts, without altering their state or numbers.
final class ProposalFoodEffect extends ProposalEffect {
  /// A compatible normalized definition.
  const new(this.food);

  /// Replacement definition.
  final ProposalFood food;
  @override
  List<Object?> get _values => [food];
}

/// Change the item's original quantity.
final class ProposalQuantityEffect extends ProposalEffect {
  /// Quantity on a domain unit.
  const new(this.quantity);

  /// Original user quantity, not a precomputed nutrient amount.
  final Quantity quantity;
  @override
  List<Object?> get _values => [quantity];
}

/// Optional oil component (null represents no added fat).
final class ProposalComponentEffect extends ProposalEffect {
  /// Food and input, or neither for the none option.
  const new(this.food, this.quantity);

  /// Component definition.
  final ProposalFood? food;

  /// Component quantity.
  final Quantity? quantity;
  @override
  List<Object?> get _values => [food, quantity];
}

/// Retain a fraction of the original oil quantity.
final class ProposalRetentionEffect extends ProposalEffect {
  /// Fraction of original oil, never a running multiplier.
  const new(this.fraction);

  /// Retained fraction.
  final double fraction;
  @override
  List<Object?> get _values => [fraction];
}

/// Eat a fraction of the original dish.
final class ProposalShareEffect extends ProposalEffect {
  /// Exact stated share.
  const new(this.fraction);

  /// Eaten fraction.
  final double fraction;
  @override
  List<Object?> get _values => [fraction];
}

/// One distinct option; value is not its identity (oil tsp/tbsp share a value).
final class ProposalOption extends ProposalValue {
  /// Structural identity, normalized option token and deterministic effect.
  const new(this.id, this.value, this.effect);

  /// Stable structural identity.
  final String id;

  /// Option token from the interpretation, never used as a diagnostic.
  final String value;

  /// Pure effect of selecting this option.
  final ProposalEffect effect;
  @override
  List<Object?> get _values => [id, value, effect];
}

/// Immutable reusable dimension. Unavailable stated values still carry state.
final class ProposalDimension extends ProposalValue {
  /// Options preserve source order; IDs must be distinct.
  new(this.id, this.kind, Iterable<ProposalOption> options, {this.stated})
    : options = List.unmodifiable(options);

  /// Stable dimension identity.
  final String id;

  /// Closed semantic kind.
  final ProposalDimensionKind kind;

  /// Finite viable options.
  final List<ProposalOption> options;

  /// User-stated value, e.g. dry when only a cooked candidate is available.
  final String? stated;
  @override
  List<Object?> get _values => [id, kind, options, stated];
}

/// Visible assumption selection, with localization owned by A22.
final class ProposalChip extends ProposalValue {
  /// A selected option and its explicit/default/fallback origin.
  const new(this.dimensionId, this.optionId, this.origin);

  /// Dimension identity.
  final String dimensionId;

  /// Selected structural option identity.
  final String optionId;

  /// Why this selection won.
  final ProposalChoiceOrigin origin;
  @override
  List<Object?> get _values => [dimensionId, optionId, origin];
}
