part of 'proposal_input.dart';

/// Compact JSON fields ready for the future B18 opaque envelopes.
final class ProposalSyncProjection extends ProposalValue {
  /// Three separately bounded UTF-16 JSON fields; never truncates a draft.
  const new(this.interpretation, this.draft, this.messageBudget);

  /// Only this card's normalized intents, referring to its fact table.
  final String interpretation;

  /// Canonical inputs/identities, without derived ops/totals.
  final String draft;

  /// Stored once on the current assistant message, never each proposal row.
  final String messageBudget;
  @override
  List<Object?> get _values => [interpretation, draft, messageBudget];
}

/// Pure versioned codec. No persistence, I/O, ID allocation or trusted totals.
abstract final class ProposalDraftCodec {
  /// B18 measures .NET string.Length, the same as Dart UTF-16 length.
  static const syncStringLimit = 32768;

  /// Canonical local projection; [syncProjection] separately enforces B18 size.
  static Map<String, Object?> encodeCard(
    ProposalSession session,
    String cardId,
  ) {
    final card = session.cards.firstWhere((c) => c.id == cardId);
    final s = session._state;
    final foods = <ProposalFood>[];
    final intents = s.request.interpretation.value!.intents
        .where((i) => s.intentCards[i.index] == cardId)
        .toList();
    final itemIds = {
      for (final i in intents)
        for (final item in i.items) item.id,
    };
    final serialized = [for (final i in intents) _writeIntent(i, foods)];
    final edits = [
      for (final id in itemIds)
        if (s.items[id] case final item?) _writeItem(item, foods),
    ];
    final components = {
      for (final id in itemIds)
        if (s.components[id] case final c?) id: _writeEffect(c, foods),
    };
    final adds = [
      for (final e in s.adds.entries)
        if (s.addOwners[e.key] == cardId) [e.key, _writeItem(e.value, foods)],
    ];
    return {
      'codecVersion': 1,
      'id': cardId,
      'originMessageId': card.originMessageId,
      'budgetMessageId': card.budgetMessageId,
      'revision': s.revision,
      'environment': _writeEnvironment(s.request.context),
      'status': card.lifecycle == .active ? 'pending' : card.lifecycle.name,
      'owned': [
        for (final id in s.issued)
          if (s.questionOwners[id] == cardId) id,
      ],
      'interpretation': serialized,
      'foods': [for (final f in foods) _writeFood(f)],
      'edits': edits,
      'components': components,
      'adds': adds,
      'removed': s.removed.where(itemIds.contains).toList(),
      'choices': {
        for (final e in s.choices.entries)
          if (itemIds.any((id) => e.key.startsWith('$id/'))) e.key: e.value,
      },
      'ids': {
        for (final id in itemIds) 'item:$id': s.ids['item:$id'],
        for (final id in itemIds) 'oil:$id': s.ids['oil:$id'],
        for (final i in intents) 'group:${i.index}': ?s.ids['group:${i.index}'],
      },
      'times': {
        for (final i in intents)
          if (s.times[i.index] case final time?) '${i.index}': _writeTime(time),
      },
      'slots': {for (final i in intents) '${i.index}': ?s.slots[i.index]},
      'cookingFatIds': s.request.facts.cookingFatIds.toList(),
    };
  }

  /// Exactly one shared budget field on the current assistant message.
  static Map<String, Object?> encodeMessageBudget(
    ProposalSession session, {
    Iterable<String> movedCardIds = const [],
  }) {
    final moved = {...session._state.departedCards, ...movedCardIds};
    if (!moved.every(
      (id) =>
          session._state.departedCards.contains(id) ||
          session.cards.any((c) => c.id == id),
    )) {
      throw const _Invalid();
    }
    return {
      'codecVersion': 1,
      'messageId': session._state.request.messageId,
      'revision': session._state.revision,
      'policy': [
        session._state.request.policy.relativeDelta,
        session._state.request.policy.kcalDelta,
      ],
      'cards': [
        for (final c in session.cards)
          if (!moved.contains(c.id)) c.id,
      ],
      'departed': moved.toList(),
      'issued': {
        for (final id in session._state.issued)
          id: session._state.questionOwners[id],
      },
      'open': [
        for (final q in session.budget.questions)
          if (!moved.contains(session._state.questionOwners[q.dimensionId]))
            q.dimensionId,
      ],
    };
  }

