part of 'proposal_input.dart';

/// Maps B08's actual public v1 JSON directly into normalized domain values.
abstract final class InterpretationDecoder {
  /// No transport DTOs, I/O, guesses from names, or content-bearing failures.
  static ProposalResult<ProposalInterpretation> decode(
    Map<String, Object?> json,
    ProposalFacts facts,
  ) {
    try {
      _bound(json, 0);
      if (utf8.encode(jsonEncode(json)).length >
          ProposalPolicyConstants.maxInputBytes) {
        throw const _Invalid(ProposalIssue.inputTooLarge);
      }
      if (_text(json, 'promptVersion') != 'interpret-v1') {
        throw const _Invalid();
      }
      _text(json, 'model');
      final intents = <ProposalIntent>[];
      var count = 0;
      for (final (i, raw) in _list(
        json,
        'intents',
        ProposalPolicyConstants.maxIntents,
      ).indexed) {
        final intent = _map(raw);
        final kind = _text(intent, 'kind');
        _text(intent, 'language');
        _text(intent, 'script');
        if (!const [
          'foodLog',
          'clarify',
          'medical',
          'outOfScope',
          'weighIn',
        ].contains(kind)) {
          throw const _Invalid();
        }
        final items = <ProposalItem>[];
        String? time;
        String? slot;
        String? group;
        if (kind == 'foodLog') {
          time = _nullableText(intent, 'timeHint');
          slot = _nullableText(intent, 'slotHint');
          group = _nullableText(intent, 'dishGroup');
          final rawItems = _list(
            intent,
            'items',
            ProposalPolicyConstants.maxItems,
          );
          count += rawItems.length;
          if (count > ProposalPolicyConstants.maxItems) {
            throw const _Invalid(ProposalIssue.inputTooLarge);
          }
          for (final (j, rawItem) in rawItems.indexed) {
            items.add(_item(_map(rawItem), '$i/$j', facts));
          }
        } else if (kind == 'weighIn') {
          _number(intent, 'value', positive: true);
          _text(intent, 'unit');
          time = _nullableText(intent, 'timeHint');
        } else if (kind != 'medical') {
          _text(intent, 'reason');
        }
        intents.add(
          ProposalIntent(
            index: i,
            kind: kind,
            items: items,
            timeHint: time,
            slotHint: slot,
            dishGroup: group,
          ),
        );
      }
      return ProposalResult.success(ProposalInterpretation(intents));
    } on _Invalid catch (e) {
      return ProposalResult.failure(e.issue);
    }
  }
}

