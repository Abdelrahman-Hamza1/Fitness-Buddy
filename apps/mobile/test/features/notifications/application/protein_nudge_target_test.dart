import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/notifications/application/notification_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

IntakeTotals _day({required double protein, int proteinUnknown = 0}) =>
    IntakeTotals.fromCounts(
      sum: Nutrients(kcal: 1500, protein: protein, carbs: 0, fat: 0, fiber: 0),
      items: 2,
      estimates: proteinUnknown,
      proteinUnknown: proteinUnknown,
    );

void main() {
  test('A62 D10 unknown or partial protein below the target suppresses the '
      'protein nudge; known protein or a certain hit keeps it', () {
    // Partial (an estimate without protein) and below 120 g: unknown, no
    // nudge.
    expect(proteinNudgeTarget(120, _day(protein: 40, proteinUnknown: 1)), null);
    // Nothing known about protein: no nudge.
    expect(proteinNudgeTarget(120, _day(protein: 0, proteinUnknown: 2)), null);
    // Fully known and low: the nudge stays.
    expect(proteinNudgeTarget(120, _day(protein: 40)), 120);
    // Partial but already at the target: a certain hit, compared as usual.
    expect(proteinNudgeTarget(120, _day(protein: 130, proteinUnknown: 1)), 120);
    // Nothing logged today, or no target.
    expect(proteinNudgeTarget(120, null), 120);
    expect(proteinNudgeTarget(null, _day(protein: 0, proteinUnknown: 2)), null);
  });
}