  /// Checks each opaque field without losing the full local pending session.
  static ProposalResult<ProposalSyncProjection> syncProjection(
    ProposalSession session,
    String cardId,
  ) {
    final card = encodeCard(session, cardId);
    final interpretation = jsonEncode(card.remove('interpretation'));
    final draft = jsonEncode(card);
    final message = jsonEncode(encodeMessageBudget(session));
    if (![interpretation, draft, message].every(fitsSyncString)) {
      return const ProposalResult.failure(ProposalIssue.syncPayloadTooLarge);
    }
    return ProposalResult.success(
      ProposalSyncProjection(interpretation, draft, message),
    );
  }

  /// Public boundary helper pins supplementary characters to UTF-16 units.
  static bool fitsSyncString(String value) => value.length <= syncStringLimit;

  /// Message plus current member rows, selected by budgetMessageId (not
  /// origin).
  static ProposalBuildResult restore(
    Map<String, Object?> message,
    Iterable<Map<String, Object?>> cards, {
    required ProposalContext context,
  }) {
    try {
      if (message.isEmpty) {
        throw const _Invalid(ProposalIssue.sessionIncomplete);
      }
      _bound(message, 0);
      _keys(message, const [
        'codecVersion',
        'messageId',
        'revision',
        'policy',
        'cards',
        'issued',
        'open',
        'departed',
      ]);
      _version(message);
      final messageId = _text(message, 'messageId');
      final revision = _integer(message['revision']);
      final expected = _strings(message['cards']);
      if (expected.toSet().length != expected.length) {
        throw const _Invalid(ProposalIssue.budgetConflict);
      }
      final rows = cards.toList();
      if (rows.length > ProposalPolicyConstants.maxIntents) {
        throw const _Invalid(ProposalIssue.inputTooLarge);
      }
      if (rows.length < expected.length) {
        throw const _Invalid(ProposalIssue.sessionIncomplete);
      }
      final policy = _array(message['policy'], 2);
      final relative = _double(policy[0]);
      final kcal = _double(policy[1]);
      if (relative < 0 || relative > 1 || kcal < 0 || kcal > 10000) {
        throw const _Invalid();
      }
      final departed = _strings(message['departed']).toSet();
      if (departed.any(expected.contains) || !departed.every(isUuidV7)) {
        throw const _Invalid(ProposalIssue.budgetConflict);
      }
      final issued = _stringMap(message['issued']);
      if (!issued.values.every(
        (id) => expected.contains(id) || departed.contains(id),
      )) {
        throw const _Invalid(ProposalIssue.budgetConflict);
      }
      final open = _strings(message['open']);
      if (issued.length > 2 || !open.every(issued.containsKey)) {
        throw const _Invalid(ProposalIssue.budgetConflict);
      }
      final state = _EngineState()
        ..allocationsAllowed = false
        ..revision = revision
        ..departedCards.addAll(departed)
        ..issued.addAll(issued.keys)
        ..questionOwners.addAll(issued);
      final intents = <ProposalIntent>[];
      final owned = <String, String>{};
      final seen = <String>{};
      final fats = <String>{};
      final identities = <String>{};
      final structuralItems = <String>{};
      ProposalContext? frozen;
      Object? environment;
      var bytes = utf8.encode(jsonEncode(message)).length;
      for (final row in rows) {
        _bound(row, 0, collectionLimit: 512);
        bytes += utf8.encode(jsonEncode(row)).length;
        if (bytes > ProposalPolicyConstants.maxInputBytes) {
          throw const _Invalid(ProposalIssue.inputTooLarge);
        }
        _version(row);
        _keys(row, const [
          'codecVersion',
          'id',
          'originMessageId',
          'budgetMessageId',
          'revision',
          'status',
          'owned',
          'interpretation',
          'foods',
          'edits',
          'components',
          'adds',
          'removed',
          'choices',
          'ids',
          'times',
          'slots',
          'cookingFatIds',
          'environment',
        ]);
        if (environment != null &&
            jsonEncode(environment) != jsonEncode(row['environment'])) {
          throw const _Invalid(ProposalIssue.budgetConflict);
        }
        environment = row['environment'];
        frozen ??= _readEnvironment(environment, context);
        final id = _text(row, 'id');
        if (!expected.contains(id) ||
            !seen.add(id) ||
            row['budgetMessageId'] != messageId ||
            row['revision'] != revision) {
          throw const _Invalid(ProposalIssue.budgetConflict);
        }
        final origin = _text(row, 'originMessageId');
        if (!isUuidV7(id) || !isUuidV7(origin)) throw const _Invalid();
        state.origins[id] = origin;
        final status = _text(row, 'status');
        state.lifecycles[id] = status == 'pending'
            ? .active
            : ProposalLifecycle.values
                      .where((v) => v != .active && v.name == status)
                      .firstOrNull ??
                  (throw const _Invalid());
        for (final q in _strings(row['owned'])) {
          if (owned.containsKey(q)) {
            throw const _Invalid(ProposalIssue.budgetConflict);
          }
          owned[q] = id;
        }
        final foods = [for (final f in _array(row['foods'])) _readFood(f)];
        final current = [
          for (final i in _array(row['interpretation'])) _readIntent(i, foods),
        ];
        for (final i in current) {
          if (state.intentCards.containsKey(i.index)) {
            throw const _Invalid(ProposalIssue.budgetConflict);
          }
          state.intentCards[i.index] = id;
          intents.add(i);
        }
        for (final i in current) {
          for (final item in i.items) {
            if (!structuralItems.add(item.id)) throw const _Invalid();
          }
        }
        final itemIds = {
          for (final i in current)
            for (final item in i.items) item.id,
        };
        for (final e in _map(row['components']).entries) {
          final effect = _readEffect(e.value, foods);
          if (!itemIds.contains(e.key) ||
              effect is! ProposalComponentEffect ||
              effect.food == null) {
            throw const _Invalid();
          }
          state.components[e.key] = effect;
        }
        for (final raw in _array(row['edits'])) {
          final item = _readItem(raw, foods);
          if (!itemIds.contains(item.id) || state.items.containsKey(item.id)) {
            throw const _Invalid();
          }
          state.items[item.id] = item;
        }
        for (final raw in _array(row['adds'])) {
          final pair = _array(raw, 2);
          final token = _string(pair[0]);
          if (state.adds.containsKey(token)) throw const _Invalid();
          state.adds[token] = _readItem(pair[1], foods);
          state.addOwners[token] = id;
        }
        final removed = _strings(row['removed']);
        if (!removed.every(itemIds.contains)) throw const _Invalid();
        state.removed.addAll(removed);
        final choices = _stringMap(row['choices']);
        if (!choices.keys.every(
          (k) => itemIds.any((i) => k.startsWith('$i/')),
        )) {
          throw const _Invalid();
        }
        state.choices.addAll(choices);
        final ids = _stringMap(row['ids']);
        for (final e in ids.entries) {
          if (!isUuidV7(e.value) ||
              state.ids.containsKey(e.key) ||
              !identities.add(e.value)) {
            throw const _Invalid();
          }
          state.ids[e.key] = e.value;
        }
        for (final e in _map(row['times']).entries) {
          final index = int.tryParse(e.key);
          if (index == null || !current.any((i) => i.index == index)) {
            throw const _Invalid();
          }
          state.times[index] = _readTime(e.value);
        }
        for (final e in _stringMap(row['slots']).entries) {
          final index = int.tryParse(e.key);
          if (index == null || !current.any((i) => i.index == index)) {
            throw const _Invalid();
          }
          state.slots[index] = e.value;
        }
        fats.addAll(_strings(row['cookingFatIds']));
      }
      if (owned.length !=
              issued.values.where((id) => !departed.contains(id)).length ||
          !owned.entries.every((e) => issued[e.key] == e.value)) {
        throw const _Invalid(ProposalIssue.budgetConflict);
      }
      if (seen.length != expected.length) {
        throw const _Invalid(ProposalIssue.sessionIncomplete);
      }
      intents.sort((a, b) => a.index.compareTo(b.index));
      if (intents.length > 20 ||
          intents.fold<int>(0, (n, i) => n + i.items.length) > 50) {
        throw const _Invalid(ProposalIssue.inputTooLarge);
      }
      // Restore freezes source facts and identities. Only confirmed intake
      // and target context refresh; a newer pack cannot change a saved draft.
      final facts = ProposalFacts(cookingFatIds: fats);
      final request = ProposalRequest._(
        ProposalInterpretation(intents),
        messageId,
        frozen ?? context,
        facts,
        ProposalPolicy._(relative, kcal),
        null,
      );
      state.request = request;
      _validateChoices(state);
      final result = ProposalEngine._build(request, state);
      if (result.issue case final issue?) return ProposalResult.failure(issue);
      final rebuilt = result.value!;
      if (!_same(
            open,
            rebuilt.budget.questions.map((q) => q.dimensionId).toList(),
          ) ||
          state.issued.length != issued.length) {
        throw const _Invalid(ProposalIssue.budgetConflict);
      }
      return result;
    } on _Invalid catch (e) {
      return ProposalResult.failure(e.issue);
    } on FormatException {
      return const ProposalResult.failure(ProposalIssue.invalidInput);
    }
    // Domain value constructors may reject corrupt stored inputs.
    // ignore: avoid_catching_errors
    on ArgumentError {
      return const ProposalResult.failure(ProposalIssue.invalidInput);
    }
  }
}

