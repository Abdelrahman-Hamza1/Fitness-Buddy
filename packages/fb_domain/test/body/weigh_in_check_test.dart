import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

void main() {
  WeighInCheckResult check(
    WeighInDraft candidate,
    List<WeighIn> others, {
    String? editingId,
  }) => WeighInCheck.check(
    candidate: candidate,
    others: others,
    editingId: editingId,
  );

  test('WB-005 a change over 3 % within 7 days asks for confirmation '
      '(97.0 → 100.0)', () {
    final last = storedOn(dayN(0), 97);
    final result = check(draftOn(dayN(3), 100), [last]);
    expect(result, LargeChange(reference: last, diffKg: 3));
    expect(
      check(draftOn(dayN(3), 94), [last]),
      LargeChange(reference: last, diffKg: -3),
    );
    expect(check(draftOn(dayN(3), 98.5), [last]), const Plausible());
  });

  test('WB-005 exactly 3 % does not ask (97.0 → 99.91)', () {
    final last = storedOn(dayN(0), 97);
    expect(check(draftOn(dayN(1), 99.91), [last]), const Plausible());
    expect(check(draftOn(dayN(1), 94.09), [last]), const Plausible());
    expect(check(draftOn(dayN(1), 99.92), [last]), isA<LargeChange>());
  });

  test('WB-005 the reference is the nearest earlier weigh-in within 7 days; '
      '8 days back means no 3 % check', () {
    final older = storedOn(dayN(0), 90);
    final nearer = storedOn(dayN(2), 97, id: weighInB);
    final result = check(draftOn(dayN(9), 100), [nearer, older]);
    expect(result, LargeChange(reference: nearer, diffKg: 3));
    expect(check(draftOn(dayN(10), 100), [nearer, older]), const Plausible());
    // The same day, earlier in the morning, counts as earlier.
    final sameDay = storedOn(dayN(9), 97, id: weighInC, hour: 6);
    expect(
      check(draftOn(dayN(9), 100), [older, sameDay, nearer]),
      LargeChange(reference: sameDay, diffKg: 3),
    );
  });

  test('WB-005 a backfilled weigh-in is checked against the next one within '
      '7 days', () {
    final next = storedOn(dayN(7), 97);
    final later = storedOn(dayN(9), 80, id: weighInB);
    expect(
      check(draftOn(dayN(0), 100), [later, next]),
      LargeChange(reference: next, diffKg: 3),
    );
    expect(check(draftOn(dayN(-1), 100), [later, next]), const Plausible());
    // An earlier weigh-in more than 7 days back hands over to the next one.
    final old = storedOn(dayN(-20), 100, id: weighInC);
    expect(
      check(draftOn(dayN(0), 100), [old, next]),
      LargeChange(reference: next, diffKg: 3),
    );
  });

  test('WB-005 214 kg after 97 kg suggests lb (97.07 kg); 97 lb after 214 lb '
      'suggests kg', () {
    final kg97 = storedOn(dayN(0), 97);
    expect(
      check(draftOn(dayN(1), 214), [kg97]),
      LikelyOtherUnit(
        suggestedUnit: MassUnit.pound,
        suggestedKg: 97.07,
        reference: kg97,
      ),
    );
    final lb214 = storedOn(dayN(0), 214, unit: MassUnit.pound);
    expect(lb214.kg, 97.07);
    expect(
      check(draftOn(dayN(1), 97, unit: MassUnit.pound), [lb214]),
      LikelyOtherUnit(
        suggestedUnit: MassUnit.kilogram,
        suggestedKg: 97,
        reference: lb214,
      ),
    );
    // Any distance in time: a year later is still a likely mix-up.
    expect(check(draftOn(dayN(365), 214), [kg97]), isA<LikelyOtherUnit>());
    // A backfill compares with the next weigh-in.
    expect(
      check(draftOn(dayN(-30), 214), [kg97]),
      LikelyOtherUnit(
        suggestedUnit: MassUnit.pound,
        suggestedKg: 97.07,
        reference: kg97,
      ),
    );
    // The other reading must be within 5 %, the typed one over 25 % away.
    expect(check(draftOn(dayN(30), 240), [kg97]), const Plausible());
    expect(check(draftOn(dayN(30), 120), [kg97]), const Plausible());
    // A suggestion outside the bounds is never made.
    // (A synced 600 kg row: 600 lb is in range, 600 kg isn't.)
    final synced = storedOn(dayN(0), 600);
    expect(
      check(draftOn(dayN(30), 600, unit: MassUnit.pound), [synced]),
      const Plausible(),
    );
  });

  test('WB-005 a unit mix-up is reported before a large change', () {
    final last = storedOn(dayN(0), 97);
    final result = check(draftOn(dayN(1), 214), [last]);
    expect(result, isA<LikelyOtherUnit>());
    expect(
      check(draftOn(dayN(1), 150), [last]),
      LargeChange(reference: last, diffKg: 53),
    );
  });

  test('WB-005 the first weigh-in is only checked against the bounds', () {
    expect(check(draftOn(dayN(0), 214), const []), const Plausible());
    expect(check(draftOn(dayN(0), 20), const []), const Plausible());
    // Out-of-range input is the bounds' message, not a check result.
    final last = storedOn(dayN(0), 97);
    expect(check(draftOn(dayN(1), 5), [last]), const Plausible());
    expect(
      check(draftOn(dayN(1), 214, unit: MassUnit.gram), [last]),
      const Plausible(),
    );
    // Synced rows without a readable kg are no reference.
    final broken = [
      storedOn(dayN(0), 97, kg: 0),
      storedOn(dayN(0), 97, id: weighInB, kg: double.nan),
      storedOn(dayN(0), 97, id: weighInC, kg: -97),
      storedOn(dayN(0), 97, id: weighInId(9), kg: 1e306),
    ];
    expect(check(draftOn(dayN(1), 214), broken), const Plausible());
  });

  test('WB-005 an edit is checked against its neighbours, not itself', () {
    final before = storedOn(dayN(0), 97);
    final edited = storedOn(dayN(1), 97.2, id: weighInB);
    final all = [before, edited];
    // The edit to 100.0: against itself (97.2 → 100) and the neighbour.
    expect(
      check(draftOn(dayN(1), 100), all, editingId: weighInB),
      LargeChange(reference: before, diffKg: 3),
    );
    expect(
      check(draftOn(dayN(1), 97.5), all, editingId: weighInB),
      const Plausible(),
    );
    // Alone, an edit has no reference at all.
    expect(
      check(draftOn(dayN(1), 150), [edited], editingId: weighInB),
      const Plausible(),
    );
  });

  test('WB-005 check results have value equality', () {
    final ref = storedOn(dayN(0), 97);
    final other = storedOn(dayN(0), 97, id: weighInB);
    expect(const Plausible(), const Plausible());
    expect(const Plausible().hashCode, const Plausible().hashCode);
    expect(
      const Plausible() == LargeChange(reference: ref, diffKg: 3),
      isFalse,
    );

    final unit = LikelyOtherUnit(
      suggestedUnit: MassUnit.pound,
      suggestedKg: 97.07,
      reference: ref,
    );
    expect(
      unit.hashCode,
      LikelyOtherUnit(
        suggestedUnit: MassUnit.pound,
        suggestedKg: 97.07,
        reference: ref,
      ).hashCode,
    );
    for (final different in [
      LikelyOtherUnit(
        suggestedUnit: MassUnit.kilogram,
        suggestedKg: 97.07,
        reference: ref,
      ),
      LikelyOtherUnit(
        suggestedUnit: MassUnit.pound,
        suggestedKg: 97.08,
        reference: ref,
      ),
      LikelyOtherUnit(
        suggestedUnit: MassUnit.pound,
        suggestedKg: 97.07,
        reference: other,
      ),
    ]) {
      expect(unit == different, isFalse);
    }
    expect(unit.suggestedUnit, MassUnit.pound);
    expect(unit.suggestedKg, 97.07);
    expect(unit.reference, ref);

    final change = LargeChange(reference: ref, diffKg: 3);
    expect(change, LargeChange(reference: ref, diffKg: 3));
    expect(change.hashCode, LargeChange(reference: ref, diffKg: 3).hashCode);
    expect(change == LargeChange(reference: other, diffKg: 3), isFalse);
    expect(change == LargeChange(reference: ref, diffKg: -3), isFalse);
    expect(change.reference, ref);
    expect(change.diffKg, 3);
  });
}
