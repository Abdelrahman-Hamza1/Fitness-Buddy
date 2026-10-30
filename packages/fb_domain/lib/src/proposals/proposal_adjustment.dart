part of 'proposal_input.dart';

/// Absolute edits only. Values are never used in diagnostics.
sealed class ProposalAdjustment extends ProposalValue {
  const new();
}

/// Select an answer or chip using its declared structural option ID.
final class ProposalSelect extends ProposalAdjustment {
  /// Dimension and option must exist in the current draft.
  const new(this.dimensionId, this.optionId);

  /// Declared dimension.
  final String dimensionId;

  /// Declared option.
  final String optionId;
  @override
  List<Object?> get _values => [dimensionId, optionId];
}

/// Replace the original quantity, including unit, with a measured quantity.
final class ProposalSetAmount extends ProposalAdjustment {
  /// Stable parent line ID and absolute quantity.
  const new(this.lineId, this.quantity);

  /// Parent row identity.
  final String lineId;

  /// New amount/unit.
  final Quantity quantity;
  @override
  List<Object?> get _values => [lineId, quantity];
}

/// Choose an alternative or fully supplied offline search result.
final class ProposalSwap extends ProposalAdjustment {
  /// Caller supplies all facts, never a name-only lookup.
  const new(this.lineId, this.food);

  /// Parent row identity.
  final String lineId;

  /// Frozen resolved facts.
  final ProposalFood food;
  @override
  List<Object?> get _values => [lineId, food];
}

/// Remove or restore an item (with its generated oil), or a generated oil
/// line on its own.
final class ProposalSetRemoved extends ProposalAdjustment {
  /// Removal is an absolute state.
  const new(this.lineId, {required this.removed});

  /// Parent row identity.
  final String lineId;

  /// True to remove; false to restore.
  final bool removed;
  @override
  List<Object?> get _values => [lineId, removed];
}

/// Allocate new item/component IDs once; replay uses the stable token.
final class ProposalAdd extends ProposalAdjustment {
  /// A deliberate new add uses a new token and the caller's ID source.
  const new(this.cardId, this.token, this.item, this.idSource);

  /// Destination card.
  final String cardId;

  /// Idempotency token, unique within the session.
  final String token;

  /// Fully resolved new item.
  final ProposalItem item;

  /// Used only on the first application of this token.
  final ProposalIdSource idSource;
  @override
  List<Object?> get _values => [cardId, token, item];
}

/// Change concrete time and/or slot on every ingredient of one card.
final class ProposalSetWhen extends ProposalAdjustment {
  /// Null fields preserve the existing value.
  const new(this.cardId, {this.time, this.slotId});

  /// Destination card.
  final String cardId;

  /// Concrete time; no clock reads.
  final EntryTime? time;

  /// Active local slot identity.
  final String? slotId;
  @override
  List<Object?> get _values => [cardId, time, slotId];
}

/// Application reports the lifecycle after its applier transaction succeeds.
final class ProposalSetLifecycle extends ProposalAdjustment {
  /// Engine emits no lifecycle writer.
  const new(this.cardId, this.lifecycle);

  /// Stable card.
  final String cardId;

  /// Observed lifecycle.
  final ProposalLifecycle lifecycle;
  @override
  List<Object?> get _values => [cardId, lifecycle];
}

/// Gives open card [cardId] fresh line and dish identities from [idSource]
/// (A23 D10): after an Undo of its confirm, the old entry IDs are diary
/// tombstones and can't be logged again. Not a user adjustment.
final class ProposalReidentify extends ProposalAdjustment {
  /// Engine emits no writer; the caller persists the result.
  const new(this.cardId, this.idSource);

  /// Stable card.
  final String cardId;

  /// Where the new identities come from.
  final ProposalIdSource idSource;
  @override
  List<Object?> get _values => [cardId, idSource];
}

