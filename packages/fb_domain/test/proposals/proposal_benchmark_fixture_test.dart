import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../../benchmark/support/proposal_workload.dart';

void main() {
  // rule: A21 benchmark-fixture
  test(
    'A21 benchmark keeps six active lines oil yields range and weekly target',
    () {
      final workload = ProposalWorkload();
      final card = workload.session.cards.single;
      expect(card.lines, hasLength(6));
      expect(card.canConfirm, isTrue);
      expect(card.range, isNotNull);
      expect(card.preview.targetsUnavailable, isFalse);
      expect(card.lines.where((l) => l.yieldNote != null), isNotEmpty);
      expect(
        card.lines.where((l) => l.entry.food.ref.id == 'usda:oil'),
        hasLength(1),
      );
      expect(
        card.lines.expand((l) => l.dimensions).map((d) => d.kind),
        containsAll([
          ProposalDimensionKind.state,
          ProposalDimensionKind.fat,
          ProposalDimensionKind.portion,
        ]),
      );
      // Structural protocol regression only: no timers or timing assertions.
      for (var cycle = 0; cycle < 2; cycle++) {
        for (final adjustment in workload.adjustments) {
          final update = ProposalEngine.recompute(workload.session, adjustment);
          expect(update.issue, isNull);
          expect(update.value!.diff.isEmpty, isFalse);
          workload.session = update.value!.session;
          expect(workload.session.cards.single.lines, hasLength(6));
        }
      }
    },
  );
}