void _keys(Map<String, Object?> m, List<String> keys) {
  if (m.length != keys.length || !m.keys.every(keys.contains)) {
    throw const _Invalid();
  }
}

void _version(Map<String, Object?> m) {
  if (m['codecVersion'] != 1) {
    throw const _Invalid(ProposalIssue.unsupportedCodecVersion);
  }
}

List<Object?> _array(Object? value, [int? length]) {
  if (value is! List<Object?> ||
      (length != null && value.length != length) ||
      value.length > 200) {
    throw const _Invalid();
  }
  return value;
}

String _string(Object? value) {
  if (value is! String || value.isEmpty) throw const _Invalid();
  return value;
}

List<String> _strings(Object? value) => [
  for (final v in _array(value)) _string(v),
];
Map<String, String> _stringMap(Object? value) =>
    _map(value).map((k, v) => MapEntry(k, _string(v)));
int _integer(Object? value) {
  if (value is! int || value < 0) throw const _Invalid();
  return value;
}

double _double(Object? value) {
  if (value is! num || !value.isFinite) throw const _Invalid();
  return value.toDouble();
}

T _enum<T>(List<T> values, Object? index) {
  final n = _integer(index);
  if (n >= values.length) throw const _Invalid();
  return values[n];
}

List<Object?> _writeTime(EntryTime t) => [
  t.occurredAtUtc.millisecondsSinceEpoch,
  t.tzOffsetMin,
];
EntryTime _readTime(Object? value) {
  final v = _array(value, 2);
  if (v[0] is! int || v[1] is! int) throw const _Invalid();
  return EntryTime(
    DateTime.fromMillisecondsSinceEpoch(v[0]! as int, isUtc: true),
    v[1]! as int,
  );
}

