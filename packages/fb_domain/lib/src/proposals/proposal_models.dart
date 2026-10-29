part of 'proposal_input.dart';

/// A normalized food item; names and raw mentions never drive policy.
final class ProposalItem extends ProposalValue {
  /// Immutable domain computation inputs.
  new({
    required this.id,
    required this.displayName,
    required this.match,
    required this.quantity,
    required this.explicit,
    required Iterable<ProposalFood> alternatives,
    required Iterable<ProposalDimension> dimensions,
    this.estimate,
    this.fraction,
    this.people,
  }) : alternatives = List.unmodifiable(alternatives),
       dimensions = List.unmodifiable(dimensions);

  /// Structural item identity (row UUIDs are allocated separately).
  final String id;

  /// Original food mention for display only, never matching or numeric policy.
  final String displayName;

  /// Matched definition, if available.
  final ProposalFood? match;

  /// User quantity or null for a visible portion default/needsAmount.
  final Quantity? quantity;

  /// Whether the quantity was explicitly stated.
  final bool explicit;

  /// At most three distinct alternatives, excluding the match.
  final List<ProposalFood> alternatives;

  /// Detected dimensions.
  final List<ProposalDimension> dimensions;

  /// Fallback per-100g bounds, only used if match is absent.
  final ProposalRange? estimate;

  /// Optional stated dish fraction.
  final double? fraction;

  /// Optional number of people sharing.
  final int? people;
  @override
  List<Object?> get _values => [
    id,
    displayName,
    match,
    quantity,
    explicit,
    alternatives,
    dimensions,
    estimate,
    fraction,
    people,
  ];
}

/// Food meal intent or typed routing outcome for A22/A23.
final class ProposalIntent extends ProposalValue {
  /// Normalized values, preserving the original intent position.
  new({
    required this.index,
    required this.kind,
    required Iterable<ProposalItem> items,
    this.timeHint,
    this.slotHint,
    this.dishGroup,
  }) : items = List.unmodifiable(items);

  /// Original message position.
  final int index;

  /// Known intent discriminator, or `unrecognized` for a kind this version
  /// can't handle yet (B09 D4).
  final String kind;

  /// Foods; empty for routing outcomes.
  final List<ProposalItem> items;

  /// Literal time hint; deterministic resolution comes later.
  final String? timeHint;

  /// Literal slot hint.
  final String? slotHint;

  /// Optional dish display name, never logged.
  final String? dishGroup;
  @override
  List<Object?> get _values => [
    index,
    kind,
    items,
    timeHint,
    slotHint,
    dishGroup,
  ];
}

/// Successfully normalized v1 interpretation.
final class ProposalInterpretation extends ProposalValue {
  /// Immutable intent list.
  new(Iterable<ProposalIntent> intents) : intents = List.unmodifiable(intents);

  /// All supported food/routing intents in source order.
  final List<ProposalIntent> intents;
  @override
  List<Object?> get _values => [intents];
}
