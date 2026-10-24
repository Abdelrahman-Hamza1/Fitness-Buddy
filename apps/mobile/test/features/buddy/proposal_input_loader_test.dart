import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
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
  today: context().referenceTime.localDate,
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
ProposalInputLoader loader(AppDatabase db) =>
    ProposalInputLoader(db, config: () => ClientConfigRepository.defaults);

void main() {
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
      expect(card.preview.eaten.kcal, 72);
      expect(card.preview.targetKcal, isNull);
    },
  );
  // rule: A21 privacy
  test('A21 loader failures emit only fixed codes without content', () async {
    final diagnostics = <String>[];
    final input = ProposalInputLoader(
      memoryDatabase(),
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