List<Object?> _writeNutrients(Nutrients n) => [
  ..._core(n),
  {for (final e in n.extras.entries) e.key.code: e.value},
];
Nutrients _readNutrients(Object? value) {
  final raw = _array(value, 6);
  final v = raw.take(5).map(_double).toList();
  final extras = <NutrientKey, double>{};
  for (final e in _map(raw[5]).entries) {
    final key = NutrientKey.fromCode(e.key);
    if (key == null) throw const _Invalid();
    extras[key] = _double(e.value);
  }
  return Nutrients(
    kcal: v[0],
    protein: v[1],
    carbs: v[2],
    fat: v[3],
    fiber: v[4],
    extras: extras,
  );
}

Object? _writeRange(ProposalRange? r) =>
    r == null ? null : [_writeNutrients(r.low), _writeNutrients(r.high)];
ProposalRange? _readRange(Object? value) {
  if (value == null) return null;
  final v = _array(value, 2);
  return ProposalRange(_readNutrients(v[0]), _readNutrients(v[1]));
}

Object? _writeQuantity(Quantity? q) =>
    q == null ? null : [q.amount, q.unitCode];
Quantity? _readQuantity(Object? value) {
  if (value == null) return null;
  final v = _array(value, 2);
  final amount = _double(v[0]);
  if (amount < 0) throw const _Invalid();
  return Quantity(amount, _string(v[1]));
}

