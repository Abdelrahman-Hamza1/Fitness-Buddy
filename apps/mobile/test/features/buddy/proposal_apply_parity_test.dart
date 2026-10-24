import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/diary/data/diary_mappers.dart'
    show provenanceOf;
import 'package:flutter_test/flutter_test.dart';

import '../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart';
import '../../../../../packages/fb_domain/test/proposals/proposal_rebuild_test.dart'
    show follow;
import '../../../../../packages/fb_domain/test/proposals/proposal_recompute_test.dart'
    show update;
import '../diary/support/diary_harness.dart';
import '../foods/data/personal_food_harness.dart' show PersonalHarness, draft;

void main() {
  // rule: A21 restore-trust-boundary
  test(
    'A21 legitimate trusted restore confirms through real applier',
    () async {
      final h = PersonalHarness();
      const key = '019a1b2c-0000-7000-8000-000000001234';
      await h.apply([CreatePersonalFood(key, draft('Private'))]);
      final loader = ProposalInputLoader(
        h.db,
        catalog: ownedCatalog(h.db),
        config: () => ClientConfigRepository.defaults,
      );
      final request = (await loader.load(
        interpretation: message([
          intent([
            item(
              match: food(key: key, source: 'personal'),
              amount: 100,
              unit: 'g',
            ),
          ]),
        ]),
        messageId: '019a1b2c-0000-7000-8000-000000009999',
        idSource: FixedIds(),
        referenceTime: context().referenceTime,
      )).value!;
      final s = ProposalEngine.build(request).value!;
      final restored = await loader.restore(
        message: ProposalDraftCodec.encodeMessageBudget(s),
        cards: [ProposalDraftCodec.encodeCard(s, s.cards.single.id)],
        referenceTime: context().referenceTime,
      );
      final card = restored.value!.cards.single;
      expect(card.issues, isEmpty);
      expect(card.canConfirm, isTrue);
      expect(
        await h.applier.apply(
          ChangeSet(card.draftOps, origin: Origin.proposal(card.id)),
        ),
        isA<Applied>(),
      );
      final stored = (await h.db.select(h.db.diaryEntries).get()).single;
      expect(stored.kcal, card.lines.single.snapshot.kcal);
    },
  );

  // rule: A21 exact-personal-snapshot
  test('A21 mixed personal versions through restore reject '
      'real applier confirmation atomically', () async {
    final h = PersonalHarness();
    const key = '019a1b2c-0000-7000-8000-000000001234';
    await h.apply([CreatePersonalFood(key, draft('Private'))]);
    var s = session(
      message([
        intent([
          item(
            match: food(key: key, source: 'personal'),
          ),
          item(
            match: food(key: key, source: 'personal'),
          ),
        ]),
      ]),
      facts: ProposalFacts(
        personal: {
          key: localFood(key: key, source: .yours, personalVersion: 1),
        },
      ),
    );
    s = update(
      s,
      ProposalSwap(
        s.cards.single.lines.last.entry.id,
        localFood(key: key, source: .yours, personalVersion: 2, kcal: 300),
      ),
    ).session;
    final card = ProposalDraftCodec.restore(
      trustedFacts: trustedSession(s, ctx: context()),
      ProposalDraftCodec.encodeMessageBudget(s),
      [ProposalDraftCodec.encodeCard(s, s.cards.single.id)],
      context: context(),
    ).value!.cards.single;
    final before = await h.raw();
    // Keep the live mixed-version guard regression as well: only restore
    // gains the stronger independent-fact rejection in this amendment.
    expect(
      await h.applier.apply(
        ChangeSet(s.cards.single.draftOps, origin: Origin.proposal(card.id)),
      ),
      isA<Rejected>().having(
        (r) => r.failure,
        'failure',
        isA<VersionConflict>(),
      ),
    );
    expect(card.canConfirm, isFalse);
    expect(card.draftOps, isEmpty);
    expect(card.issues, contains(ProposalIssue.staleFacts));
    expect(await h.raw(), before);
  });
  test(
    'AI-044 rebuilt second dish confirms after sibling without group collision',
    () async {
      final h = PersonalHarness();
      final ids = FixedIds();
      var s = session(
        message([
          intent([item()], slot: 'breakfast', group: 'first'),
          intent([item()], slot: 'dinner', group: 'second'),
        ]),
        ids: ids,
      );
      final first = s.cards.first;
      expect(
        await h.applier.apply(
          ChangeSet(first.draftOps, origin: Origin.proposal(first.id)),
        ),
        isA<Applied>(),
      );
      s = update(s, ProposalSetLifecycle(first.id, .confirmed)).session;
      final second = ProposalEngine.rebuild(
        s.cards.last,
        follow(
          message([
            intent([item()], slot: 'dinner', group: 'second'),
          ]),
          ids,
        ),
      ).value!.session.cards.single;
      expect(
        await h.applier.apply(
          ChangeSet(second.draftOps, origin: Origin.proposal(second.id)),
        ),
        isA<Applied>(),
      );
      expect(await h.db.select(h.db.dishGroups).get(), hasLength(2));
    },
  );

  test('AI-031 T01 draft ops through real applier match preview', () async {
    final harness = DiaryHarness();
    final card = session(
      t01(),
      facts: ProposalFacts(cookingFatIds: {'usda:oil'}),
    ).cards.single;
    expect(await harness.db.select(harness.db.diaryEntries).get(), isEmpty);
    final result = await harness.applier.apply(
      ChangeSet(card.draftOps, origin: Origin.proposal(card.id)),
    );
    expect(result, isA<Applied>());
    final entries = await harness.db.select(harness.db.diaryEntries).get();
    expect(entries.length, 2);
    expect(await harness.db.select(harness.db.dishGroups).get(), hasLength(1));
    for (final line in card.lines) {
      final stored = entries.singleWhere((e) => e.id == line.entry.id);
      expect(stored.kcal, line.snapshot.kcal);
      expect(stored.proteinG, line.snapshot.protein);
      expect(stored.carbsG, line.snapshot.carbs);
      expect(stored.fatG, line.snapshot.fat);
      expect(stored.fiberG, line.snapshot.fiber);
      expect(stored.amount, line.entry.amount.amount);
      expect(stored.dishGroupId, line.entry.dishGroupId);
      expect(stored.origin, 'proposal:${card.id}');
    }
    expect(
      entries.fold<double>(0, (sum, e) => sum + e.kcal),
      closeTo(card.totals.kcal, 1e-9),
    );
  });
  // rule: A21 read-only-adapter
  test(
    'A21 building and adjusting proposals write no rows or outbox',
    () async {
      final h = PersonalHarness();
      final before = await h.raw();
      final input =
          await ProposalInputLoader(
            h.db,
            catalog: ownedCatalog(h.db),
            config: () => ClientConfigRepository.defaults,
          ).load(
            interpretation: t01(),
            messageId: '019a1b2c-0000-7000-8000-000000009999',
            idSource: FixedIds(),
            referenceTime: context().referenceTime,
          );
      final s = ProposalEngine.build(input.value!).value!;
      final adjusted = ProposalEngine.recompute(
        s,
        ProposalSetAmount(
          s.cards.single.lines.first.entry.id,
          Quantity(2, 'piece'),
        ),
      );
      expect(adjusted.issue, isNull);
      expect(await h.raw(), before);
    },
  );
  test(
    'AI-031 confirmed applier snapshots equal every preview line and total',
    () async {
      const personalKey = '019a1b2c-0000-7000-8000-000000001234';
      final plate = serving('plate', 350)
        ..['rangeLo'] = 250.0
        ..['rangeHi'] = 450.0;
      final reference = food(
        key: 'ref:dish',
        source: 'reference',
        servings: [plate],
      )..['ranges'] = {'low': n(100), 'high': n(200)};
      final estimate = item(amount: 100, unit: 'g')
        ..['match'] = null
        ..['estimate'] = {
          'range': {'low': n(100), 'high': n(200)},
        };
      final fat = fatDimension()..['statedValue'] = 'oil';
      for (final raw in [
        t01(),
        message([
          intent([
            item(match: reference, explicit: false, unit: 'plate'),
            estimate,
            item(
              dimensions: [fat],
              explicit: false,
              share: {'fraction': .5, 'people': 2},
            ),
          ], group: 'dish'),
        ]),
        message([
          intent([
            item(
              match: food(key: personalKey, source: 'personal'),
              amount: 100,
              unit: 'ml',
            ),
          ]),
        ]),
      ]) {
        final h = PersonalHarness();
        await h.apply([
          CreatePersonalFood(
            personalKey,
            PersonalFoodDraft(
              names: FoodNames('Personal milk'),
              per100: nutrients(60),
              basis: .per100ml,
            ),
          ),
        ]);
        final request =
            (await ProposalInputLoader(
                  h.db,
                  catalog: ownedCatalog(h.db),
                  config: () => ClientConfigRepository.defaults,
                ).load(
                  interpretation: raw,
                  messageId: '019a1b2c-0000-7000-8000-000000009999',
                  idSource: FixedIds(),
                  referenceTime: context().referenceTime,
                ))
                .value!;
        final card = ProposalEngine.build(request).value!.cards.single;
        expect(
          await h.applier.apply(
            ChangeSet(card.draftOps, origin: Origin.proposal(card.id)),
          ),
          isA<Applied>(),
        );
        final entries = await h.db.select(h.db.diaryEntries).get();
        for (final line in card.lines) {
          final r = entries.singleWhere((r) => r.id == line.entry.id);
          expect(
            [r.kcal, r.proteinG, r.carbsG, r.fatG, r.fiberG],
            [
              line.snapshot.kcal,
              line.snapshot.protein,
              line.snapshot.carbs,
              line.snapshot.fat,
              line.snapshot.fiber,
            ],
          );
          expect(r.nameEn, line.entry.food.names.en);
          expect(r.foodKind, line.entry.food.ref.kind.code);
          expect(r.foodId, line.entry.food.ref.id);
          expect(r.foodVersion, line.entry.food.ref.version);
          expect(r.source, line.entry.food.provenance.source.code);
          expect(r.isEstimate, line.entry.food.provenance.isEstimate);
          expect(r.amount, line.entry.amount.amount);
          expect(r.inputAmount, line.entry.amount.input.amount);
          expect(r.inputUnit, line.entry.amount.input.unitCode);
          expect(
            r.assumptionsJson == null
                ? <Object?>[]
                : jsonDecode(r.assumptionsJson!),
            line.entry.food.provenance.assumptions,
          );
          expect(
            provenanceOf(
              r.source,
              r.estimateRangeJson,
              r.assumptionsJson,
              isEstimate: r.isEstimate,
            ),
            line.entry.food.provenance,
          );
          expect(r.origin, 'proposal:${card.id}');
        }
        expect(
          entries.fold<double>(0, (s, r) => s + r.kcal),
          closeTo(card.totals.kcal, 1e-9),
        );
      }
    },
  );
  test(
    'AI-020 confirmation creates group before its ingredient entries',
    () async {
      final h = PersonalHarness();
      final card = session(t01()).cards.single;
      expect(card.draftOps.first, isA<CreateDishGroup>());
      expect(card.draftOps.last, isA<LogEntries>());
      expect(
        await h.applier.apply(
          ChangeSet(card.draftOps, origin: Origin.proposal(card.id)),
        ),
        isA<Applied>(),
      );
      final group = (await h.db.select(h.db.dishGroups).get()).single;
      final entries = await h.db.select(h.db.diaryEntries).get();
      expect(
        entries.every(
          (e) =>
              e.dishGroupId == group.id &&
              e.localDate == group.localDate &&
              e.slotId == group.slotId,
        ),
        isTrue,
      );
    },
  );
  // rule: A21 duplicate-confirmation
  test('A21 duplicate confirmation cannot log entries twice', () async {
    final h = PersonalHarness();
    final card = session(t01()).cards.single;
    final set = ChangeSet(card.draftOps, origin: Origin.proposal(card.id));
    expect(await h.applier.apply(set), isA<Applied>());
    final before = await h.raw();
    expect(await h.applier.apply(set), isA<Rejected>());
    expect(await h.raw(), before);
  });
  // rule: A21 version-guard
  test(
    'A21 personal food changed since preview rejects confirmation atomically',
    () async {
      final h = PersonalHarness();
      const key = '019a1b2c-0000-7000-8000-000000001234';
      await h.apply([CreatePersonalFood(key, draft('Private'))]);
      final input =
          (await ProposalInputLoader(
                h.db,
                catalog: ownedCatalog(h.db),
                config: () => ClientConfigRepository.defaults,
              ).load(
                interpretation: message([
                  intent([
                    item(),
                    item(
                      match: food(key: key, source: 'personal'),
                      amount: 100,
                      unit: 'g',
                    ),
                  ], group: 'dish'),
                ]),
                messageId: '019a1b2c-0000-7000-8000-000000009999',
                idSource: FixedIds(),
                referenceTime: context().referenceTime,
              ))
              .value!;
      final card = ProposalEngine.build(input).value!.cards.single;
      await h.apply([UpdatePersonalFood(key, 1, draft('Changed'))]);
      final before = await h.raw();
      final result = await h.applier.apply(
        ChangeSet(card.draftOps, origin: Origin.proposal(card.id)),
      );
      expect(
        result,
        isA<Rejected>().having(
          (r) => r.failure,
          'failure',
          isA<VersionConflict>(),
        ),
      );
      expect(await h.raw(), before);
    },
  );
}

OfflineCatalog ownedCatalog(AppDatabase db) {
  final catalog = OfflineCatalog(db);
  addTearDown(catalog.dispose);
  return catalog;
}