final class _EngineState {
  late ProposalRequest request;
  bool allocationsAllowed = true;
  int revision = 0;
  final untrustedRestoreFoods = <ProposalFood>{};
  final restoreIssues = <String, ProposalIssue>{};
  final components = <String, ProposalComponentEffect>{};
  final departedCards = <String>{};
  final questionOwners = <String, String>{};
  final intentCards = <int, String>{};
  final ids = <String, String>{};
  final items = <String, ProposalItem>{};
  final removed = <String>{};
  final choices = <String, String>{};
  final issued = <String>[];
  final times = <int, EntryTime>{};
  final slots = <int, String>{};
  final origins = <String, String>{};
  final lifecycles = <String, ProposalLifecycle>{};
  final adds = <String, ProposalItem>{};
  final addOwners = <String, String>{};

  /// Items whose amount Buddy assumed when first built: their lines keep
  /// − / + after a user step or a follow-up states the amount (A22b E3).
  final assumedAmounts = <String>{};

  /// Items whose generated oil line was removed on its own (A22b review 4).
  final removedComponents = <String>{};

  /// Cards the user adjusted (a chip, amount, swap, add, removal or time),
  /// kept across rebuilds: the confirmed outcome's `adjusted` (A23 D9).
  final userAdjusted = <String>{};
  String identity(String key, ProposalIdSource? source) =>
      ids.putIfAbsent(key, () {
        if (!allocationsAllowed) throw const _Invalid();
        return _id(source);
      });
  _EngineState copy() => _EngineState()
    ..untrustedRestoreFoods.addAll(untrustedRestoreFoods)
    ..restoreIssues.addAll(restoreIssues)
    ..departedCards.addAll(departedCards)
    ..components.addAll(components)
    ..revision = revision
    ..questionOwners.addAll(questionOwners)
    ..allocationsAllowed = allocationsAllowed
    ..request = request
    ..intentCards.addAll(intentCards)
    ..ids.addAll(ids)
    ..items.addAll(items)
    ..removed.addAll(removed)
    ..choices.addAll(choices)
    ..issued.addAll(issued)
    ..times.addAll(times)
    ..slots.addAll(slots)
    ..origins.addAll(origins)
    ..lifecycles.addAll(lifecycles)
    ..adds.addAll(adds)
    ..addOwners.addAll(addOwners)
    ..assumedAmounts.addAll(assumedAmounts)
    ..removedComponents.addAll(removedComponents)
    ..userAdjusted.addAll(userAdjusted);
}

ProposalRequest _request(
  _EngineState state,
  ProposalInterpretation interpretation, {
  ProposalContext? context,
  ProposalRequest? fresh,
}) => ProposalRequest._(
  interpretation,
  fresh?.messageId ?? state.request.messageId,
  fresh?.context ?? context ?? state.request.context,
  fresh?.facts ?? state.request.facts,
  fresh?.policy ?? state.request.policy,
  fresh?.idSource ?? state.request.idSource,
);

ProposalItem _copyItem(
  ProposalItem i, {
  required bool explicit,
  String? id,
  ProposalFood? food,
  Quantity? quantity,
}) => ProposalItem(
  id: id ?? i.id,
  displayName: i.displayName,
  match: food ?? i.match,
  quantity: quantity ?? i.quantity,
  explicit: explicit,
  alternatives: i.alternatives,
  dimensions: i.dimensions,
  estimate: i.estimate,
  fraction: i.fraction,
  people: i.people,
);
ProposalIntent _intent(ProposalIntent i, Iterable<ProposalItem> items) =>
    ProposalIntent(
      index: i.index,
      kind: i.kind,
      items: items,
      timeHint: i.timeHint,
      slotHint: i.slotHint,
      dishGroup: i.dishGroup,
      dateHint: i.dateHint,
    );

