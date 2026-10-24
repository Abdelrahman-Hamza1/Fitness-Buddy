part of 'proposal_input.dart';

/// Frozen local inputs. Targets/rebalancing are extended by WP3, never guessed.
final class ProposalContext {
  /// No clock inside the engine; reference time and every slot are supplied.
  new({
    required this.referenceTime,
    required Iterable<MealSlot> slots,
    Iterable<YieldFactor> yields = const [],
    Map<String, String> savedDefaults = const {},
    Map<String, String> choices = const {},
    this.mode = SlotMode.normal,
  }) : slots = List.unmodifiable(slots),
       yields = List.unmodifiable(yields),
       savedDefaults = Map.unmodifiable(savedDefaults),
       choices = Map.unmodifiable(choices);

  /// Fixed time/offset, also the source for slot fallback.
  final EntryTime referenceTime;

  /// Available local slots.
  final List<MealSlot> slots;

  /// Frozen conversion factors.
  final List<YieldFactor> yields;

  /// Semantic questionKind to option value or structural option ID.
  final Map<String, String> savedDefaults;

  /// Explicit dimension-ID to option-ID selections.
  final Map<String, String> choices;

  /// Active normal/Ramadan slot mode.
  final SlotMode mode;
  @override
  String toString() => 'ProposalContext(redacted)';
}

/// Transport JSON is normalized immediately; later caller mutations cannot win.
final class ProposalRequest {
  /// A message, frozen domain facts/context/policy and caller-owned allocator.
  new({
    required Map<String, Object?> interpretation,
    required this.messageId,
    required this.idSource,
    required this.context,
    required this.facts,
    ProposalPolicy? policy,
  }) : interpretation = InterpretationDecoder.decode(interpretation, facts),
       policy = policy ?? ProposalPolicy.fromThresholds({});

  /// Creating/current assistant-message ID, not identity/account context.
  final String messageId;

  /// Normalized immutable boundary outcome.
  final ProposalResult<ProposalInterpretation> interpretation;

  /// Only build/add/unmatched rebuild may allocate identities.
  final ProposalIdSource idSource;

  /// Frozen local inputs.
  final ProposalContext context;

  /// Frozen source/classification facts.
  final ProposalFacts facts;

  /// Effective threshold snapshot.
  final ProposalPolicy policy;
  @override
  String toString() => 'ProposalRequest(redacted)';
}

/// One computed line, exactly the data carried into an existing diary op.
final class ProposalLine extends ProposalValue {
  /// Freeze one calculated line and its typed assumption chips.
  new({
    required this.entry,
    required this.snapshot,
    required this.factOrigin,
    required Iterable<ProposalChip> chips,
    this.range,
    this.yieldNote,
    Iterable<ProposalDimension> dimensions = const [],
  }) : chips = List.unmodifiable(chips),
       dimensions = List.unmodifiable(dimensions);

  /// Fully resolved diary entry input with stable row ID, time and slot.
  final NewDiaryEntry entry;

  /// Storage-rounded nutrients, computed once from the canonical amount.
  final Nutrients snapshot;

  /// Which actual food facts were used.
  final ProposalFactOrigin factOrigin;

  /// Visible selected dimensions/assumptions.
  final List<ProposalChip> chips;

  /// Available dimensions, including generated all/most oil retention.
  final List<ProposalDimension> dimensions;

  /// Absolute consumed kcal range, when uncertain.
  final EstimateRange? range;

  /// Exact state conversion; A22 localizes it.
  final YieldNote? yieldNote;
  @override
  List<Object?> get _values => [
    entry,
    snapshot,
    factOrigin,
    chips,
    dimensions,
    range,
    yieldNote?.fromState,
    yieldNote?.toState,
    yieldNote?.factor,
  ];
}

/// One independently confirmable meal card; status persistence belongs to A23.
final class ProposalCard extends ProposalValue {
  new _({
    required this.id,
    required this.originMessageId,
    required this.budgetMessageId,
    required Iterable<ProposalLine> lines,
    required Iterable<ChangeOp> draftOps,
    required Iterable<ProposalIssue> issues,
  }) : lines = List.unmodifiable(lines),
       draftOps = List.unmodifiable(draftOps),
       issues = List.unmodifiable(issues);

  /// Stable proposal UUID.
  final String id;

  /// Immutable assistant-message origin.
  final String originMessageId;

  /// Current assistant-message question budget binding.
  final String budgetMessageId;

  /// Active storage-rounded ingredient/component lines.
  final List<ProposalLine> lines;

