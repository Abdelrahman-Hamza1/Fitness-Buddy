part of 'proposal_input.dart';

/// Typed highlight fields; no before/after user values in diagnostics.
enum ProposalField {
  /// Food identity and definition.
  food,

  /// Canonical amount or entered unit.
  amount,

  /// Storage-rounded snapshot.
  nutrients,

  /// Fact/provenance source.
  source,

  /// Estimate badge or bounds.
  estimate,

  /// Selected assumptions or conversion.
  assumptions,

  /// Concrete entry time.
  time,

  /// Meal slot.
  slot,

  /// Card totals.
  totals,

  /// Conservative bounds.
  range,

  /// Confirmed-only A12 projection.
  dayPreview,

  /// Application-reported lifecycle.
  lifecycle,
}

/// Immutable changed identities/field codes, suitable for A22 highlights.
final class ProposalDiff extends ProposalValue {
  new _(
    Iterable<String> added,
    Iterable<String> removed,
    Map<String, Set<ProposalField>> lines,
    Map<String, Set<ProposalField>> cards,
    Iterable<String> dimensions,
    Iterable<String> questions,
  ) : addedLineIds = List.unmodifiable(added),
      removedLineIds = List.unmodifiable(removed),
      lineFields = Map.unmodifiable(
        lines.map((k, v) => MapEntry(k, Set<ProposalField>.unmodifiable(v))),
      ),
      cardFields = Map.unmodifiable(
        cards.map((k, v) => MapEntry(k, Set<ProposalField>.unmodifiable(v))),
      ),
      changedDimensionIds = List.unmodifiable(dimensions),
      changedQuestionIds = List.unmodifiable(questions);

  /// New active lines.
  final List<String> addedLineIds;

  /// Deactivated lines.
  final List<String> removedLineIds;

  /// Fields changed on existing lines.
  final Map<String, Set<ProposalField>> lineFields;

  /// Fields changed on cards.
  final Map<String, Set<ProposalField>> cardFields;

  /// Changed choices or available dimensions.
  final List<String> changedDimensionIds;

  /// Changed open questions.
  final List<String> changedQuestionIds;

  /// Repeated absolute edits produce no highlights.
  bool get isEmpty =>
      addedLineIds.isEmpty &&
      removedLineIds.isEmpty &&
      lineFields.isEmpty &&
      cardFields.isEmpty &&
      changedDimensionIds.isEmpty &&
      changedQuestionIds.isEmpty;
  @override
  List<Object?> get _values => [
    addedLineIds,
    removedLineIds,
    for (final e in lineFields.entries) [e.key, e.value.toList()],
    for (final e in cardFields.entries) [e.key, e.value.toList()],
    changedDimensionIds,
    changedQuestionIds,
  ];
}

/// Recomputed immutable session and its typed highlights.
final class ProposalUpdate extends ProposalValue {
  /// Full replacement and its highlight codes.
  const new(this.session, this.diff);

  /// Full replacement draft.
  final ProposalSession session;

  /// Changes from the previous draft.
  final ProposalDiff diff;
  @override
  List<Object?> get _values => [session, diff];
}

/// Fixed failure or a new draft with typed changes.
typedef ProposalUpdateResult = ProposalResult<ProposalUpdate>;

ProposalDiff _diff(ProposalSession a, ProposalSession b) {
  final before = {
    for (final c in a.cards)
      for (final l in c.lines) l.entry.id: l,
  };
  final after = {
    for (final c in b.cards)
      for (final l in c.lines) l.entry.id: l,
  };
  final lines = <String, Set<ProposalField>>{};
  for (final id in before.keys.where(after.containsKey)) {
    final x = before[id]!;
    final y = after[id]!;
    final fields = <ProposalField>{
      if (x.entry.food.ref != y.entry.food.ref ||
          x.entry.food.per100 != y.entry.food.per100)
        .food,
      if (x.entry.amount != y.entry.amount) .amount,
      if (x.snapshot != y.snapshot) .nutrients,
      if (x.factOrigin != y.factOrigin ||
          x.entry.food.provenance.source != y.entry.food.provenance.source)
        .source,
      if (x.range != y.range ||
          x.entry.food.provenance.isEstimate !=
              y.entry.food.provenance.isEstimate)
        .estimate,
      if (!_same(x.chips, y.chips) ||
          !_same(x.dimensions, y.dimensions) ||
          x.yieldNote?.factor != y.yieldNote?.factor)
        .assumptions,
      if (x.entry.when != y.entry.when) .time,
      if (x.entry.slotId != y.entry.slotId) .slot,
    };
    if (fields.isNotEmpty) lines[id] = fields;
  }
  final cards = <String, Set<ProposalField>>{};
  for (final y in b.cards) {
    final x = a.cards.where((c) => c.id == y.id).firstOrNull;
    final fields = <ProposalField>{
      if (x?.totals != y.totals) .totals,
      if (x?.range != y.range) .range,
      if (x?.preview != y.preview) .dayPreview,
      if (x?.lifecycle != y.lifecycle) .lifecycle,
    };
    if (fields.isNotEmpty) cards[y.id] = fields;
  }
  Map<String, Object> dimensions(ProposalSession s) => {
    for (final c in s.cards)
      for (final l in c.lines)
        for (final d in l.dimensions)
          d.id: [d, ...l.chips.where((v) => v.dimensionId == d.id)],
  };
  final dx = dimensions(a);
  final dy = dimensions(b);
  final qx = {for (final q in a.budget.questions) q.dimensionId: q};
  final qy = {for (final q in b.budget.questions) q.dimensionId: q};
  return ProposalDiff._(
    after.keys.where((id) => !before.containsKey(id)),
    before.keys.where((id) => !after.containsKey(id)),
    lines,
    cards,
    {...dx.keys, ...dy.keys}.where((id) => !_same(dx[id], dy[id])),
    {...qx.keys, ...qy.keys}.where((id) => qx[id] != qy[id]),
  );
}