ProposalUpdateResult _recompute(
  ProposalSession session,
  ProposalAdjustment adjustment,
  ProposalContext? context,
) {
  try {
    final state = session._state.copy()..allocationsAllowed = false;
    var interpretation = state.request.interpretation.value!;
    final originals = [for (final i in interpretation.intents) ...i.items];
    // The card a user adjustment touched; null for lifecycle and refreshes.
    String? touched;
    ProposalItem find(String lineId) {
      final original = originals
          .where(
            (i) =>
                state.ids['item:${i.id}'] == lineId ||
                state.ids['oil:${i.id}'] == lineId,
          )
          .firstOrNull;
      if (original == null) throw const _Invalid();
      final owner = interpretation.intents.firstWhere(
        (i) => i.items.contains(original),
      );
      if ((state.lifecycles[state.intentCards[owner.index]] ??
              ProposalLifecycle.active) !=
          ProposalLifecycle.active) {
        throw const _Invalid();
      }
      touched = state.intentCards[owner.index];
      return state.items[original.id] ?? original;
    }

    switch (adjustment) {
      case ProposalSelect(:final dimensionId, :final optionId):
        final dimensions = [
          for (final c in session.cards)
            for (final l in c.lines) ...l.dimensions,
        ];
        final d = dimensions.where((d) => d.id == dimensionId).firstOrNull;
        if (d == null || !d.options.any((o) => o.id == optionId)) {
          throw const _Invalid();
        }
        touched = session.cards
            .where((c) => c.lines.any((l) => l.dimensions.contains(d)))
            .firstOrNull
            ?.id;
        if (d.kind == .fat) {
          for (final original in originals) {
            final item = state.items[original.id] ?? original;
            if (item.dimensions.any((d) => d.id == dimensionId)) {
              state.components.remove(item.id);
            }
          }
        }
        state.choices[dimensionId] = optionId;
      case ProposalSetAmount(:final lineId, :final quantity):
        final i = find(lineId);
        if (state.ids['oil:${i.id}'] == lineId) {
          final line = session.cards
              .expand((c) => c.lines)
              .firstWhere((l) => l.entry.id == lineId);
          final food = line.selectedFood!;
          state.components[i.id] = ProposalComponentEffect(food, quantity);
          break;
        }
        state.items[i.id] = _copyItem(i, quantity: quantity, explicit: true);
        for (final d in i.dimensions.where((d) => d.kind == .portion)) {
          state.choices.remove(d.id);
        }
      case ProposalSwap(:final lineId, :final food):
        _readFood(_writeFood(food));
        final i = find(lineId);
        if (food.key.isEmpty ||
            (food.source == .yours && food.personalVersion == null)) {
          throw const _Invalid();
        }
        // The amount carries over when its unit works for the new food;
        // otherwise the food's default portion (a serving or grams) is
        // assumed, so the row stays editable with − / + (A22b review).
        Quantity? fits(Quantity? q) =>
            q != null && food.measures.resolve(q) is Resolved ? q : null;
        if (state.ids['oil:${i.id}'] == lineId) {
          final line = session.cards
              .expand((c) => c.lines)
              .firstWhere((l) => l.entry.id == lineId);
          state.components[i.id] = ProposalComponentEffect(
            food,
            fits(line.entry.amount.input) ??
                DefaultPortion.choose(food.measures),
          );
          break;
        }
        final kept = fits(i.quantity);
        if (i.quantity != null && kept == null) {
          state.assumedAmounts.add(i.id);
        }
        state.items[i.id] = ProposalItem(
          id: i.id,
          displayName: i.displayName,
          match: food,
          quantity: i.quantity == null
              ? null
              : kept ?? DefaultPortion.choose(food.measures),
          explicit: i.explicit,
          alternatives: [
            if (i.match != null && i.match!.key != food.key) i.match!,
            ...i.alternatives.where((f) => f.key != food.key),
          ],
          dimensions: [],
          fraction: i.fraction,
          people: i.people,
        );
        state.choices.removeWhere((key, _) => key.startsWith('${i.id}/'));
      case ProposalSetRemoved(:final lineId, :final removed):
        final i = find(lineId);
        // A generated oil line goes (or comes back) on its own; its item
        // stays.
        if (state.ids['oil:${i.id}'] == lineId) {
          if (removed) {
            state.removedComponents.add(i.id);
          } else {
            state.removedComponents.remove(i.id);
          }
          break;
        }
        if (removed) {
          state.removed.add(i.id);
        } else {
          state.removed.remove(i.id);
        }
      case ProposalAdd(
        :final cardId,
        :final token,
        :final item,
        :final idSource,
      ):
        touched = cardId;
        final foods = <ProposalFood>[];
        final normalized = _writeItem(item, foods);
        _bound([
          normalized,
          [for (final f in foods) _writeFood(f)],
        ], 0);
        for (final f in foods) {
          _readFood(_writeFood(f));
        }
        _readItem(normalized, foods);
        if (state.adds[token] case final old?) {
          if (old != item || state.addOwners[token] != cardId) {
            throw const _Invalid();
          }
          break;
        }
        if (originals.length >= ProposalPolicyConstants.maxItems) {
          throw const _Invalid(ProposalIssue.inputTooLarge);
        }
        final card = session.cards
            .where((c) => c.id == cardId && c.lifecycle == .active)
            .firstOrNull;
        if (card == null || token.isEmpty) throw const _Invalid();
        final owner = interpretation.intents
            .where((i) => state.intentCards[i.index] == cardId)
            .firstOrNull;
        if (owner == null) throw const _Invalid();
        final id = _id(idSource);
        final added = _reidentify(item, id);
        state.ids['item:$id'] = id;
        state.ids['oil:$id'] = _id(idSource);
        state.adds[token] = item;
        state.addOwners[token] = cardId;
        interpretation = ProposalInterpretation([
          for (final i in interpretation.intents)
            if (i == owner) _intent(i, [...i.items, added]) else i,
        ]);
      case ProposalSetWhen(:final cardId, :final time, :final slotId):
        final card = session.cards.where((c) => c.id == cardId).firstOrNull;
        if (card == null ||
            card.lifecycle != .active ||
            (slotId != null &&
                !(context ?? state.request.context).slots.any(
                  (s) => s.id == slotId && s.active,
                ))) {
          throw const _Invalid();
        }
        touched = cardId;
        for (final i in interpretation.intents.where(
          (i) => state.intentCards[i.index] == cardId,
        )) {
          if (time != null) state.times[i.index] = time;
          if (slotId != null) state.slots[i.index] = slotId;
        }

      case ProposalReidentify(:final cardId, :final idSource):
        final card = session.cards.where((c) => c.id == cardId).firstOrNull;
        if (card == null || card.lifecycle != .active) throw const _Invalid();
        for (final i in interpretation.intents.where(
          (i) => state.intentCards[i.index] == cardId,
        )) {
          for (final item in i.items) {
            state.ids['item:${item.id}'] = _id(idSource);
            state.ids['oil:${item.id}'] = _id(idSource);
          }
          if (state.ids.containsKey('group:${i.index}')) {
            state.ids['group:${i.index}'] = _id(idSource);
          }
        }

      case ProposalSetLifecycle(:final cardId, :final lifecycle):
        final card = session.cards.where((c) => c.id == cardId).firstOrNull;
        if (card == null ||
            (card.lifecycle != .active && lifecycle == .active)) {
          throw const _Invalid();
        }
        state.lifecycles[cardId] = lifecycle;
    }
    // No ID source exists on this path. A missing identity fails closed.
    final result = ProposalEngine._build(
      _request(state, interpretation, context: context),
      state,
    );
    if (result.issue case final issue?) return ProposalResult.failure(issue);
    final diff = _diff(session, result.value!);
    if (!diff.isEmpty) {
      state.revision++;
      if (touched case final card?) state.userAdjusted.add(card);
    }
    return ProposalResult.success(ProposalUpdate(result.value!, diff));
  } on _Invalid catch (e) {
    return ProposalResult.failure(e.issue);
  }
  // Unit/ID primitives throw ArgumentError; expose only a fixed issue.
  // ignore: avoid_catching_errors
  on ArgumentError {
    return const ProposalResult.failure(ProposalIssue.invalidInput);
  }
}

