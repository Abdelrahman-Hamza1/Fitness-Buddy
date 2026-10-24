import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart';
import '../diary/support/diary_harness.dart';

void main() {
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
}