  /// Ops only: the application's confirm use case composes the ChangeSet.
  final List<ChangeOp> draftOps;

  /// Blocking fixed-code issues.
  final List<ProposalIssue> issues;

  /// Empty/all-invalid cards cannot be confirmed.
  bool get canConfirm => draftOps.isNotEmpty && issues.isEmpty;

  /// Totals at storage precision: no accumulating into an earlier draft.
  Nutrients get totals => _sum(lines.map((l) => l.snapshot));

  /// Conservative sum of line bounds (exact lines use their snapshot).
  EstimateRange? get range => lines.any((l) => l.range != null)
      ? EstimateRange(
          lines.fold(
            0,
            (sum, l) => sum + (l.range?.lowKcal ?? l.snapshot.kcal),
          ),
          lines.fold(
            0,
            (sum, l) => sum + (l.range?.highKcal ?? l.snapshot.kcal),
          ),
        )
      : null;
  @override
  List<Object?> get _values => [
    id,
    originMessageId,
    budgetMessageId,
    lines,
    draftOps,
    issues,
  ];
}

/// Immutable built message: cards, shared bounded questions and routing data.
final class ProposalSession extends ProposalValue {
  new _(
    Iterable<ProposalCard> cards,
    this.budget,
    Iterable<ProposalIntent> routing,
  ) : cards = List.unmodifiable(cards),
      routing = List.unmodifiable(routing);

  /// One card per resolved meal.
  final List<ProposalCard> cards;

  /// Message-wide allocation (never per card).
  final QuestionBudget budget;

  /// Non-food v1 intents remain typed routing data.
  final List<ProposalIntent> routing;
  @override
  List<Object?> get _values => [cards, budget, routing];
}

/// Build outcome; invalid input never produces executable ops.
typedef ProposalBuildResult = ProposalResult<ProposalSession>;

