import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart' show UnauthorizedWriteError;
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart';
import '../../core/catalog/support/catalog_support.dart';
import '../../core/db/support/db_support.dart';
import '../foods/data/personal_food_harness.dart' show PersonalHarness, draft;

const riceKey = 'usda:rice_white_long_grain_cooked';
Future<ProposalResult<ProposalRequest>> load(
  ProposalInputLoader loader,
  Map<String, Object?> raw,
) => loader.load(
  interpretation: raw,
  messageId: '019a1b2c-0000-7000-8000-000000009999',
  idSource: FixedIds(),
  referenceTime: context().referenceTime,
);
Map<String, Object?> riceMessage() => message([
  intent([
    item(
      match: food(key: riceKey, kcal: 900),
      amount: 100,
      unit: 'g',
    ),
  ]),
]);
ProposalInputLoader loader(AppDatabase db) => ProposalInputLoader(
  db,
  catalog: ownedCatalog(db),
  config: () => ClientConfigRepository.defaults,
);

void main() {
  // rule: A21 restore-trust-boundary
  test('A21 restore loader reads trusted catalog pack and personal rows '
      'without writes', () async {
    final (db, catalog) = fixtureCatalog();
    addTearDown(catalog.dispose);
    final l = loader(db);
    final request = (await load(l, riceMessage())).value!;
    final s = ProposalEngine.build(request).value!;
    final budget = ProposalDraftCodec.encodeMessageBudget(s);
    final row = ProposalDraftCodec.encodeCard(s, s.cards.single.id);
    final before = await db.customSelect('SELECT * FROM sync_outbox').get();
    final good = await l.restore(
      message: budget,
      cards: [row],
      referenceTime: context().referenceTime,
    );
    expect(good.value!.cards.single, s.cards.single);
    for (final field in [5, 8]) {
      final forged = jsonDecode(jsonEncode(row)) as Map<String, Object?>;
      final food = (forged['foods']! as List).first as List;
      if (field == 5) {
        (food[5] as List)[0] = 999.0;
      } else {
        food[8] = 'older-pack';
      }
      final result = await l.restore(
        message: budget,
        cards: [forged],
        referenceTime: context().referenceTime,
      );
      expect(result.value!.cards.single.canConfirm, isFalse);
      expect(
        result.value!.cards.single.issues,
        contains(
          field == 5 ? ProposalIssue.factsMismatch : ProposalIssue.staleFacts,
        ),
      );
    }
    expect(
      (await db.customSelect('SELECT * FROM sync_outbox').get()).map(
        (r) => r.data,
      ),
      before.map((r) => r.data),
    );

    final h = PersonalHarness();
    const key = '019a1b2c-0000-7000-8000-000000001234';
    await h.apply([
      CreatePersonalFood(
        key,
        PersonalFoodDraft(
          names: FoodNames('Private'),
          per100: nutrients(123),
          servings: [PersonalFoodServing('cup', 250)],
          entryServing: PersonalFoodServing('piece', 50),
        ),
      ),
    ]);
    final personalLoader = loader(h.db);
    final personalRequest = (await load(
      personalLoader,
      message([
        intent([
          item(
            match: food(key: key, source: 'personal'),
          ),
        ]),
      ]),
    )).value!;
    final ps = ProposalEngine.build(personalRequest).value!;
    final saved = await h.raw();
    final restored = await personalLoader.restore(
      message: ProposalDraftCodec.encodeMessageBudget(ps),
      cards: [ProposalDraftCodec.encodeCard(ps, ps.cards.single.id)],
      referenceTime: context().referenceTime,
    );
    expect(restored.value, ps);
    expect(await h.raw(), saved);
    final bad = await personalLoader.restore(
      message: {},
      cards: [],
      referenceTime: context().referenceTime,
    );
    expect(bad.issue, ProposalIssue.sessionIncomplete);
  });

  // rule: A21 restore-trust-boundary
  test(
    'A21 restore loader malformed JSON and failed reads return typed issues',
    () async {
      final l = loader(memoryDatabase());
      final corrupt = await l.restore(
        message: {'bad': double.nan},
        cards: [],
        referenceTime: context().referenceTime,
      );
      expect(corrupt.issue, ProposalIssue.invalidInput);
      final invalid = await l.restore(
        message: {},
        cards: [
          {
            'foods': <Object?>[
              null,
              <Object?>[],
              [42],
              ['missing'],
            ],
          },
        ],
        referenceTime: context().referenceTime,
      );
      expect(invalid.issue, isNotNull);
      final fail = ProposalInputLoader(
        memoryDatabase(),
        catalog: ownedCatalog(memoryDatabase()),
        config: () => throw const FormatException(),
      );
      expect(
        (await fail.restore(
          message: {},
          cards: [],
          referenceTime: context().referenceTime,
        )).issue,
        ProposalIssue.invalidInput,
      );
    },
  );
  test('FD-060 loader raw cooked scenario uses local '
      'siblings and skips unknown yield states', () async {
    final (db, catalog) = fixtureCatalog(
      extraSql:
          'INSERT INTO yields VALUES '
          "('future', 'unknown', 'cooked', 2, 'reviewed');",
    );
    addTearDown(catalog.dispose);
    const rawKey = 'usda:rice_white_long_grain_raw';
    final request = (await load(
      loader(db),
      message([
        intent([
          item(
            match: food(key: riceKey, kcal: 900, group: 'rice'),
            amount: 200,
            unit: 'g',
            dimensions: [
              dimension('state', [
                option(
                  'dry',
                  candidate: food(
                    key: rawKey,
                    state: 'dry',
                    kcal: 999,
                    group: 'rice',
                  ),
                ),
                option(
                  'cooked',
                  candidate: food(key: riceKey, kcal: 900, group: 'rice'),
                ),
              ], stated: 'dry'),
            ],
          ),
        ]),
      ]),
    )).value!;
    final card = ProposalEngine.build(request).value!.cards.single;
    expect(card.lines.single.entry.food.ref.id, rawKey);
    expect(card.totals.kcal, 730);
    expect(request.context.yields.any((y) => y.group == 'future'), isFalse);
  });
  // rule: A21 loader-error-boundary
  test('A21 loader never hides UnauthorizedWriteError', () async {
    final input = ProposalInputLoader(
      memoryDatabase(),
      catalog: ownedCatalog(memoryDatabase()),
      config: () => throw UnauthorizedWriteError('custom'),
    );
    await expectLater(
      load(input, message()),
      throwsA(isA<UnauthorizedWriteError>()),
    );
  });

  // rule: A21 catalog-adapter
  test('A21 loader resolves yield siblings and dish variants '
      'through OfflineCatalog', () async {
    final (db, catalog) = fixtureCatalog();
    addTearDown(catalog.dispose);
    final request = (await load(loader(db), riceMessage())).value!;
    expect(
      request.facts.catalog.containsKey('usda:rice_white_long_grain_raw'),
      isTrue,
    );
    final dishes = await db
        .customSelect('SELECT id FROM catalog.dishes LIMIT 1')
        .get();
    final dish = dishes.single.read<String>('id');
    final variants = await catalog.foodsByIds([dish]);
    final result = await load(
      loader(db),
      message([
        intent([
          item(
            match: food(key: dish, source: 'reference'),
            amount: 100,
            unit: 'g',
          ),
        ]),
      ]),
    );
    expect(result.issue, isNull);
    expect(
      result.value!.facts.catalog.keys,
      containsAll(variants[dish]!.map((f) => f.id)),
    );
  });
  // rule: A21 loader-error-boundary
  test(
    'A21 loader rethrows Error subtypes without masking programming errors',
    () async {
      final input = ProposalInputLoader(
        memoryDatabase(),
        catalog: ownedCatalog(memoryDatabase()),
        config: () => throw StateError('bug'),
      );
      await expectLater(load(input, message()), throwsStateError);
    },
  );

  test(
    'AI-041 loader snapshots local personal pack facts yields and config',
    () async {
      final (db, catalog) = fixtureCatalog();
      addTearDown(catalog.dispose);
      final result = await load(loader(db), riceMessage());
      expect(result.issue, isNull);
      final request = result.value!;
      expect(request.facts.catalog[riceKey]!.per100.kcal, 130);
      expect(request.context.yields, isNotEmpty);
      expect(request.context.slots, isNotEmpty);
      final s = ProposalEngine.build(request).value!;
      expect(s.cards.single.totals.kcal, 130);
      expect(
        s.cards.single.lines.single.factOrigin,
        ProposalFactOrigin.localCatalog,
      );
    },
  );
  test('AI-040 recompute makes no SQL network or config reads', () async {
    final db = memoryDatabase();
    var configReads = 0;
    final input = ProposalInputLoader(
      db,
      catalog: ownedCatalog(db),
      config: () {
        configReads++;
        return ClientConfigRepository.defaults;
      },
    );
    final request = (await load(input, message())).value!;
    final s = ProposalEngine.build(request).value!;
    // Make later SQL/config reads fail; the engine owns neither dependency.
    await db.close();
    final r = ProposalEngine.recompute(
      s,
      ProposalSetAmount(
        s.cards.single.lines.single.entry.id,
        Quantity(2, 'piece'),
      ),
    );
    expect(r.issue, isNull);
    expect(r.value!.session.cards.single.totals.kcal, 144);
    expect(configReads, 1);
  });
  // rule: A21 targets
  test(
    'A21 loader returns targetsUnavailable until A13 read port exists',
    () async {
      final request = (await load(loader(memoryDatabase()), message())).value!;
      final card = ProposalEngine.build(request).value!.cards.single;
      expect(card.preview.targetsUnavailable, isTrue);
      expect(card.preview.eaten!.kcal, 72);
      expect(card.preview.targetKcal, isNull);
    },
  );
  // rule: A21 privacy
  test('A21 loader failures emit only fixed codes without content', () async {
    final diagnostics = <String>[];
    final input = ProposalInputLoader(
      memoryDatabase(),
      catalog: ownedCatalog(memoryDatabase()),
      config: () => throw const FormatException('private secret طعام 884'),
    );
    final r = await load(input, message());
    diagnostics
      ..add(r.toString())
      ..add(input.toString());
    expect(r.issue, ProposalIssue.invalidInput);
    expect(diagnostics.join(), isNot(contains('private')));
    expect(diagnostics.join(), isNot(contains('طعام')));
    final bad = await load(
      loader(memoryDatabase()),
      message()..['model'] = null,
    );
    expect(bad.issue, ProposalIssue.invalidInput);
  });
  // rule: A21 cooking-fat-meta
  test(
    'A21 loader reads optional cooking fat metadata without inference',
    () async {
      final (db, catalog) = fixtureCatalog(
        extraSql:
            '''INSERT INTO meta VALUES ('cooking_fat_ids', '["$riceKey"]');''',
      );
      addTearDown(catalog.dispose);
      final request = (await load(loader(db), riceMessage())).value!;
      expect(request.facts.cookingFatIds, {riceKey});
      expect(request.facts.cookingFatIds.clear, throwsUnsupportedError);
    },
  );
  // rule: A21 cooking-fat-meta
  test(
    'A21 loader absent cooking fat metadata supplies an empty set',
    () async {
      final (db, catalog) = fixtureCatalog();
      addTearDown(catalog.dispose);
      final request = (await load(loader(db), riceMessage())).value!;
      expect(request.facts.cookingFatIds, isEmpty);
      expect(
        (await load(
          loader(memoryDatabase()),
          message(),
        )).value!.facts.cookingFatIds,
        isEmpty,
      );
    },
  );
  // rule: A21 fact-precedence
  test(
    'A21 loader distinguishes absent pack from missing attached key',
    () async {
      final (db, catalog) = fixtureCatalog();
      addTearDown(catalog.dispose);
      expect(
        (await load(loader(db), message())).issue,
        ProposalIssue.missingFoodFacts,
      );
      final absent = (await load(loader(memoryDatabase()), message())).value!;
      expect(absent.facts.packAvailable, isFalse);
      expect(
        ProposalEngine.build(absent)
            .value!
            .cards
            .single
            .lines
            .single
            .factOrigin,
        ProposalFactOrigin.embeddedServer,
      );
    },
  );
  // rule: A21 fact-precedence
  test(
    'A21 loader personal ml basis and version replace embedded facts',
    () async {
      final h = PersonalHarness();
      const key = '019a1b2c-0000-7000-8000-000000001234';
      await h.apply([
        CreatePersonalFood(
          key,
          draft(
            'Private milk',
            basis: .per100ml,
            servings: [PersonalFoodServing('cup', 250)],
          ),
        ),
      ]);
      final request = (await load(
        loader(h.db),
        message([
          intent([
            item(
              match: food(key: key, source: 'personal', kcal: 999),
              amount: 100,
              unit: 'ml',
            ),
          ]),
        ]),
      )).value!;
      final s = ProposalEngine.build(request).value!;
      final line = s.cards.single.lines.single;
      expect(line.entry.amount.basis, NutrientBasis.per100ml);
      expect(line.snapshot.kcal, 0);
      expect(request.facts.personal[key]!.personalVersion, 1);
      expect(s.cards.single.draftOps.first, isA<RequirePersonalFood>());
    },
  );
  // rule: A21 read-only-adapter
  test('A21 read snapshot never authorizes a user data write', () async {
    final db = memoryDatabase();
    expect(
      await db.readSnapshot(() => db.customSelect('SELECT 1 AS n').get()),
      hasLength(1),
    );
    await expectLater(
      db.readSnapshot(
        () => db.customStatement('CREATE TABLE forbidden (value INTEGER)'),
      ),
      throwsA(isA<UnauthorizedWriteError>()),
    );
  });
}

OfflineCatalog ownedCatalog(AppDatabase db) {
  final catalog = OfflineCatalog(db);
  addTearDown(catalog.dispose);
  return catalog;
}
