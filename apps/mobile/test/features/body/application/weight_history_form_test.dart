import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/application/weight_history_form.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/weigh_in_harness.dart';

EntryTime _at8(LocalDate date) =>
    EntryTime.local(LocalDateTime(date, hour: 8), 180);

void main() {
  test('WB-001 the form starts with one undated row in the unit setting; '
      'Add row dates the next one a week later, capped at today', () {
    final start = WeightHistoryForm.start(MassUnit.pound);
    expect(start.rows, hasLength(1));
    expect(start.rows.single.date, isNull);
    expect(start.rows.single.unit, MassUnit.pound);
    expect(start.isDirty, isFalse);
    expect(start.canAddRow, isTrue);

    // Undated last row: the new one is undated too.
    final two = start.addRow(day17);
    expect(two.rows.last.date, isNull);
    expect(two.rows.map((r) => r.key).toSet(), hasLength(2));

    final dated = start.withDate(0, day17.plusDays(-20));
    expect(dated.isDirty, isTrue);
    final next = dated.addRow(day17);
    expect(next.rows.last.date, day17.plusDays(-13));
    final capped = next.addRow(day17).addRow(day17);
    expect(capped.rows.map((r) => r.date), [
      day17.plusDays(-20),
      day17.plusDays(-13),
      day17.plusDays(-6),
      day17,
    ]);
    expect(capped.toString(), 'WeightHistoryForm(4 rows)');
  });

  test('UX-052 removing rows never leaves the form empty; typed text marks it '
      'dirty', () {
    final form = WeightHistoryForm.start(MassUnit.kilogram)
        .withText(0, '97.4')
        .addRow(day17);
    expect(form.isDirty, isTrue);
    final one = form.remove(0);
    expect(one.rows, hasLength(1));
    expect(one.isDirty, isFalse);
    final reset = one.remove(one.rows.single.key);
    expect(reset.rows, hasLength(1));
    expect(reset.rows.single.key, isNot(one.rows.single.key));
    expect(
      WeightHistoryForm.start(MassUnit.kilogram).withText(0, '  ').isDirty,
      isFalse,
    );
  });

  test('LC-010 WB-005 the unit chips relabel every row; Use lb switches one '
      "row; edits clear that row's Keep", () {
    final base = WeightHistoryForm.start(MassUnit.kilogram)
        .withDate(0, day17.plusDays(-10))
        .withText(0, '97')
        .addRow(day17)
        .withText(1, '214');
    WeighInBatchResult check(WeightHistoryForm f) =>
        f.check(existing: const [], today: day17, timeFor: _at8);
    final result = check(base);
    final mixUp = result.rows[1];
    expect(mixUp.implausible, isA<LikelyOtherUnit>());

    final kept = base.keep(1, mixUp.keepToken!);
    expect(check(kept).rows[1].kept, isTrue);
    expect(check(kept).included, hasLength(2));
    // Editing the row clears its Keep.
    expect(kept.withText(1, '215').rows[1].keep, isNull);
    expect(kept.withDate(1, day17.plusDays(-2)).rows[1].keep, isNull);
    expect(kept.withRowUnit(1, MassUnit.pound).rows[1].keep, isNull);
    // The same text, date or unit keeps it.
    expect(kept.withText(1, '214').rows[1].keep, isNotNull);
    expect(kept.withDate(1, day17.plusDays(-3)).rows[1].keep, isNotNull);
    expect(kept.withRowUnit(1, MassUnit.kilogram).rows[1].keep, isNotNull);

    // Use lb: 214 lb is plausible after 97 kg.
    final lb = base.withRowUnit(1, MassUnit.pound);
    expect(lb.rows[1].unit, MassUnit.pound);
    expect(lb.rows[0].unit, MassUnit.kilogram);
    expect(check(lb).rows[1].flags, isEmpty);
    expect(check(lb).included.last.kg, 97.07);

    // The chips: every row in lb, new rows too; numbers unchanged.
    final allLb = kept.withUnit(MassUnit.pound);
    expect(allLb.unit, MassUnit.pound);
    expect(allLb.rows.map((r) => r.unit).toSet(), {MassUnit.pound});
    expect(allLb.rows.map((r) => r.text), ['97', '214']);
    expect(allLb.rows[1].keep, isNull);
    expect(allLb.addRow(day17).rows.last.unit, MassUnit.pound);
    expect(base.rows[1].toString(), isNot(contains('214')));
  });
}
