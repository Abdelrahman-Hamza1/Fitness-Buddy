import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/src/proposals/proposal_input.dart'
    show ProposalInterpretation;
import 'package:test/test.dart';

import 'proposal_fixtures.dart';

ProposalResult<ProposalInterpretation> decode(
  Map<String, Object?> json, [
  ProposalFacts? facts,
]) => InterpretationDecoder.decode(json, facts ?? ProposalFacts());

ProposalItem decodedItem(Map<String, Object?> i, [ProposalFacts? facts]) =>
    decode(
      message([
        intent([i]),
      ]),
      facts,
    ).value!.intents.single.items.single;

void main() {
  // rule: A21 contract-boundary
  test(
    'A21 v1 response decodes candidate facts options and all five intent kinds',
    () {
      final json = message([
        intent([
          item(
            alternatives: [
              food(),
              food(key: 'usda:other'),
              food(key: 'usda:other'),
            ],
          ),
        ]),
        {
          'kind': 'clarify',
          'language': 'ar',
          'script': 'arabic',
          'reason': 'unmatchedFood',
        },
        {
          'kind': 'outOfScope',
          'language': 'en',
          'script': 'latin',
          'reason': 'other',
        },
        {'kind': 'medical', 'language': 'en', 'script': 'latin'},
        {
          'kind': 'weighIn',
          'language': 'en',
          'script': 'latin',
          'value': 90,
          'unit': 'kg',
          'timeHint': null,
        },
      ]);
      final result = decode(json);
      expect(result.issue, isNull);
      expect(result.value!.intents.map((i) => i.kind), [
        'foodLog',
        'clarify',
        'outOfScope',
        'medical',
        'weighIn',
      ]);
      expect(result.value!.intents.first.items.single.alternatives.length, 1);
      expect(result, decode(json));
      expect(result.hashCode, decode(json).hashCode);
      expect(result.toString(), isNot(contains('Synthetic')));
      final f = decodedItem(
        item(
          match: food(state: 'asSold', source: 'database'),
        ),
      ).match!;
      expect(f.state, FoodState.asSold);
      expect(f.ref.kind, FoodRefKind.catalog);
      expect(f.measures.resolve(Quantity(1, 'piece')), isA<Resolved>());
    },
  );
  // rule: A21 fact-precedence
  test('A21 local personal row always wins over embedded facts '
      'and pins its version', () {
    const key = '019a1b2c-0000-7000-8000-000000000001';
    final local = localFood(
      key: key,
      source: .yours,
      basis: .per100ml,
      personalVersion: 7,
    );
    final m = item(
      match: food(key: key, source: 'personal'),
    );
    final f = decodedItem(m, ProposalFacts(personal: {key: local})).match!;
    expect(f.per100, local.per100);
    expect(f.basis, NutrientBasis.per100ml);
    expect(f.personalVersion, 7);
    expect(f.origin, ProposalFactOrigin.localPersonal);
    expect(f.ref, FoodRef.personal(key));
    expect(decodedItem(m, ProposalFacts(personal: {key: local})).match, f);
    expect(
      decode(
        message([
          intent([m]),
        ]),
      ).issue,
      ProposalIssue.missingFoodFacts,
    );
  });
  // rule: A21 fact-precedence
  test('A21 local pack row wins and each line records fact origin', () {
    final local = localFood();
    final facts = ProposalFacts(
      catalog: {local.key: local},
      packAvailable: true,
    );
    final f = decodedItem(item(), facts).match!;
    expect(f.per100, local.per100);
    expect(f.version, '1');
    expect(f.origin, ProposalFactOrigin.localCatalog);
    expect(f.ref.version, '1');
    final ml = localFood(basis: .per100ml);
    expect(ml.measures.resolve(Quantity(1, 'piece')), isA<Resolved>());
    expect(ml.toString(), isNot(contains('Local')));
  });
  // rule: A21 fact-precedence
  test(
    'A21 absent pack uses eligible embedded facts but missing pack key blocks',
    () {
      expect(
        decodedItem(item()).match!.origin,
        ProposalFactOrigin.embeddedServer,
      );
      expect(
        decode(message(), ProposalFacts(packAvailable: true)).issue,
        ProposalIssue.missingFoodFacts,
      );
      final maps = <String, ProposalFood>{};
      final facts = ProposalFacts(catalog: maps);
      maps['changed'] = localFood();
      expect(facts.catalog, isEmpty);
      expect(facts.toString(), 'ProposalFacts(redacted)');
    },
  );
  // rule: A21 input-validation
  test(
    'A21 unknown codes dangling keys and incompatible facts block confirmation',
    () {
      final mutations = <Map<String, Object?> Function()>[
        () => item(match: food(state: 'unknown')),
        () => item(match: food(source: 'unknown')),
        () => item(match: food()..['nameEn'] = ''),
        () => item(match: food()..['densityGPerMl'] = -1),
        () => item(match: food()..['nutrients'] = n(double.nan)),
        () => item(match: food(servings: [serving('piece', 1)..['ml'] = 1])),
        () => item(match: food(servings: [serving('piece', 1)..['g'] = null])),
        () => item(
          match: food(
            servings: [
              serving('piece', 1)
                ..['rangeLo'] = 2
                ..['rangeHi'] = 3,
            ],
          ),
        ),
        () => item(
          match: food(servings: [serving('piece', 1)..['rangeLo'] = .5]),
        ),
        () => item(
          match: food(servings: [serving('piece', 1), serving('piece', 2)]),
        ),
        () => item()..['amount'] = {'value': 1, 'unit': null, 'explicit': true},
        () => item()..['amount'] = {'value': 1, 'unit': 'g', 'explicit': 'yes'},
        () => item(share: {'fraction': 2, 'people': null}),
        () => item(share: {'fraction': null, 'people': 0}),
        () => item(share: {'fraction': null, 'people': 1.5}),
        () => item(dimensions: [dimension('unknown', [])]),
        () => item(
          dimensions: [
            dimension('state', [option('raw')]),
          ],
        ),
        () => item(
          dimensions: [
            dimension('portion', [option('big')]),
          ],
        ),
        () => item(
          dimensions: [
            dimension('fat', [option('oil')]),
          ],
        ),
        () => item(
          dimensions: [
            dimension('share', [option('half', amount: 2, unit: 'fraction')]),
          ],
        ),
        () => item(
          dimensions: [
            dimension('state', [option('raw')..['candidateKey'] = 'absent']),
          ],
        ),
        () => item(
          dimensions: [
            dimension('state', [
              option('raw', candidate: food())..['candidateKey'] = 'wrong',
            ]),
          ],
        ),
      ];
      for (final mutate in mutations) {
        expect(
          decode(
            message([
              intent([mutate()]),
            ]),
          ).issue,
          isNotNull,
        );
      }
      for (final json in [
        message()..['promptVersion'] = 'v2',
        message()..['model'] = null,
        message()..['intents'] = {},
        message([
          {'kind': '', 'language': 'en', 'script': 'latin'},
        ]),
        message([
          {'kind': 'medical', 'language': 'en'},
        ]),
        message([
          {'kind': 'weighIn', 'script': 'latin', 'value': 80, 'unit': 'kg'},
        ]),
        message([null]),
        message()..['extra'] = Object(),
      ]) {
        expect(decode(json).issue, isNotNull);
      }
      final invalidLocal = localFood(key: 'different');
      expect(
        decode(
          message(),
          ProposalFacts(catalog: {'usda:egg': invalidLocal}),
        ).issue,
        ProposalIssue.factsMismatch,
      );
      const key = 'bad-personal-id';
      expect(
        decode(
          message([
            intent([
              item(
                match: food(key: key, source: 'personal'),
              ),
            ]),
          ]),
          ProposalFacts(
            personal: {key: localFood(key: key, source: .yours)},
          ),
        ).issue,
        ProposalIssue.factsMismatch,
      );
    },
  );
  test('AI-063 oil tsp and tbsp keep distinct option IDs', () {
    final oil = food(key: 'usda:oil');
    final i = decodedItem(
      item(
        dimensions: [
          dimension('fat', [
            option('none', amount: 0, unit: 'tsp'),
            option('oil', candidate: oil, amount: 1, unit: 'tsp'),
            option('oil', candidate: oil, amount: 1, unit: 'tbsp'),
          ]),
        ],
      ),
    );
    expect(i.dimensions.single.options.map((o) => o.id).toSet().length, 3);
    expect(
      i.dimensions.single.options[1].effect,
      isA<ProposalComponentEffect>(),
    );
    expect(
      decodedItem(
        item(
          dimensions: [
            dimension('variant', [option('egg', candidate: food())]),
          ],
        ),
      ).dimensions.single.kind,
      ProposalDimensionKind.variant,
    );
    expect(
      decodedItem(
        item(
          dimensions: [
            dimension('state', [
              option('cooked')..['candidateKey'] = 'usda:egg',
            ]),
          ],
        ),
      ).dimensions.single.options.single.effect,
      isA<ProposalFoodEffect>(),
    );
    expect(
      decodedItem(
        item(
          dimensions: [
            dimension('portion', [option('big', amount: 200, unit: 'g')]),
          ],
        ),
      ).dimensions.single.options.single.effect,
      isA<ProposalQuantityEffect>(),
    );
    expect(
      decodedItem(
        item(
          dimensions: [
            dimension('oilRetention', [
              option('most', amount: .25, unit: 'fraction'),
            ]),
          ],
        ),
      ).dimensions.single.options.single.effect,
      isA<ProposalRetentionEffect>(),
    );
    expect(
      decodedItem(
        item(
          dimensions: [
            dimension('share', [option('half', amount: .5, unit: 'fraction')]),
          ],
        ),
      ).dimensions.single.options.single.effect,
      isA<ProposalShareEffect>(),
    );
  });
  test(
    'AI-063 fallback estimate without amount needsAmount and offers other',
    () {
      final i = item(amount: null, unit: null)
        ..['match'] = null
        ..['estimate'] = {
          'range': {'low': n(100), 'high': n(200)},
          'reason': 'noMatch',
        };
      expect(
        decode(
          message([
            intent([i]),
          ]),
        ).issue,
        ProposalIssue.needsAmount,
      );
      i['amount'] = {'value': 100, 'unit': 'g', 'explicit': true};
      expect(decodedItem(i).estimate!.low.kcal, 100);
    },
  );
  test('AQ-10 invalid fallback ranges never create an unbadged estimate', () {
    for (final estimate in [
      null,
      {
        'range': {'low': n(200), 'high': n(100)},
      },
      {'range': null},
    ]) {
      final i = item()
        ..['match'] = null
        ..['estimate'] = estimate;
      expect(
        decode(
          message([
            intent([i]),
          ]),
        ).issue,
        isNotNull,
      );
    }
    final f = food(source: 'reference')
      ..['ranges'] = {'low': n(100), 'high': n(200)};
    expect(decodedItem(item(match: f)).match!.range!.high.kcal, 200);
  });
  // rule: A21 input-bounds
  test('A21 input limits reject excess without dropping food lines', () {
    for (final json in [
      message(List.filled(21, intent([]))),
      message([intent(List.generate(51, (_) => item()))]),
      message([
        intent(List.generate(26, (_) => item())),
        intent(List.generate(26, (_) => item())),
      ]),
      message([
        intent([
          item(dimensions: List.generate(9, (_) => dimension('fat', []))),
        ]),
      ]),
      message([
        intent([
          item(
            dimensions: [
              dimension('fat', List.generate(33, (_) => option('none'))),
            ],
          ),
        ]),
      ]),
      message([
        intent([
          item(alternatives: List.generate(4, (i) => food(key: 'usda:$i'))),
        ]),
      ]),
      message()..['extra'] = 'x' * 524289,
      message()..['extra'] = 'ع' * 300000,
      message()..['extra'] = List.filled(65, null),
      message()..['extra'] = {for (var i = 0; i < 65; i++) '$i': null},
    ]) {
      expect(decode(json).issue, ProposalIssue.inputTooLarge);
    }
    Object? deep;
    for (var i = 0; i < 34; i++) {
      deep = [deep];
    }
    expect(
      decode(message()..['extra'] = deep).issue,
      ProposalIssue.inputTooLarge,
    );
  });
  // rule: B09 decoder forward-compat
  test('B09 decoder routes unknown intent kinds as unrecognized '
      'without failing the message', () {
    final result = decode(
      message([
        intent([item()]),
        {
          'kind': 'diaryEdit',
          'language': 'ar',
          'script': 'arabic',
          'reference': {'ref': 0, 'mention': 'Synthetic lunch'},
          'items': [
            {'whatever': true},
          ],
        },
        {'kind': 'medical', 'language': 'en', 'script': 'latin'},
        {'kind': 'unrecognized', 'language': 'en', 'script': 'latin'},
        {'kind': 'diaryEdit', 'language': 'en'},
        {'kind': 'memoryChange'},
      ]),
    );
    expect(result.issue, isNull);
    final intents = result.value!.intents;
    expect(intents.map((i) => i.kind), [
      'foodLog',
      'unrecognized',
      'medical',
      'unrecognized',
      'unrecognized',
      'unrecognized',
    ]);
    expect(intents.map((i) => i.index), [0, 1, 2, 3, 4, 5]);
    final unknown = intents[1];
    expect(unknown.items, isEmpty);
    expect(unknown.timeHint, isNull);
    expect(unknown.slotHint, isNull);
    expect(unknown.dishGroup, isNull);
    expect(unknown.toString(), isNot(contains('Synthetic')));
    expect(intents.first.items.single.match!.key, 'usda:egg');
  });
  // rule: B09 decoder forward-compat
  test('B09 decoder accepts interpret-vN as provenance '
      'and still rejects malformed versions', () {
    for (final version in ['interpret-v1', 'interpret-v2', 'interpret-v10']) {
      expect(
        decode(message()..['promptVersion'] = version).issue,
        isNull,
        reason: version,
      );
    }
    for (final version in [
      'v2',
      'interpret-v0',
      'interpret-v',
      'interpret-v02',
      'interpret-v2-beta',
      'interpret-v2 ',
      ' interpret-v2',
      'Interpret-v2',
      '',
      null,
      2,
    ]) {
      expect(
        decode(message()..['promptVersion'] = version).issue,
        ProposalIssue.invalidInput,
        reason: '$version',
      );
    }
  });
  // rule: B09 decoder forward-compat
  test('B09 oversized unknown kind is rejected as inputTooLarge', () {
    Map<String, Object?> unknown(Object? payload) => {
      'kind': 'batch',
      'language': 'en',
      'script': 'latin',
      'payload': payload,
    };
    Object? deep;
    for (var i = 0; i < 34; i++) {
      deep = [deep];
    }
    for (final payload in [
      'x' * 524289,
      List.filled(65, null),
      {for (var i = 0; i < 65; i++) '$i': null},
      deep,
    ]) {
      expect(
        decode(
          message([
            intent([item()]),
            unknown(payload),
          ]),
        ).issue,
        ProposalIssue.inputTooLarge,
      );
    }
    expect(
      decode(message(List.filled(21, unknown(null)))).issue,
      ProposalIssue.inputTooLarge,
    );
  });
}
