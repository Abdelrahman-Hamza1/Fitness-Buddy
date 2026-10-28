import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_rebuild_test.dart' show follow;
import 'proposal_recompute_test.dart' show decodedItem, update, valueChecks;

Map<String, Object?> copyJson(Map<String, Object?> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, Object?>;
List<Map<String, Object?>> cardRows(ProposalSession s) => [
  for (final c in s.cards) ProposalDraftCodec.encodeCard(s, c.id),
];
ProposalSession roundTrip(ProposalSession s, {ProposalContext? ctx}) {
  final r = ProposalDraftCodec.restore(
    trustedFacts: trustedSession(s, ctx: ctx),
    copyJson(ProposalDraftCodec.encodeMessageBudget(s)),
    cardRows(s).map(copyJson),
    context: ctx ?? context(),
  );
  expect(r.issue, isNull);
  return r.value!;
}

void main() {
  // rule: A21 restore-input-bounds
  test('A21 restore preflight counts JSON scalars and rejects non JSON', () {
    expect(
      ProposalDraftCodec.validateRestoreInput({
        'text': r'"\ع漢😀',
        'values': [null, true, false, 1.25, 2],
      }, []).issue,
      isNull,
    );
    expect(
      ProposalDraftCodec.validateRestoreInput({'bad': Object()}, []).issue,
      ProposalIssue.invalidInput,
    );
  });

  // rule: A21 restore-input-bounds
  test(
    'A21 restore bounds deep JSON lazy cards and cumulative bytes',
    () async {
      Object? deep;
      for (var i = 0; i < 10000; i++) {
        deep = [deep];
      }
      var enumerated = 0;
      Iterable<Map<String, Object?>> endless() sync* {
        while (true) {
          enumerated++;
          yield <String, Object?>{};
        }
      }

      final cases = <(Map<String, Object?>, Iterable<Map<String, Object?>>)>[
        ({'deep': deep}, []),
        (
          {},
          [
            {'deep': deep},
          ],
        ),
        ({}, endless()),
        (
          {'padding': 'x' * 300000},
          [
            {'padding': 'x' * 300000},
          ],
        ),
        (
          {'padding': 'ع' * 180000},
          [
            {'padding': 'ع' * 90000},
          ],
        ),
        ({'padding': '\u0000' * 90000}, []),
      ];
      for (final (budget, rows) in cases) {
        final result = ProposalDraftCodec.restore(
          budget,
          rows,
          context: context(),
          trustedFacts: TrustedFoodFacts(),
        );
        expect(result.issue, ProposalIssue.inputTooLarge);
        expect(result.toString(), isNot(contains('padding')));
      }
      expect(enumerated, ProposalPolicyConstants.maxIntents + 1);
    },
  );

  // rule: A21 draft-codec
  test('A21 card and message v1 round trip preserves choices bindings '
      'lifecycle and policy', () {
    final ids = FixedIds();
    var s = session(
      message([
        intent([riceItem()]),
        intent([item()], slot: 'dinner'),
      ]),
      ids: ids,
    );
    final q = s.budget.questions.single;
    s = update(s, ProposalSelect(q.dimensionId, q.optionIds.last)).session;
    s = update(
      s,
      ProposalSetAmount(s.cards.first.lines.first.entry.id, Quantity(300, 'g')),
    ).session;
    s = update(
      s,
      ProposalSetWhen(
        s.cards.first.id,
        time: EntryTime(DateTime.utc(2026, 10, 16, 20), 120),
        slotId: DefaultSlots.lunch.id,
      ),
    ).session;
    s = update(
      s,
      ProposalAdd(s.cards.first.id, 'added', decodedItem(item()), ids),
    ).session;
    s = update(
      s,
      ProposalSetRemoved(s.cards.first.lines.last.entry.id, removed: true),
    ).session;
    s = update(s, ProposalSetLifecycle(s.cards.last.id, .confirmed)).session;
    expect(roundTrip(s), s);
    expect(ids.calls, 8);
    expect(roundTrip(s).cards.last.canConfirm, isFalse);
  });
  test(
    'AI-015 cards of one message restore with one shared question budget',
    () {
      final s = session(
        message([
          intent([riceItem()]),
          intent([riceItem()], slot: 'dinner'),
        ]),
      );
      final restored = roundTrip(s);
      expect(restored, s);
      expect(restored.budget.questions, hasLength(2));
      for (final row in cardRows(s)) {
        expect(row.containsKey('issued'), isFalse);
        expect(row.containsKey('policy'), isFalse);
        expect(row['owned'], hasLength(1));
        expect(row['interpretation'], hasLength(1));
      }
    },
  );
  test('AQ-08 message budget and card ownership conflict cannot exceed '
      'two issued question IDs', () {
    final s = session(
      message([
        intent([riceItem(), riceItem(), riceItem()]),
      ]),
    );
    final budget = ProposalDraftCodec.encodeMessageBudget(s);
    final rows = cardRows(s);
    for (final broken in [
      copyJson(budget)
        ..['issued'] = {
          'a': s.cards.single.id,
          'b': s.cards.single.id,
          'c': s.cards.single.id,
        },
      copyJson(budget)..['issued'] = <String, Object?>{},
      copyJson(budget)..['open'] = <Object?>[],
      copyJson(budget)..['revision'] = 99,
    ]) {
      expect(
        ProposalDraftCodec.restore(
          trustedFacts: trustedSession(s, ctx: context()),
          broken,
          rows,
          context: context(),
        ).issue,
        ProposalIssue.budgetConflict,
      );
    }
    final row = copyJson(rows.single)..['owned'] = <Object?>[];
    expect(
      ProposalDraftCodec.restore(
        trustedFacts: trustedSession(s, ctx: context()),
        budget,
        [row],
        context: context(),
      ).issue,
      ProposalIssue.budgetConflict,
    );
  });
  // rule: A21 draft-codec
  test('A21 missing message or card row returns sessionIncomplete '
      'without resetting budget', () {
    final s = session(message());
    expect(
      ProposalDraftCodec.restore(
        trustedFacts: trustedSession(s, ctx: context()),
        {},
        cardRows(s),
        context: context(),
      ).issue,
      ProposalIssue.sessionIncomplete,
    );
    expect(
      ProposalDraftCodec.restore(
        trustedFacts: trustedSession(s, ctx: context()),
        ProposalDraftCodec.encodeMessageBudget(s),
        [],
        context: context(),
      ).issue,
      ProposalIssue.sessionIncomplete,
    );
  });
  // rule: A21 draft-codec
  test('A21 restore recomputes and rejects tampered derived ops or totals', () {
    final s = session(message());
    final budget = ProposalDraftCodec.encodeMessageBudget(s);
    for (final key in ['totals', 'draftOps']) {
      final row = copyJson(cardRows(s).single)..[key] = [];
      expect(
        ProposalDraftCodec.restore(
          trustedFacts: trustedSession(s, ctx: context()),
          budget,
          [row],
          context: context(),
        ).issue,
        ProposalIssue.invalidInput,
      );
    }
    final row = copyJson(cardRows(s).single);
    (row['ids']! as Map<String, Object?>).remove('item:0/0');
    expect(
      ProposalDraftCodec.restore(
        trustedFacts: trustedSession(s, ctx: context()),
        budget,
        [row],
        context: context(),
      ).issue,
      ProposalIssue.invalidInput,
    );
    expect(roundTrip(s).cards.single.totals, s.cards.single.totals);
  });
  // rule: A21 sync-bounds
  test('A21 six item compact card fits 32768 UTF-16 units without losing '
      'recompute options', () {
    final s = session(
      message([
        intent([
          riceItem(),
          riceItem(),
          item(dimensions: [fatDimension()]),
          item(),
          item(),
          item(),
        ], group: 'dish'),
      ]),
    );
    final result = ProposalDraftCodec.syncProjection(s, s.cards.single.id);
    expect(result.issue, isNull);
    final p = result.value!;
    expect(p.interpretation.length, lessThanOrEqualTo(32768));
    expect(p.draft.length, lessThanOrEqualTo(32768));
    expect(p.messageBudget.length, lessThanOrEqualTo(32768));
    valueChecks(
      p,
      ProposalDraftCodec.syncProjection(s, s.cards.single.id).value!,
    );
    expect(roundTrip(s), s);
    final q = s.budget.questions.first;
    final restored = roundTrip(s);
    expect(
      update(restored, ProposalSelect(q.dimensionId, q.optionIds.last)).session,
      update(s, ProposalSelect(q.dimensionId, q.optionIds.last)).session,
    );
    for (final text in ['a' * 32768, '😀' * 16384]) {
      expect(ProposalDraftCodec.fitsSyncString(text), isTrue);
      expect(ProposalDraftCodec.fitsSyncString('${text}a'), isFalse);
    }
  });
  // rule: A21 sync-bounds
  test('A21 oversized sync projection retains local draft and returns '
      'syncPayloadTooLarge', () {
    final raw = item(match: food()..['nameEn'] = '😀' * 17000);
    final s = session(
      message([
        intent([raw]),
      ]),
    );
    expect(s.cards.single.canConfirm, isTrue);
    expect(
      ProposalDraftCodec.syncProjection(s, s.cards.single.id).issue,
      ProposalIssue.syncPayloadTooLarge,
    );
    expect(s.cards.single.canConfirm, isTrue);
    expect(roundTrip(s), s);
  });
  // rule: A21 draft-codec
  test('A21 unknown codec version and malformed JSON fail without content', () {
    final s = session(message());
    final budget = ProposalDraftCodec.encodeMessageBudget(s);
    expect(
      ProposalDraftCodec.restore(
        trustedFacts: trustedSession(s, ctx: context()),
        copyJson(budget)..['codecVersion'] = 2,
        cardRows(s),
        context: context(),
      ).issue,
      ProposalIssue.unsupportedCodecVersion,
    );
    for (final value in <Object?>[
      null,
      'private طعام 884',
      [1],
      double.nan,
    ]) {
      final row = copyJson(cardRows(s).single)..['foods'] = value;
      final r = ProposalDraftCodec.restore(
        trustedFacts: trustedSession(s, ctx: context()),
        budget,
        [row],
        context: context(),
      );
      expect(r.issue, isNotNull);
      expect(r.toString(), isNot(contains('private')));
    }
  });
  // rule: A21 component-edits
  test('A21 generated oil amount food and retention survive codec and '
      'absolute edits', () {
    var s = session(
      message([
        intent([
          item(dimensions: [fatDimension()]),
        ]),
      ]),
    );
    final d = s.cards.single.lines.first.dimensions.first;
    s = update(s, ProposalSelect(d.id, d.options.last.id)).session;
    final oilId = s.cards.single.lines.last.entry.id;
    s = update(s, ProposalSetAmount(oilId, Quantity(2, 'tsp'))).session;
    expect(s.cards.single.lines.last.entry.amount.amount, 9);
    s = update(
      s,
      ProposalSwap(
        oilId,
        ProposalFood(
          key: 'usda:new-oil',
          names: FoodNames('Oil'),
          state: .raw,
          source: .database,
          per100: nutrients(800),
          density: 1,
        ),
      ),
    ).session;
    final retention = s.cards.single.lines.last.dimensions.single;
    s = update(
      s,
      ProposalSelect(retention.id, retention.options.last.id),
    ).session;
    expect(roundTrip(s), s);
    final again = update(s, ProposalSetAmount(oilId, Quantity(2, 'tsp')));
    expect(again.diff.isEmpty, isTrue);
  });
  // rule: A21 malformed-storage
  test('A21 bounded structural mutations return typed outcomes without '
      'leaking content', () {
    final s = session(
      message([
        intent([
          riceItem(),
          item(dimensions: [fatDimension()]),
        ], group: 'dish'),
      ]),
    );
    final budget = ProposalDraftCodec.encodeMessageBudget(s);
    final row = cardRows(s).single;
    final paths = <List<Object>>[];
    void visit(Object? value, List<Object> path) {
      paths.add(path);
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          visit(value[i], [...path, i]);
        }
      } else if (value is Map<String, Object?>) {
        for (final e in value.entries) {
          visit(e.value, [...path, e.key]);
        }
      }
    }

    visit(row, []);
    for (final path in paths.where((p) => p.isNotEmpty)) {
      for (final invalid in <Object?>[
        null,
        true,
        [],
        <String, Object?>{},
        '',
        -1,
        999999,
        'private طعام 884',
      ]) {
        final changed = copyJson(row);
        Object? parent = changed;
        for (final key in path.take(path.length - 1)) {
          parent = parent is List
              ? parent[key as int]
              : (parent! as Map<String, Object?>)[key];
        }
        final key = path.last;
        if (parent is List) {
          parent[key as int] = invalid;
        } else {
          (parent! as Map<String, Object?>)[key as String] = invalid;
        }
        final result = ProposalDraftCodec.restore(
          trustedFacts: trustedSession(s, ctx: context()),
          budget,
          [changed],
          context: context(),
        );
        expect(result.toString(), isNot(contains('private')));
        if (result.value case final session?) {
          expect(session.budget.questions.length, lessThanOrEqualTo(2));
        }
      }
    }
  });
  // rule: A21 source-aware-codec
  test(
    'A21 codec retains local versions extras ranges yields and every effect',
    () {
      const key = '019a1b2c-0000-7000-8000-000000001234';
      final personal = ProposalFood(
        key: key,
        names: FoodNames('Personal'),
        source: .yours,
        state: .cooked,
        per100: Nutrients(
          kcal: 150,
          protein: 0,
          carbs: 0,
          fat: 0,
          fiber: 0,
          extras: {NutrientKey.sodium: 20},
        ),
        basis: .per100ml,
        personalVersion: 3,
        origin: .localPersonal,
        density: 1,
        range: ProposalRange(nutrients(100), nutrients(200)),
        servings: [ProposalServing('cup', 250, .per100ml, 200, 300)],
      );
      final raw = item(
        match: food(key: key, source: 'personal'),
        unit: 'cup',
        explicit: false,
        dimensions: [
          dimension('portion', [
            option('one', amount: 1, unit: 'cup'),
            option('two', amount: 2, unit: 'cup'),
          ]),
          dimension('share', [
            option('half', amount: .5, unit: 'g'),
            option('all', amount: 1, unit: 'g'),
          ]),
          dimension('oilRetention', [
            option('all', amount: 1, unit: 'g'),
            option('most', amount: .25, unit: 'g'),
          ]),
        ],
      );
      final estimate = item(amount: 100, unit: 'g')
        ..['match'] = null
        ..['estimate'] = {
          'range': {'low': n(100), 'high': n(200)},
        };
      final ctx = context(
        yields: [
          YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.8),
        ],
      );
      final s = session(
        message([
          intent([raw, estimate]),
        ]),
        ctx: ctx,
        facts: ProposalFacts(personal: {key: personal}),
      );
      expect(roundTrip(s, ctx: ctx), s);
      final encoded = cardRows(s).single;
      final fields = encoded['foods']! as List<Object?>;
      final corrupt = copyJson(encoded);
      final f = (corrupt['foods']! as List<Object?>).first! as List<Object?>;
      f[9] = 0;
      expect(
        ProposalDraftCodec.restore(
          trustedFacts: trustedSession(s, ctx: ctx),
          ProposalDraftCodec.encodeMessageBudget(s),
          [corrupt],
          context: ctx,
        ).issue,
        ProposalIssue.invalidInput,
      );
      expect(fields, isNotEmpty);
      final superseded = copyJson(encoded)..['status'] = 'superseded';
      final budget = copyJson(ProposalDraftCodec.encodeMessageBudget(s))
        ..['open'] = [];
      final historical = ProposalDraftCodec.restore(
        trustedFacts: trustedSession(s, ctx: ctx),
        budget,
        [superseded],
        context: ctx,
      );
      expect(historical.issue, isNull);
      expect(historical.value!.cards.single.canConfirm, isFalse);
    },
  );

  // rule: B18 contract-handoff
  test('B18 encodeCard status equals ProposalStatus.ofLifecycle for every '
      'lifecycle', () {
    final s = session(message());
    final id = s.cards.single.id;
    for (final lifecycle in ProposalLifecycle.values) {
      final observed = lifecycle == .active
          ? s
          : update(s, ProposalSetLifecycle(id, lifecycle)).session;
      expect(observed.cards.single.lifecycle, lifecycle);
      expect(
        ProposalDraftCodec.encodeCard(observed, id)['status'],
        ProposalStatus.ofLifecycle(lifecycle).code,
      );
    }
  });

  // rule: B18 contract-handoff
  test('B18 cardFromSync and messageFromSync invert syncProjection', () {
    final ids = FixedIds();
    final first = session(
      message([
        intent([riceItem(), riceItem()]),
      ]),
      ids: ids,
    );
    final followUp = ProposalEngine.rebuild(
      first.cards.single,
      follow(
        message([
          intent([riceItem(), riceItem(), riceItem()]),
        ]),
        ids,
      ),
    ).value!.session;
    final three = session(
      message([
        intent([riceItem()]),
        intent([item()], slot: 'dinner'),
        intent([item(match: oilFood(), unit: 'tbsp')], slot: 'lunch'),
      ]),
    );
    expect(three.cards.length, 3);
    final multi = update(
      three,
      ProposalSetLifecycle(three.cards.first.id, .confirmed),
    ).session;
    expect(multi.cards.first.lifecycle, ProposalLifecycle.confirmed);
    expect(
      followUp.cards.single.originMessageId,
      isNot(followUp.cards.single.budgetMessageId),
    );
    for (final s in [first, followUp, multi]) {
      final cards = <Map<String, Object?>>[];
      Map<String, Object?>? budget;
      for (final card in s.cards) {
        final p = ProposalDraftCodec.syncProjection(s, card.id).value!;
        final row = ProposalDraftCodec.cardFromSync(
          interpretationJson: p.interpretation,
          draftJson: p.draft,
        );
        expect(row.issue, isNull);
        expect(row.value, copyJson(ProposalDraftCodec.encodeCard(s, card.id)));
        cards.add(row.value!);
        final message = ProposalDraftCodec.messageFromSync(p.messageBudget);
        expect(
          message.value,
          copyJson(ProposalDraftCodec.encodeMessageBudget(s)),
        );
        budget = message.value;
      }
      final restored = ProposalDraftCodec.restore(
        budget!,
        cards,
        context: context(),
        trustedFacts: trustedSession(s, ctx: context()),
      );
      expect(restored.issue, isNull);
      expect(restored.value, s);
    }
  });

  // rule: B18 contract-handoff
  test('B18 malformed non-object or null sync fields return a fixed issue '
      'without throwing', () {
    const private = 'private طعام 😀';
    final over = '{"p":"${'😀' * 16380}"}a';
    final limit = '{"p":"${'😀' * 16380}"}';
    expect(limit.length, ProposalDraftCodec.syncStringLimit);
    expect(over.length, ProposalDraftCodec.syncStringLimit + 1);
    final cards = <(String?, String, ProposalIssue)>[
      (null, '{}', .invalidInput),
      ('[]', '{', .invalidInput),
      ('[]', '[]', .invalidInput),
      ('[]', 'null', .invalidInput),
      ('[]', '1', .invalidInput),
      ('[]', '"$private"', .invalidInput),
      ('[]', '{"interpretation":[]}', .invalidInput),
      ('[$private', '{}', .invalidInput),
      ('', '{}', .invalidInput),
      ('[]', over, .inputTooLarge),
      (over, '{}', .inputTooLarge),
    ];
    for (final (interpretation, draft, issue) in cards) {
      final r = ProposalDraftCodec.cardFromSync(
        interpretationJson: interpretation,
        draftJson: draft,
      );
      expect(r.issue, issue);
      expect(r.value, isNull);
      expect(r.toString(), isNot(contains('private')));
    }
    final messages = <(String?, ProposalIssue)>[
      (null, .invalidInput),
      ('', .invalidInput),
      ('{', .invalidInput),
      ('[]', .invalidInput),
      ('null', .invalidInput),
      ('"$private"', .invalidInput),
      ('{"$private":', .invalidInput),
      (over, .inputTooLarge),
    ];
    for (final (budget, issue) in messages) {
      final r = ProposalDraftCodec.messageFromSync(budget);
      expect(r.issue, issue);
      expect(r.toString(), isNot(contains('private')));
    }
    // Opaque JSON at the limit decodes; restore diagnoses engine content.
    expect(ProposalDraftCodec.messageFromSync(limit).value, {
      'p': '😀' * 16380,
    });
    expect(
      ProposalDraftCodec.cardFromSync(
        interpretationJson: limit,
        draftJson: limit,
      ).value,
      {
        'p': '😀' * 16380,
        'interpretation': {'p': '😀' * 16380},
      },
    );
    for (final interpretation in ['null', '{}', '1', r'"\ud800"']) {
      final card = ProposalDraftCodec.cardFromSync(
        interpretationJson: interpretation,
        draftJson: '{}',
      );
      expect(card.issue, isNull);
      expect(card.value!.keys, ['interpretation']);
    }
    final empty = ProposalDraftCodec.restore(
      ProposalDraftCodec.messageFromSync('{}').value!,
      [
        ProposalDraftCodec.cardFromSync(
          interpretationJson: 'null',
          draftJson: '{}',
        ).value!,
      ],
      context: context(),
      trustedFacts: TrustedFoodFacts(),
    );
    expect(empty.issue, ProposalIssue.sessionIncomplete);
  });
}