ProposalUpdateResult _rebuild(ProposalCard previous, ProposalRequest fresh) {
  if (previous.lifecycle != .active) {
    return const ProposalResult.failure(ProposalIssue.invalidInput);
  }
  if (fresh.interpretation.issue case final issue?) {
    return ProposalResult.failure(issue);
  }
  final old = previous._state;
  final state = old.copy()
    ..untrustedRestoreFoods.clear()
    ..restoreIssues.clear()
    ..allocationsAllowed = true
    ..departedCards.clear()
    ..revision = old.revision + 1
    ..issued.clear()
    ..intentCards.clear()
    ..times.clear()
    ..slots.clear()
    ..ids.removeWhere((key, _) => key.startsWith('group:'));
  // Rebuild of unverified history must not carry serialized food overrides
  // into the newly trusted request, including generated components/additions.
  if (old.restoreIssues.containsKey(previous.id)) {
    state.items.clear();
    state.components.clear();
    state.adds.clear();
    state.addOwners.clear();
  }
  final oldItems = [
    for (final i in old.request.interpretation.value!.intents)
      if (old.intentCards[i.index] == previous.id) ...i.items,
  ];
  final used = <String>{};
  final intents = <ProposalIntent>[];
  for (final intent in fresh.interpretation.value!.intents) {
    final items = <ProposalItem>[];
    for (final item in intent.items) {
      final match = oldItems
          .where((i) => !used.contains(i.id) && i.match?.key == item.match?.key)
          .firstOrNull;
      if (match == null) {
        // Fresh structural positions can collide with old matched identities.
        final id = _id(fresh.idSource);
        state.ids['item:$id'] = id;
        state.ids['oil:$id'] = _id(fresh.idSource);
        items.add(_reidentify(item, id));
        continue;
      }
      used.add(match.id);
      final priorIntent = old.request.interpretation.value!.intents.firstWhere(
        (i) => i.items.contains(match),
      );
      if (intent.timeHint == null && old.times[priorIntent.index] != null) {
        state.times[intent.index] = old.times[priorIntent.index]!;
      }
      if (intent.slotHint == null && old.slots[priorIntent.index] != null) {
        state.slots[intent.index] = old.slots[priorIntent.index]!;
      }
      final group = old.ids['group:${priorIntent.index}'];
      if (group != null && intent.dishGroup != null) {
        state.ids.putIfAbsent('group:${intent.index}', () => group);
      }
      if (item.dimensions.any((d) => d.kind == .fat && d.stated != null)) {
        state.components.remove(match.id);
      }
      final adjusted = state.items.remove(match.id);
      final next = _copyItem(
        item,
        id: match.id,
        quantity: item.explicit ? item.quantity : adjusted?.quantity,
        food: adjusted?.match?.key == item.match?.key ? adjusted?.match : null,
        explicit: item.explicit || (adjusted?.explicit ?? false),
      );
      // Preserve compatible dimension IDs by kind/occurrence, never by names.
      final dimensions = <ProposalDimension>[];
      final priorKinds = <ProposalDimensionKind, int>{};
      for (final d in next.dimensions) {
        final occurrence = priorKinds.update(
          d.kind,
          (n) => n + 1,
          ifAbsent: () => 0,
        );
        final prior = match.dimensions
            .where((p) => p.kind == d.kind)
            .skip(occurrence)
            .firstOrNull;
        if (prior == null) {
          dimensions.add(
            ProposalDimension(
              '${match.id}/new/${dimensions.length}',
              d.kind,
              d.options,
              stated: d.stated,
            ),
          );
          continue;
        }
        final mapped = ProposalDimension(prior.id, d.kind, [
          for (final o in d.options)
            ProposalOption(
              '${prior.id}/${d.options.indexOf(o)}',
              o.value,
              o.effect,
            ),
        ], stated: d.stated);
        dimensions.add(mapped);
        final choice = state.choices[prior.id];
        final chosen = prior.options.where((o) => o.id == choice).firstOrNull;
        final compatible = mapped.options
            .where((o) => o.effect == chosen?.effect)
            .firstOrNull;
        if (d.stated != null || compatible == null) {
          state.choices.remove(prior.id);
        } else {
          state.choices[prior.id] = compatible.id;
        }
      }
      items.add(
        ProposalItem(
          id: next.id,
          displayName: next.displayName,
          match: next.match,
          quantity: next.quantity,
          explicit: next.explicit,
          alternatives: next.alternatives,
          dimensions: dimensions,
          estimate: next.estimate,
          fraction: next.fraction,
          people: next.people,
        ),
      );
    }
    intents.add(_intent(intent, items));
  }
  for (final q in ProposalEngine._build(
    _request(old.copy(), old.request.interpretation.value!),
    old.copy(),
  ).value!.budget.questions) {
    if (used.any((id) => q.dimensionId.startsWith('$id/'))) {
      state.issued.add(q.dimensionId);
    }
  }
  // A follow-up that names no day or time, or no meal, keeps the card's
  // (A22b review): even when every food changed, it's still that meal on
  // that day ("swap it for rice" never moves lunch to breakfast time).
  final prior = previous.lines.firstOrNull?.entry;
  if (prior != null) {
    for (final intent in intents) {
      if (prior.when case EntryAt(:final time)
          when intent.timeHint == null && intent.dateHint == null) {
        state.times.putIfAbsent(intent.index, () => time);
      }
      if (prior.slotId case final slot? when intent.slotHint == null) {
        state.slots.putIfAbsent(intent.index, () => slot);
      }
    }
  }
  state.origins[previous.id] = previous.originMessageId;
  return _finishRebuild(
    previous,
    fresh,
    state,
    ProposalInterpretation(intents),
  );
}