List<Object?> _writeFood(ProposalFood f) => [
  f.key,
  f.names.en,
  f.names.ar,
  f.state.index,
  f.source.index,
  _writeNutrients(f.per100),
  f.basis.index,
  f.origin.index,
  f.version,
  f.personalVersion,
  f.density,
  f.yieldGroup,
  _writeRange(f.range),
  [
    for (final s in f.servings)
      [s.code, s.amount, s.basis.index, s.low, s.high],
  ],
];
ProposalFood _readFood(Object? value) {
  final v = _array(value, 14);
  final source = _enum(FoodSource.values, v[4]);
  if (source == FoodSource.estimate) throw const _Invalid();
  final key = _string(v[0]);
  final version = v[9] == null ? null : _integer(v[9]);
  if (source == FoodSource.yours &&
      (!isUuid(key) || version == null || version < 1)) {
    throw const _Invalid();
  }
  final density = v[10] == null ? null : _double(v[10]);
  if (density != null && density <= 0) throw const _Invalid();
  return ProposalFood(
    key: key,
    names: FoodNames(_string(v[1]), ar: _optionalString(v[2])),
    state: _enum(FoodState.values, v[3]),
    source: source,
    per100: _readNutrients(v[5]),
    basis: _enum(NutrientBasis.values, v[6]),
    origin: _enum(ProposalFactOrigin.values, v[7]),
    version: _optionalString(v[8]),
    personalVersion: version,
    density: density,
    yieldGroup: _optionalString(v[11]),
    range: _readRange(v[12]),
    servings: [for (final raw in _array(v[13])) _readServing(raw)],
  );
}

String? _optionalString(Object? value) => value == null ? null : _string(value);
ProposalServing _readServing(Object? raw) {
  final v = _array(raw, 5);
  final amount = _double(v[1]);
  final low = v[3] == null ? null : _double(v[3]);
  final high = v[4] == null ? null : _double(v[4]);
  if (amount <= 0 ||
      (low == null) != (high == null) ||
      (low != null && (low <= 0 || low > amount || high! < amount))) {
    throw const _Invalid();
  }
  return ProposalServing(
    _string(v[0]),
    amount,
    _enum(NutrientBasis.values, v[2]),
    low,
    high,
  );
}

int _foodIndex(ProposalFood f, List<ProposalFood> foods) {
  final index = foods.indexOf(f);
  if (index >= 0) return index;
  foods.add(f);
  return foods.length - 1;
}

ProposalFood _foodAt(Object? value, List<ProposalFood> foods) {
  final index = _integer(value);
  if (index >= foods.length) throw const _Invalid();
  return foods[index];
}

List<Object?> _writeEffect(ProposalEffect e, List<ProposalFood> foods) =>
    switch (e) {
      ProposalFoodEffect(:final food) => [0, _foodIndex(food, foods)],
      ProposalQuantityEffect(:final quantity) => [1, _writeQuantity(quantity)],
      ProposalComponentEffect(:final food, :final quantity) => [
        2,
        if (food == null) null else _foodIndex(food, foods),
        _writeQuantity(quantity),
      ],
      ProposalRetentionEffect(:final fraction) => [3, fraction],
      ProposalShareEffect(:final fraction) => [4, fraction],
    };