/// Deterministic numeric construction only. No confirmation or storage access.
abstract final class ProposalEngine {
  /// Compute a message once from frozen facts and explicit environment.
  static ProposalBuildResult build(ProposalRequest request) {
    final decoded = request.interpretation;
    if (decoded.issue case final issue?) return ProposalResult.failure(issue);
    try {
      if (!isUuidV7(request.messageId)) throw const _Invalid();
      final context = request.context;
      final converter = YieldConverter(context.yields);
      final questions = <ProposalQuestion>[];
      final cards = <String, _CardBuilder>{};
      final cookingFatIds = {...request.facts.cookingFatIds};
      for (final intent in decoded.value!.intents) {
        for (final item in intent.items) {
          for (final d in item.dimensions.where((d) => d.kind == .fat)) {
            for (final o in d.options) {
              if (o.effect case ProposalComponentEffect(food: final food?)) {
                cookingFatIds.add(food.key);
              }
            }
          }
        }
      }
      for (final intent in decoded.value!.intents.where(
        (i) => i.kind == 'foodLog',
      )) {
        var time = context.referenceTime;
        if (intent.timeHint == 'yesterday') {
          time = time.onDate(time.localDate.plusDays(-1));
        }
        final active = context.slots.where(
          (s) => s.active && s.mode == context.mode,
        );
        final explicit = active
            .where(
              (s) =>
                  s.id == intent.slotHint ||
                  s.defaultKey == intent.slotHint ||
                  s.name == intent.slotHint,
            )
            .firstOrNull;
        final slot =
            explicit?.id ??
            const SlotAssigner().assign(
              time.localDateTime.time.minuteOfDay,
              context.slots,
              context.mode,
            );
        if (slot == null) throw const _Invalid(ProposalIssue.needsConversion);
        final key = '${time.localDate}:$slot';
        final card = cards.putIfAbsent(
          key,
          () => _CardBuilder(_id(request.idSource)),
        );
        final group = intent.dishGroup == null ? null : _id(request.idSource);
        if (group != null) {
          card.groups.add(
            CreateDishGroup(
              id: group,
              name: intent.dishGroup!,
              date: time.localDate,
              slotId: slot,
            ),
          );
        }
        // Explicit classified cooking fats already present in this meal must
        // not be synthesized again from an unstated-fat dimension.
        final hasExplicitFat = intent.items.any(
          (i) => i.explicit && cookingFatIds.contains(i.match?.key),
        );
        for (final item in intent.items) {
          final id = _id(request.idSource);
          final oilId = _id(
            request.idSource,
          ); // Reserved even when not used yet.
          try {
            final selections = <String, ProposalOption>{};
            final origins = <String, ProposalChoiceOrigin>{};
            for (final d in item.dimensions) {
              if (d.options.isEmpty) continue;
              final explicitChoice = d.options
                  .where((o) => o.id == context.choices[d.id])
                  .firstOrNull;
              final stated = d.options
                  .where((o) => o.value == d.stated)
                  .firstOrNull;
              final qk = _questionKind(d.kind, item.match);
              final saved = d.options
                  .where(
                    (o) =>
                        o.id == context.savedDefaults[qk] ||
                        _optionCode(o) == context.savedDefaults[qk],
                  )
                  .firstOrNull;
              selections[d.id] =
                  explicitChoice ??
                  stated ??
                  saved ??
                  d.options
                      .where(
                        (o) =>
                            o.effect is ProposalFoodEffect &&
                            (o.effect as ProposalFoodEffect).food.key ==
                                item.match?.key,
                      )
                      .firstOrNull ??
                  d.options.first;
              origins[d.id] = explicitChoice != null
                  ? .userAdjusted
                  : d.stated != null
                  ? .stated
                  : saved != null
                  ? .savedDefault
                  : .fallback;
            }
            List<ProposalLine> calculate(Map<String, ProposalOption> choices) =>
                _calculate(
                  item,
                  id,
                  oilId,
                  group,
                  time,
                  slot,
                  choices,
                  origins,
                  converter,
                  cookingFatIds,
                  hasExplicitFat,
                  context.choices,
                );
            final lines = calculate(selections);
            final cookingFat =
                item.explicit &&
                cookingFatIds.contains(lines.first.entry.food.ref.id);
            card.lines.addAll(lines);
            if (!cookingFat) {
              for (final d in item.dimensions) {
                if (origins[d.id] != ProposalChoiceOrigin.fallback ||
                    d.options.length < 2 ||
                    (d.kind == .fat && hasExplicitFat)) {
                  continue;
                }
                final impacts = <double>[];
                for (final o in d.options) {
                  impacts.add(
                    _sum(
                      calculate({...selections, d.id: o})
                          .map((l) => l.snapshot),
                    ).kcal,
                  );
                }
                final low = impacts.reduce((a, b) => a < b ? a : b);
                final high = impacts.reduce((a, b) => a > b ? a : b);
                if (!request.policy.asks(low, high)) continue;
                final picked = <String>{
                  selections[d.id]!.id,
                  d.options[impacts.indexOf(low)].id,
                  d.options[impacts.indexOf(high)].id,
                };
                for (final o in d.options) {
                  if (picked.length < 4) picked.add(o.id);
                }
                questions.add(
                  ProposalQuestion(
                    dimensionId: d.id,
                    kind: d.kind.name,
                    subject: item.match?.yieldGroup ?? item.match?.key,
                    impact: high - low,
                    optionIds: picked,
                  ),
                );
              }
            }
          } on _Invalid catch (e) {
            card.issues.add(e.issue);
          }
        }
      }
      final built = <ProposalCard>[];
      for (final card in cards.values) {
        final ops = <ChangeOp>[];
        if (card.issues.isEmpty && card.lines.isNotEmpty) {
          for (final line in card.lines) {
            if (line.entry.food.ref.kind == FoodRefKind.personal) {
              final local = request.facts.personal[line.entry.food.ref.id]!;
              ops.add(
                RequirePersonalFood(
                  VersionedId(local.key, local.personalVersion!),
                ),
              );
            }
          }
          ops
            ..addAll(card.groups)
            ..add(LogEntries(card.lines.map((l) => l.entry)));
        }
        built.add(
          ProposalCard._(
            id: card.id,
            originMessageId: request.messageId,
            budgetMessageId: request.messageId,
            lines: card.lines,
            draftOps: ops,
            issues: card.issues,
          ),
        );
      }
      return ProposalResult.success(
        ProposalSession._(
          built,
          QuestionBudget.select(questions),
          decoded.value!.intents.where((i) => i.kind != 'foodLog'),
        ),
      );
    } on _Invalid catch (e) {
      return ProposalResult.failure(e.issue);
    }
    // Existing unit/rounding/ID primitives throw ArgumentError. Translate at
    // this untrusted-input boundary; never expose their content-bearing text.
    // ignore: avoid_catching_errors
    on ArgumentError {
      return const ProposalResult.failure(ProposalIssue.invalidInput);
    }
  }
}

