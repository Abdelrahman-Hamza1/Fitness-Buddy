import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';
import 'proposal_fixtures.dart';
import 'proposal_rebuild_test.dart' show follow;

void main() {
  group('AmountStep', () {
    test('AI-040 amount step moves by unit kind and never below the smallest '
        'step', () {
      expect(AmountStep.up(Quantity(2, 'piece')), Quantity(3, 'piece'));
      expect(AmountStep.down(Quantity(2, 'piece')), Quantity(1, 'piece'));
      expect(AmountStep.down(Quantity(1, 'piece')), Quantity(0.5, 'piece'));
      expect(AmountStep.down(Quantity(0.5, 'piece')), isNull);
      expect(AmountStep.up(Quantity(0.5, 'tbsp')), Quantity(1, 'tbsp'));
      expect(AmountStep.up(Quantity(1, 'tbsp')), Quantity(2, 'tbsp'));
      expect(AmountStep.up(Quantity(1.3, 'cup')), Quantity(2, 'cup'));
      expect(AmountStep.up(Quantity(45, 'g')), Quantity(50, 'g'));
      expect(AmountStep.up(Quantity(50, 'g')), Quantity(60, 'g'));
      expect(AmountStep.down(Quantity(50, 'g')), Quantity(45, 'g'));
      expect(AmountStep.up(Quantity(200, 'ml')), Quantity(225, 'ml'));
      expect(AmountStep.down(Quantity(200, 'ml')), Quantity(190, 'ml'));
      expect(AmountStep.up(Quantity(143, 'g')), Quantity(150, 'g'));
      expect(AmountStep.down(Quantity(143, 'g')), Quantity(140, 'g'));
      expect(AmountStep.down(Quantity(7, 'g')), Quantity(5, 'g'));
      expect(AmountStep.down(Quantity(5, 'g')), isNull);
      expect(AmountStep.down(Quantity(3, 'g')), isNull);
    });

    Glados2(
      any.doubleInRange(0.01, 5000),
      any.choose(['g', 'ml', 'piece', 'tbsp', 'cup']),
      propertyRuns,
    ).test('A22 amount step keeps the unit and moves strictly in its '
        'direction', (amount, unit) {
      final q = Quantity(amount, unit);
      final up = AmountStep.up(q);
      expect(up.unitCode, unit);
      expect(up.amount, greaterThan(amount));
      final down = AmountStep.down(q);
      if (amount <= AmountStep.smallest(unit)) {
        expect(down, isNull);
      } else {
        expect(down!.unitCode, unit);
        expect(down.amount, lessThan(amount));
        expect(down.amount, greaterThanOrEqualTo(AmountStep.smallest(unit)));
      }
    });
  });

  group('ProposalLine', () {
    test('AI-040 assumed amount stays assumed after the user steps it', () {
      final s = session(
        message([
          intent([
            item(explicit: false),
            item(match: food(key: 'usda:bread', kcal: 250)),
          ]),
        ]),
      );
      final lines = s.cards.single.lines;
      expect(lines.first.amountAssumed, isTrue);
      expect(lines.last.amountAssumed, isFalse);
      final stepped = ProposalEngine.recompute(
        s,
        ProposalSetAmount(lines.first.entry.id, Quantity(2, 'piece')),
      ).value!.session;
      final line = stepped.cards.single.lines.first;
      expect(line.entry.amount.input, Quantity(2, 'piece'));
      expect(line.amountAssumed, isTrue);
    });

    test('AI-040 a stepped line keeps its stepper after a follow-up states '
        'the amount', () {
      final ids = FixedIds();
      final s = session(
        message([
          intent([item(explicit: false)]),
        ]),
        ids: ids,
      );
      final line = s.cards.single.lines.single;
      final stepped = ProposalEngine.recompute(
        s,
        ProposalSetAmount(line.entry.id, Quantity(2, 'piece')),
      ).value!.session;
      final rebuilt = ProposalEngine.rebuild(
        stepped.cards.single,
        follow(
          message([
            intent([item(amount: 3)]),
          ]),
          ids,
        ),
      ).value!.session.cards.single.lines.single;
      expect(rebuilt.entry.id, line.entry.id);
      expect(rebuilt.entry.amount.input, Quantity(3, 'piece'));
      expect(rebuilt.amountAssumed, isTrue);
      // A line whose amount was stated from the start never gets one.
      final stated = session(message()).cards.single.lines.single;
      expect(stated.amountAssumed, isFalse);
    });

    test('AI-041 line alternatives are at most three distinct foods never the '
        'selected one', () {
      final s = session(
        message([
          intent([
            item(
              match: food(key: 'usda:a', kcal: 100),
              alternatives: [
                food(key: 'usda:a', kcal: 100),
                food(key: 'usda:b', kcal: 110),
                food(key: 'usda:b', kcal: 110),
                food(key: 'usda:c', kcal: 120),
                food(key: 'usda:d', kcal: 130),
              ],
            ),
          ]),
        ]),
      );
      final line = s.cards.single.lines.single;
      final keys = [for (final f in line.alternatives) f.key];
      expect(keys, ['usda:b', 'usda:c', 'usda:d']);
      // After a swap the old match is offered back, still three at most.
      final swapped = ProposalEngine.recompute(
        s,
        ProposalSwap(line.entry.id, line.alternatives.first),
      ).value!.session.cards.single.lines.single;
      final after = [for (final f in swapped.alternatives) f.key];
      expect(after.length, lessThanOrEqualTo(3));
      expect(after.toSet().length, after.length);
      expect(after, isNot(contains('usda:b')));
      expect(after, contains('usda:a'));
    });
  });
}