ProposalEffect _readEffect(Object? value, List<ProposalFood> foods) {
  final v = _array(value);
  if (v.isEmpty) throw const _Invalid();
  switch (v[0]) {
    case 0:
      _array(v, 2);
      return ProposalFoodEffect(_foodAt(v[1], foods));
    case 1:
      _array(v, 2);
      final q = _readQuantity(v[1]);
      if (q == null) throw const _Invalid();
      return ProposalQuantityEffect(q);
    case 2:
      _array(v, 3);
      final q = _readQuantity(v[2]);
      if ((v[1] == null) != (q == null)) throw const _Invalid();
      return ProposalComponentEffect(
        v[1] == null ? null : _foodAt(v[1], foods),
        q,
      );
    case 3:
    case 4:
      _array(v, 2);
      final fraction = _double(v[1]);
      if (fraction <= 0 ||
          fraction > 1 ||
          (v[0] == 3 && fraction != 1 && fraction != .25)) {
        throw const _Invalid();
      }
      return v[0] == 3
          ? ProposalRetentionEffect(fraction)
          : ProposalShareEffect(fraction);
    default:
      throw const _Invalid();
  }
}

List<Object?> _writeItem(ProposalItem i, List<ProposalFood> foods) => [
  i.id,
  if (i.match == null) null else _foodIndex(i.match!, foods),
  _writeQuantity(i.quantity),
  i.explicit,
  [for (final f in i.alternatives) _foodIndex(f, foods)],
  [
    for (final d in i.dimensions)
      [
        d.id,
        d.kind.index,
        d.stated,
        [
          for (final o in d.options)
            [o.id, o.value, _writeEffect(o.effect, foods)],
        ],
      ],
  ],
  _writeRange(i.estimate),
  i.fraction,
  i.people,
  if (i.match == null) i.displayName else null,
];
ProposalItem _readItem(Object? value, List<ProposalFood> foods) {
  final v = _array(value, 10);
  if (v[3] is! bool) throw const _Invalid();
  final food = v[1] == null ? null : _foodAt(v[1], foods);
  final estimate = _readRange(v[6]);
  final q = _readQuantity(v[2]);
  if (food == null && (estimate == null || q == null)) throw const _Invalid();
  final fraction = v[7] == null ? null : _double(v[7]);
  final people = v[8] == null ? null : _integer(v[8]);
  if ((fraction != null && (fraction <= 0 || fraction > 1)) || people == 0) {
    throw const _Invalid();
  }
  final alternatives = [for (final f in _array(v[4])) _foodAt(f, foods)];
  final dimensions = <ProposalDimension>[];
  for (final raw in _array(v[5])) {
    final d = _array(raw, 4);
    final options = <ProposalOption>[];
    for (final raw in _array(d[3])) {
      final o = _array(raw, 3);
      options.add(
        ProposalOption(_string(o[0]), _string(o[1]), _readEffect(o[2], foods)),
      );
    }
    if (options.length > 32 ||
        options.map((o) => o.id).toSet().length != options.length) {
      throw const _Invalid();
    }
    final kind = _enum(ProposalDimensionKind.values, d[1]);
    if (!options.every(
      (o) => switch (kind) {
        ProposalDimensionKind.state ||
        ProposalDimensionKind.variant => o.effect is ProposalFoodEffect,
        ProposalDimensionKind.fat => o.effect is ProposalComponentEffect,
        ProposalDimensionKind.portion => o.effect is ProposalQuantityEffect,
        ProposalDimensionKind.oilRetention =>
          o.effect is ProposalRetentionEffect,
        ProposalDimensionKind.share => o.effect is ProposalShareEffect,
      },
    )) {
      throw const _Invalid();
    }
    dimensions.add(
      ProposalDimension(
        _string(d[0]),
        kind,
        options,
        stated: _optionalString(d[2]),
      ),
    );
  }
  if (alternatives.length > 3 ||
      dimensions.length > 8 ||
      dimensions.map((d) => d.id).toSet().length != dimensions.length) {
    throw const _Invalid();
  }
  return ProposalItem(
    id: _string(v[0]),
    displayName: food?.names.en ?? _string(v[9]),
    match: food,
    quantity: q,
    explicit: v[3]! as bool,
    alternatives: alternatives,
    dimensions: dimensions,
    estimate: estimate,
    fraction: fraction,
    people: people,
  );
}