ProposalItem _item(Map<String, Object?> m, String id, ProposalFacts facts) {
  final displayName = _text(m, 'mention');
  final match = m['match'] == null ? null : _candidate(_map(m['match']), facts);
  final candidates = <String, ProposalFood>{};
  for (final raw in _list(
    m,
    'alternatives',
    ProposalPolicyConstants.maxOptions,
  )) {
    final food = _candidate(_map(raw), facts);
    if (food.key != match?.key) candidates.putIfAbsent(food.key, () => food);
  }
  if (candidates.length >= ProposalPolicyConstants.maxCandidates) {
    throw const _Invalid(ProposalIssue.inputTooLarge);
  }
  final amount = _map(m['amount']);
  final explicit = amount['explicit'];
  if (explicit is! bool) throw const _Invalid();
  final quantity = _quantity(amount, 'value', 'unit');
  final estimate = m['estimate'] == null
      ? null
      : _range(_map(_map(m['estimate'])['range']));
  if (match == null && estimate == null) throw const _Invalid();
  if (match == null && quantity == null) {
    throw const _Invalid(ProposalIssue.needsAmount);
  }
  double? fraction;
  int? people;
  if (m['share'] != null) {
    final share = _map(m['share']);
    fraction = _nullableNumber(share, 'fraction', positive: true);
    if (fraction != null && fraction > 1) throw const _Invalid();
    final p = share['people'];
    if (p != null) {
      if (p is! int || p <= 0) throw const _Invalid();
      people = p;
    }
  }
  final dimensions = <ProposalDimension>[];
  final available = {...candidates};
  if (match case final food?) available[food.key] = food;
  for (final (di, raw) in _list(
    m,
    'dimensions',
    ProposalPolicyConstants.maxDimensions,
  ).indexed) {
    final d = _map(raw);
    final code = _text(d, 'kind');
    final kind = ProposalDimensionKind.values
        .where((k) => k.name == code)
        .firstOrNull;
    if (kind == null) throw const _Invalid();
    final dimensionId = '$id/$di';
    final options = <ProposalOption>[];
    for (final (oi, rawOption) in _list(
      d,
      'options',
      ProposalPolicyConstants.maxOptions,
    ).indexed) {
      final o = _map(rawOption);
      final value = _text(o, 'value');
      final key = _nullableText(o, 'candidateKey');
      final embedded = o['candidate'] == null
          ? null
          : _candidate(_map(o['candidate']), facts);
      if (embedded != null &&
          embedded.key != (facts.catalogAliases[key] ?? key)) {
        throw const _Invalid(ProposalIssue.factsMismatch);
      }
      final food = embedded ?? available[key];
      if (key != null && food == null) throw const _Invalid();
      final q = _quantity(o, 'amount', 'unit');
      final ProposalEffect effect;
      switch (kind) {
        case ProposalDimensionKind.state:
        case ProposalDimensionKind.variant:
          if (food == null) throw const _Invalid();
          effect = ProposalFoodEffect(food);
        case ProposalDimensionKind.portion:
          if (q == null) throw const _Invalid();
          effect = ProposalQuantityEffect(q);
        case ProposalDimensionKind.fat:
          if (value == 'none' && food == null) {
            effect = const ProposalComponentEffect(null, null);
          } else {
            if (food == null || q == null) throw const _Invalid();
            effect = ProposalComponentEffect(food, q);
          }
        case ProposalDimensionKind.oilRetention:
        case ProposalDimensionKind.share:
          final v = q?.amount;
          if (v == null ||
              v <= 0 ||
              v > 1 ||
              (kind == ProposalDimensionKind.oilRetention &&
                  v != 1 &&
                  v != ProposalPolicyConstants.mostOilLeft)) {
            throw const _Invalid();
          }
          effect = kind == ProposalDimensionKind.oilRetention
              ? ProposalRetentionEffect(v)
              : ProposalShareEffect(v);
      }
      options.add(ProposalOption('$dimensionId/$oi', value, effect));
    }
    dimensions.add(
      ProposalDimension(
        dimensionId,
        kind,
        options,
        stated: _nullableText(d, 'statedValue'),
      ),
    );
  }
  return ProposalItem(
    id: id,
    displayName: displayName,
    match: match,
    quantity: quantity,
    explicit: explicit,
    alternatives: candidates.values,
    dimensions: dimensions,
    estimate: estimate,
    fraction: fraction,
    people: people,
  );
}

ProposalFood _candidate(Map<String, Object?> m, ProposalFacts facts) {
  final inputKey = _text(m, 'key');
  final key = m['source'] == 'personal'
      ? inputKey
      : facts.catalogAliases[inputKey] ?? inputKey;
  final code = _text(m, 'source');
  final source = switch (code) {
    'personal' => FoodSource.yours,
    'usda' || 'database' => FoodSource.database,
    'reference' => FoodSource.reference,
    _ => throw const _Invalid(),
  };
  final stateCode = _text(m, 'state');
  final state = FoodState.fromCode(
    stateCode == 'asSold' ? 'as_sold' : stateCode,
  );
  if (state == null) throw const _Invalid();
  final name = _text(m, 'nameEn');
  final ar = _nullableText(m, 'nameAr');
  final nutrients = _nutrients(_map(m['nutrients']));
  final range = m['ranges'] == null ? null : _range(_map(m['ranges']));
  final density = _nullableNumber(m, 'densityGPerMl', positive: true);
  final group = _nullableText(m, 'yieldGroup');
  final servings = <ProposalServing>[];
  for (final raw in _list(m, 'servings', ProposalPolicyConstants.maxOptions)) {
    final s = _map(raw);
    final g = _nullableNumber(s, 'g', positive: true);
    final ml = _nullableNumber(s, 'ml', positive: true);
    if ((g == null) == (ml == null)) throw const _Invalid();
    final lo = _nullableNumber(s, 'rangeLo', positive: true);
    final hi = _nullableNumber(s, 'rangeHi', positive: true);
    if ((lo == null) != (hi == null) ||
        (lo != null && (lo > (g ?? ml!) || hi! < (g ?? ml!)))) {
      throw const _Invalid();
    }
    final unit = _text(s, 'unitCode');
    _text(s, 'source');
    if (servings.any((s) => s.code == unit)) throw const _Invalid();
    servings.add(
      ProposalServing(
        unit,
        g ?? ml!,
        g == null ? NutrientBasis.per100ml : NutrientBasis.per100g,
        lo,
        hi,
      ),
    );
  }
  final local = source == FoodSource.yours
      ? facts.personal[key]
      : facts.catalog[key];
  if (local != null) {
    if (local.key != key ||
        local.source != source ||
        (source == FoodSource.yours &&
            (!isUuid(key) || (local.personalVersion ?? 0) < 1))) {
      throw const _Invalid(ProposalIssue.factsMismatch);
    }
    return ProposalFood(
      key: local.key,
      names: local.names,
      state: local.state,
      source: local.source,
      per100: local.per100,
      basis: local.basis,
      origin: source == FoodSource.yours
          ? ProposalFactOrigin.localPersonal
          : ProposalFactOrigin.localCatalog,
      version: local.version,
      personalVersion: local.personalVersion,
      density: local.density,
      yieldGroup: local.yieldGroup,
      range: local.range,
      servings: local.servings,
    );
  }
  if (source == FoodSource.yours || facts.packAvailable) {
    throw const _Invalid(ProposalIssue.missingFoodFacts);
  }
  return ProposalFood(
    key: key,
    names: FoodNames(name, ar: ar),
    state: state,
    source: source,
    per100: nutrients,
    range: range,
    density: density,
    yieldGroup: group,
    servings: servings,
  );
}