ProposalUpdateResult _finishRebuild(
  ProposalCard previous,
  ProposalRequest fresh,
  _EngineState state,
  ProposalInterpretation interpretation,
) {
  for (final intent in interpretation.intents.where(
    (i) => i.kind == 'foodLog',
  )) {
    state.intentCards[intent.index] = previous.id;
  }
  final request = ProposalRequest._(
    interpretation,
    fresh.messageId,
    fresh.context,
    fresh.facts,
    fresh.policy,
    fresh.idSource,
  );
  state.request = request;
  final compatibleChoices = _choiceOptions(state);
  state.choices.removeWhere(
    (key, value) => !(compatibleChoices[key]?.contains(value) ?? false),
  );
  final result = ProposalEngine._build(request, state);
  if (result.issue case final issue?) return ProposalResult.failure(issue);
  final before = ProposalSession._(
    [previous],
    QuestionBudget._([]),
    [],
    previous._state,
  );
  return ProposalResult.success(
    ProposalUpdate(result.value!, _diff(before, result.value!)),
  );
}

ProposalItem _reidentify(ProposalItem item, String id) => ProposalItem(
  id: id,
  displayName: item.displayName,
  match: item.match,
  quantity: item.quantity,
  explicit: item.explicit,
  alternatives: item.alternatives,
  dimensions: [
    for (final (di, d) in item.dimensions.indexed)
      ProposalDimension('$id/$di', d.kind, [
        for (final (oi, o) in d.options.indexed)
          ProposalOption('$id/$di/$oi', o.value, o.effect),
      ], stated: d.stated),
  ],
  estimate: item.estimate,
  fraction: item.fraction,
  people: item.people,
);

Iterable<ProposalFood> _foods(_EngineState state) sync* {
  for (final c in state.components.values) {
    if (c.food case final food?) yield food;
  }
  for (final intent in state.request.interpretation.value!.intents) {
    for (final original in intent.items) {
      final item = state.items[original.id] ?? original;
      if (item.match case final food?) yield food;
      yield* item.alternatives;
      for (final d in item.dimensions) {
        for (final o in d.options) {
          if (o.effect case ProposalFoodEffect(:final food)) yield food;
          if (o.effect case ProposalComponentEffect(food: final food?)) {
            yield food;
          }
        }
      }
    }
  }
}