List<Object?> _writeIntent(ProposalIntent i, List<ProposalFood> foods) => [
  i.index,
  i.timeHint,
  i.slotHint,
  i.dishGroup,
  [for (final item in i.items) _writeItem(item, foods)],
];
ProposalIntent _readIntent(Object? value, List<ProposalFood> foods) {
  final v = _array(value, 5);
  return ProposalIntent(
    index: _integer(v[0]),
    kind: 'foodLog',
    timeHint: _optionalString(v[1]),
    slotHint: _optionalString(v[2]),
    dishGroup: _optionalString(v[3]),
    items: [for (final i in _array(v[4])) _readItem(i, foods)],
  );
}

List<Object?> _writeEnvironment(ProposalContext c) => [
  _writeTime(c.referenceTime),
  c.mode.index,
  [
    for (final s in c.slots)
      [
        s.id,
        s.sortOrder,
        s.defaultKey,
        s.name,
        s.window?.startMin,
        s.window?.endMin,
        s.mode.index,
        s.active,
      ],
  ],
  [
    for (final y in c.yields) [y.group, y.from.index, y.to.index, y.factor],
  ],
  c.savedDefaults,
  c.choices,
];
ProposalContext _readEnvironment(Object? raw, ProposalContext current) {
  final v = _array(raw, 6);
  return ProposalContext(
    referenceTime: _readTime(v[0]),
    mode: _enum(SlotMode.values, v[1]),
    dayContext: current.dayContext,
    normalize: current.normalize,
    slots: [for (final raw in _array(v[2])) _readSlot(raw)],
    yields: [for (final raw in _array(v[3])) _readYield(raw)],
    savedDefaults: _stringMap(v[4]),
    choices: _stringMap(v[5]),
  );
}

MealSlot _readSlot(Object? raw) {
  final v = _array(raw, 8);
  if (v[7] is! bool) throw const _Invalid();
  return MealSlot(
    id: _string(v[0]),
    sortOrder: _integer(v[1]),
    defaultKey: _optionalString(v[2]),
    name: _optionalString(v[3]),
    window: TimeWindow.fromBounds(
      v[4] == null ? null : _integer(v[4]),
      v[5] == null ? null : _integer(v[5]),
    ),
    mode: _enum(SlotMode.values, v[6]),
    active: v[7]! as bool,
  );
}

YieldFactor _readYield(Object? raw) {
  final v = _array(raw, 4);
  return YieldFactor(
    group: _string(v[0]),
    from: _enum(FoodState.values, v[1]),
    to: _enum(FoodState.values, v[2]),
    factor: _double(v[3]),
  );
}

Map<String, Set<String>> _choiceOptions(_EngineState state) {
  final dimensions = <String, Set<String>>{};
  for (final intent in state.request.interpretation.value!.intents) {
    for (final original in intent.items) {
      final item = state.items[original.id] ?? original;
      for (final d in item.dimensions) {
        dimensions[d.id] = d.options.map((o) => o.id).toSet();
      }
      dimensions['${item.id}/oilRetention'] = {
        '${item.id}/oilRetention/all',
        '${item.id}/oilRetention/most',
      };
    }
  }
  return dimensions;
}

void _validateChoices(_EngineState state) {
  final dimensions = _choiceOptions(state);
  if (!state.choices.entries.every(
    (e) => dimensions[e.key]?.contains(e.value) ?? false,
  )) {
    throw const _Invalid();
  }
}