final class _CardBuilder {
  new(this.id);
  final String id;
  final lines = <ProposalLine>[];
  final groups = <CreateDishGroup>[];
  final issues = <ProposalIssue>[];
}

String _id(ProposalIdSource source) {
  final id = source.next();
  if (!isUuidV7(id)) throw const _Invalid();
  return id;
}

String _questionKind(ProposalDimensionKind kind, ProposalFood? food) =>
    '${kind.name}:${food?.yieldGroup ?? food?.key ?? '*'}';

String _optionCode(ProposalOption o) {
  if (o.effect case ProposalComponentEffect(quantity: final q?)) {
    return '${o.value}:${q.amount}:${q.unitCode}';
  }
  return o.value;
}

List<ProposalLine> _calculate(
  ProposalItem item,
  String id,
  String oilId,
  String? group,
  EntryTime time,
  String slot,
  Map<String, ProposalOption> choices,
  Map<String, ProposalChoiceOrigin> origins,
  YieldConverter converter,
  Set<String> cookingFatIds,
  bool hasExplicitFat,
  Map<String, String> directChoices,
) {
  var food = item.match;
  var quantity = item.quantity;
  ProposalComponentEffect? component;
  var retention = 1.0;
  var share = 1.0;
  var shareSelected = false;
  FoodState? statedState;
  final chips = <ProposalChip>[];
  for (final d in item.dimensions) {
    final selected = choices[d.id];
    if (d.kind == .state && d.stated != null) {
      statedState = FoodState.fromCode(d.stated!);
    }
    if (selected == null) continue;
    chips.add(ProposalChip(d.id, selected.id, origins[d.id]!));
    switch (selected.effect) {
      case ProposalFoodEffect(food: final f):
        food = f;
      case ProposalQuantityEffect(quantity: final q):
        quantity = q;
      case final ProposalComponentEffect c:
        component = c;
      case ProposalRetentionEffect(fraction: final f):
        retention = f;
      case ProposalShareEffect(fraction: final f):
        share = f;
        shareSelected = true;
    }
  }
  if (item.explicit) {
    share = 1;
  } else if (!shareSelected) {
    share = item.fraction ?? (item.people == null ? 1 : 1 / item.people!);
  }
  final estimate = food == null;
  final per100 =
      food?.per100 ?? (item.estimate!.low + item.estimate!.high).scale(.5);
  // The decoder rejects unmatched/no-amount input; only matched foods can
  // reach this fallback. Never invent grams for an unmatched estimate.
  quantity ??= DefaultPortion.choose(food!.measures);
  final measures = food?.measures ?? FoodMeasures(basis: .per100g);
  final resolution = measures.resolve(quantity);
  if (resolution is! Resolved) {
    throw const _Invalid(ProposalIssue.needsConversion);
  }
  var amount = resolution.amount;
  YieldNote? yieldNote;
  if (statedState != null && food != null && statedState != food.state) {
    if (food.yieldGroup == null || measures.basis != NutrientBasis.per100g) {
      throw const _Invalid(ProposalIssue.needsConversion);
    }
    yieldNote = converter.convert(
      amount: Mass.grams(amount),
      group: food.yieldGroup!,
      from: statedState,
      to: food.state,
    );
    if (yieldNote == null) throw const _Invalid(ProposalIssue.needsConversion);
    amount = yieldNote.toAmount.grams;
  }
  final oil = cookingFatIds.contains(food?.key);
  final retentionId = '${item.id}/oilRetention';
  final retentionDimension = ProposalDimension(retentionId, .oilRetention, [
    ProposalOption('$retentionId/all', 'all', const ProposalRetentionEffect(1)),
    ProposalOption(
      '$retentionId/most',
      'most',
      const ProposalRetentionEffect(ProposalPolicyConstants.mostOilLeft),
    ),
  ]);
  final explicitRetention = directChoices[retentionId];
  if (explicitRetention == 'most' || explicitRetention == '$retentionId/most') {
    retention = ProposalPolicyConstants.mostOilLeft;
  } else if (explicitRetention == 'all' ||
      explicitRetention == '$retentionId/all') {
    retention = 1;
  }
  final assumptions = <String>[
    for (final chip in chips) 'a1:origin:${chip.origin.name}',
    if (yieldNote != null) _yieldCode(yieldNote),
    if (share != 1)
      'a1:share:${item.fraction == null ? '1' : item.fraction.toString()}/${item.fraction == null ? item.people ?? 1 : 1}',
    if (oil) 'a1:oil:${retention == 1 ? 'all' : 'most'}',
  ];
  if (oil) {
    chips.add(
      ProposalChip(
        retentionId,
        '$retentionId/${retention == 1 ? 'all' : 'most'}',
        explicitRetention == null ? .fallback : .userAdjusted,
      ),
    );
  }
  final uncertain =
      estimate ||
      item.quantity == null ||
      !item.explicit ||
      food.source == FoodSource.reference;
  final range = estimate ? item.estimate : food.range;
  final serving = food?.servings
      .where((s) => s.code == quantity!.unitCode)
      .firstOrNull;
  final factor = share * (oil ? retention : 1);
  final lowAmount = (!item.explicit && serving?.low != null)
      ? amount * serving!.low! / serving.amount
      : amount;
  final highAmount = (!item.explicit && serving?.high != null)
      ? amount * serving!.high! / serving.amount
      : amount;
  final absoluteRange = uncertain
      ? EstimateRange(
          (range?.low.kcal ?? per100.kcal) * lowAmount * factor / 100,
          (range?.high.kcal ?? per100.kcal) * highAmount * factor / 100,
        )
      : null;
  final snapshot = const NutritionCalculator().forAmount(
    per100: per100,
    amount: amount * factor,
    basis: measures.basis,
    input: quantity,
  );
  final entry = NewDiaryEntry(
    id: id,
    when: EntryWhen.at(time),
    slotId: slot,
    dishGroupId: group,
    amount: EntryAmount(
      input: quantity,
      amount: snapshot.amount,
      basis: measures.basis,
    ),
    food: EntryFood(
      ref: food?.ref ?? FoodRef.estimate(),
      names: food?.names ?? FoodNames(item.displayName),
      per100: per100,
      provenance: Provenance(
        source: food?.source ?? .estimate,
        isEstimate: uncertain,
        range: absoluteRange,
        assumptions: assumptions,
      ),
    ),
  );
  final lines = <ProposalLine>[
    ProposalLine(
      entry: entry,
      snapshot: snapshot.nutrients,
      factOrigin: food?.origin ?? .embeddedServer,
      chips: List.unmodifiable(chips),
      range: absoluteRange,
      yieldNote: yieldNote,
      dimensions: [...item.dimensions, if (oil) retentionDimension],
    ),
  ];
  if (!hasExplicitFat && component?.food != null) {
    final oilFood = component!.food!;
    final q = component.quantity!;
    final resolved = oilFood.measures.resolve(q);
    if (resolved is! Resolved) {
      throw const _Invalid(ProposalIssue.needsConversion);
    }
    final oilSnapshot = const NutritionCalculator().forAmount(
      per100: oilFood.per100,
      amount: resolved.amount * share * retention,
      basis: resolved.basis,
      input: q,
    );
    final oilChips = List<ProposalChip>.unmodifiable([
      ProposalChip(
        retentionId,
        '$retentionId/${retention == 1 ? 'all' : 'most'}',
        explicitRetention == null ? .fallback : .userAdjusted,
      ),
    ]);
    lines.add(
      ProposalLine(
        entry: NewDiaryEntry(
          id: oilId,
          when: EntryWhen.at(time),
          slotId: slot,
          dishGroupId: group,
          food: EntryFood(
            ref: oilFood.ref,
            names: oilFood.names,
            per100: oilFood.per100,
            provenance: Provenance(
              source: oilFood.source,
              assumptions: ['a1:oil:${retention == 1 ? 'all' : 'most'}'],
            ),
          ),
          amount: EntryAmount(
            input: q,
            amount: oilSnapshot.amount,
            basis: resolved.basis,
          ),
        ),
        snapshot: oilSnapshot.nutrients,
        factOrigin: oilFood.origin,
        chips: oilChips,
        dimensions: [retentionDimension],
      ),
    );
  }
  return lines;
}

Nutrients _sum(Iterable<Nutrients> values) {
  final all = values.toList();
  double field(double Function(Nutrients) get) =>
      all.fold<int>(0, (s, n) => s + (get(n) * 100).round()) / 100;
  return Nutrients(
    kcal: field((n) => n.kcal),
    protein: field((n) => n.protein),
    carbs: field((n) => n.carbs),
    fat: field((n) => n.fat),
    fiber: field((n) => n.fiber),
  );
}

String _yieldCode(YieldNote note) =>
    'a1:yield:${note.fromState.code}:${note.toState.code}:'
    '${note.fromAmount.grams}:${note.toAmount.grams}';