Map<String, Object?> _map(Object? v) {
  if (v is! Map<String, Object?>) throw const _Invalid();
  return v;
}

String _text(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is! String || v.trim().isEmpty) throw const _Invalid();
  return v;
}

String? _nullableText(Map<String, Object?> m, String key) {
  if (!m.containsKey(key)) throw const _Invalid();
  return m[key] == null ? null : _text(m, key);
}

double _number(Map<String, Object?> m, String key, {bool positive = false}) {
  final v = m[key];
  if (v is! num || !v.isFinite || (positive ? v <= 0 : v < 0)) {
    throw const _Invalid();
  }
  return v.toDouble();
}

double? _nullableNumber(
  Map<String, Object?> m,
  String key, {
  bool positive = false,
}) {
  if (!m.containsKey(key)) throw const _Invalid();
  return m[key] == null ? null : _number(m, key, positive: positive);
}

List<Object?> _list(Map<String, Object?> m, String key, int limit) {
  final v = m[key];
  if (v is! List<Object?>) throw const _Invalid();
  if (v.length > limit) throw const _Invalid(ProposalIssue.inputTooLarge);
  return v;
}

Quantity? _quantity(Map<String, Object?> m, String amount, String unit) {
  final v = _nullableNumber(m, amount);
  final u = _nullableText(m, unit);
  if ((v == null) != (u == null)) throw const _Invalid();
  return v == null ? null : Quantity(v, u!);
}

Nutrients _nutrients(Map<String, Object?> m) => Nutrients(
  kcal: _number(m, 'kcal'),
  protein: _number(m, 'proteinG'),
  carbs: _number(m, 'carbsG'),
  fat: _number(m, 'fatG'),
  fiber: _number(m, 'fiberG'),
);

ProposalRange _range(Map<String, Object?> m) =>
    ProposalRange(_nutrients(_map(m['low'])), _nutrients(_map(m['high'])));

// Bound traversal before encoding, including deeply nested malformed input.
int _bound(Object? value, int depth, {int collectionLimit = 64}) {
  if (depth > 32) throw const _Invalid(ProposalIssue.inputTooLarge);
  var work = 1;
  if (value is String) {
    work += value.length;
  } else if (value is Map<String, Object?>) {
    if (value.length > collectionLimit) {
      throw const _Invalid(ProposalIssue.inputTooLarge);
    }
    for (final e in value.entries) {
      work +=
          _bound(e.key, depth + 1, collectionLimit: collectionLimit) +
          _bound(e.value, depth + 1, collectionLimit: collectionLimit);
      if (work > ProposalPolicyConstants.maxInputBytes) {
        throw const _Invalid(ProposalIssue.inputTooLarge);
      }
    }
  } else if (value is List<Object?>) {
    if (value.length > collectionLimit) {
      throw const _Invalid(ProposalIssue.inputTooLarge);
    }
    for (final v in value) {
      work += _bound(v, depth + 1, collectionLimit: collectionLimit);
      if (work > ProposalPolicyConstants.maxInputBytes) {
        throw const _Invalid(ProposalIssue.inputTooLarge);
      }
    }
  } else if (value is num && !value.isFinite) {
    throw const _Invalid();
  } else if (value != null && value is! num && value is! bool) {
    throw const _Invalid();
  }
  if (work > ProposalPolicyConstants.maxInputBytes) {
    throw const _Invalid(ProposalIssue.inputTooLarge);
  }
  return work;
}
