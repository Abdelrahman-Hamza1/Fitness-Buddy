import 'package:fb_design_system/fb_design_system.dart' show NumberPadKey;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/application/weigh_in_form.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/weigh_in_harness.dart';

/// Now, as the harness applies: 2026-10-17 12:00 UTC (15:00 at UTC+03:00).
final DateTime now = harnessNow;

/// 2026-10-17 15:00 local (UTC+03:00), the sheet's default time.
final EntryTime nowTime = EntryTime(harnessNow, 180);

WeighInFormState logForm(
  List<WeighIn> weighIns, {
  MassUnit unit = MassUnit.kilogram,
  EntryTime? time,
}) =>
    WeighInFormState.log(weighIns: weighIns, unit: unit, time: time ?? nowTime);

WeighInFormState type(WeighInFormState form, String keys) {
  var next = form;
  for (final c in keys.split('')) {
    next = next.key(switch (c) {
      '.' => NumberPadKey.decimal,
      '<' => NumberPadKey.backspace,
      _ => NumberPadKey.digit(int.parse(c)),
    });
  }
  return next;
}

/// The local time [hour]:[minute] on [date] at UTC+03:00.
EntryTime at(LocalDate date, int hour, [int minute = 0]) =>
    EntryTime.local(LocalDateTime(date, hour: hour, minute: minute), 180);

void main() {
  final lastWeek = day17.plusDays(-6);

  group('prefill', () {
    test('WB-001 the pad opens prefilled with the latest weigh-in in the '
        'shown unit; the first digit replaces it', () {
      final history = [
        storedWeighIn(1, weighInDraft(98.2, date: lastWeek.plusDays(-1))),
        storedWeighIn(2, weighInDraft(97.4, date: lastWeek)),
      ];
      final kg = logForm(history);
      expect(kg.buffer, '97.4');
      expect(kg.prefilled, isTrue);
      expect(kg.unit, MassUnit.kilogram);

      // Shown in lb: converted to one decimal (97.4 kg = 214.73 lb).
      expect(logForm(history, unit: MassUnit.pound).buffer, '214.7');

      // Typed in lb and shown in lb: the typed value.
      final typedLb = [
        storedWeighIn(
          3,
          weighInDraft(214, date: lastWeek, unit: MassUnit.pound),
        ),
      ];
      expect(logForm(typedLb, unit: MassUnit.pound).buffer, '214.0');

      final typed = type(kg, '9');
      expect(typed.buffer, '9');
      expect(typed.prefilled, isFalse);
      expect(type(typed, '6.8').value, 96.8);
      // Same value as last time: Save needs no typing.
      expect(kg.draft!.input, const WeighInInput(97.4, MassUnit.kilogram));
    });

    test('no weigh-ins: the pad is empty and Save is off', () {
      final form = logForm(const []);
      expect(form.buffer, isEmpty);
      expect(form.prefilled, isFalse);
      expect(form.issueAt(now), WeighInFormIssue.empty);
      expect(form.save(now).$2, isNull);
    });

    test('the pad holds 4 digits and 1 decimal; a synced outlier that '
        "doesn't fit is not prefilled", () {
      expect(type(logForm(const []), '123456').buffer, '1234');
      expect(type(logForm(const []), '97.45').buffer, '97.4');
      final outlier = WeighIn(
        id: fixtureId(1),
        version: 1,
        time: nowTime,
        localDate: day17,
        kg: 20000,
        input: const WeighInInput(20000, MassUnit.kilogram),
      );
      expect(logForm([outlier]).buffer, isEmpty);
      // A typed value too large for the pad (security review 5): no
      // "1e+306" prefill.
      final huge = WeighIn(
        id: fixtureId(2),
        version: 1,
        time: nowTime,
        localDate: day17,
        kg: 97,
        input: const WeighInInput(1e306, MassUnit.kilogram),
      );
      expect(logForm([huge]).buffer, isEmpty);
    });

    test('security: a synced weigh-in with an unreadable kg (1e306) is '
        'neither prefilled, nor a reference, nor listed on its day', () {
      final absurd = WeighIn(
        id: fixtureId(1),
        version: 1,
        time: at(day17, 6),
        localDate: day17,
        kg: 1e306,
        input: const WeighInInput(1e306, MassUnit.kilogram),
      );
      final form = logForm([absurd]);
      expect(form.buffer, isEmpty);
      expect(form.weighIns, isEmpty);
      expect(form.sameDay, isEmpty);
      expect(type(form, '97').check, isA<Plausible>());
      expect(form.withWeighIns([absurd]).weighIns, isEmpty);
    });
  });

  test('TG-002 the pad accepts kg or lb whatever the setting; switching '
      'relabels the typed number', () {
    final form = type(logForm(const []), '214');
    final lb = form.withUnit(MassUnit.pound);
    expect(lb.value, 214);
    expect(lb.unit, MassUnit.pound);
    expect(lb.draft!.kg, 97.07);
    expect(identical(lb.withUnit(MassUnit.pound), lb), isTrue);
    final metric = type(
      logForm(const [], unit: MassUnit.pound),
      '97',
    ).withUnit(MassUnit.kilogram);
    expect(metric.draft!.input, const WeighInInput(97, MassUnit.kilogram));
  });

  group('WB-005 implausible values', () {
    final yesterday = storedWeighIn(
      1,
      weighInDraft(97, date: day17.plusDays(-1)),
    );

    test('WB-005 an implausible change shows the confirm; Save saves, Edit '
        'returns to the pad', () {
      final form = type(logForm([yesterday]), '100');
      final (asking, none) = form.save(now);
      expect(none, isNull);
      expect(asking.confirming, isA<LargeChange>());
      expect((asking.confirming! as LargeChange).diffKg, 3);

      // Edit: back to the pad, nothing saved.
      expect(asking.backToPad().confirming, isNull);
      // A key closes the confirmation too.
      expect(type(asking, '<').confirming, isNull);

      // Save (the banner's, or the pinned one again) submits as typed.
      for (final (next, submission) in [asking.confirm(), asking.save(now)]) {
        expect(next.confirming, isNull);
        expect(
          submission!.draft.input,
          const WeighInInput(100, MassUnit.kilogram),
        );
        expect(submission.editing, isNull);
      }
    });

    test('WB-005 Did you mean lb: Save as lb stores 214 lb / 97.07 kg; Keep '
        'kg keeps what was typed', () {
      final (asking, _) = type(logForm([yesterday]), '214').save(now);
      final unit = asking.confirming! as LikelyOtherUnit;
      expect(unit.suggestedUnit, MassUnit.pound);
      expect(unit.suggestedKg, 97.07);

      final (asLb, lb) = asking.confirm(otherUnit: true);
      expect(asLb.unit, MassUnit.pound);
      expect(lb!.draft.input, const WeighInInput(214, MassUnit.pound));
      expect(lb.draft.kg, 97.07);

      final (_, kg) = asking.confirm();
      expect(kg!.draft.input, const WeighInInput(214, MassUnit.kilogram));
    });
  });

  group('WB-003 same day', () {
    final early = storedWeighIn(1, weighInDraft(97.2, hour: 6, minute: 50));

    test('WB-003 a second weigh-in on a day shows the earlier one, which the '
        'trend uses, and the use-for-trend switch', () {
      final form = type(logForm([early]), '97.8');
      expect(form.sameDay, [early]);
      expect(form.usedForTrendNow, early);
      expect(form.showTrendSwitch, isTrue);
      expect(form.defaultForTrend, isFalse);
      expect(form.forTrend, isFalse);
      expect(form.save(now).$2!.trend, isNull);

      final on = form.withUseForTrend(on: true);
      expect(on.forTrend, isTrue);
      final pick = on.save(now).$2!.trend!;
      expect(pick.useThis, isTrue);
      expect(pick.dayOthers, [early]);

      // Back to the default: no pick.
      expect(on.withUseForTrend(on: false).trendPick, isNull);
    });

    test('WB-003 a backfilled earlier weigh-in is the default choice; '
        'switching it off picks the other one', () {
      final form = type(logForm([early]), '97.0').withTime(at(day17, 6));
      expect(form.defaultForTrend, isTrue);
      expect(form.forTrend, isTrue);
      expect(form.trendPick, isNull);
      final off = form.withUseForTrend(on: false).trendPick!;
      expect(off.useThis, isFalse);
      expect(off.dayOthers, [early]);
    });

    test('a preferred weigh-in on the day wins over a new earlier one', () {
      final preferred = storedWeighIn(
        1,
        weighInDraft(97.2, hour: 9),
        preferred: true,
      );
      final form = type(logForm([preferred]), '97.0').withTime(at(day17, 6));
      expect(form.usedForTrendNow, preferred);
      expect(form.defaultForTrend, isFalse);
    });
  });

  group('edit', () {
    final stored = storedWeighIn(
      2,
      weighInDraft(97.8, hour: 8, note: 'after Eid'),
      version: 3,
    );
    final early = storedWeighIn(1, weighInDraft(97.2, hour: 6));

    test('opens with the value and unit as typed, the time and the note; '
        'checks against the others, not itself', () {
      final lb = storedWeighIn(
        3,
        weighInDraft(214.5, unit: MassUnit.pound, date: lastWeek),
      );
      final form = WeighInFormState.edit(lb, weighIns: [lb]);
      expect(form.isEdit, isTrue);
      expect(form.buffer, '214.5');
      expect(form.prefilled, isTrue);
      expect(form.unit, MassUnit.pound);
      expect(form.time, lb.time);
      expect(form.draft, lb.draft);
      // Alone, it is the first weigh-in: no check against itself.
      expect(type(form, '300').check, isA<Plausible>());

      final noted = WeighInFormState.edit(stored, weighIns: [early, stored]);
      expect(noted.note, 'after Eid');
      final (_, submission) = noted.save(now);
      expect(submission!.editing, stored);
      expect(submission.draft, stored.draft);
    });

    test("editing a weigh-in's date hides the use-for-trend switch and "
        'drops its pick (PA6)', () {
      final preferred = storedWeighIn(
        2,
        weighInDraft(97.8, hour: 8),
        preferred: true,
      );
      final form = WeighInFormState.edit(
        preferred,
        weighIns: [early, preferred],
      );
      expect(form.showTrendSwitch, isTrue);
      expect(form.defaultForTrend, isTrue);
      final off = form.withUseForTrend(on: false);
      expect(off.trendPick!.useThis, isFalse);

      final moved = off.withTime(at(day17.plusDays(-1), 8));
      expect(moved.dateMoved, isTrue);
      expect(moved.showTrendSwitch, isFalse);
      expect(moved.trendPick, isNull);
      expect(moved.save(now).$2!.trend, isNull);
      // Back on the stored day the switch returns.
      expect(moved.withTime(at(day17, 9)).showTrendSwitch, isTrue);
    });

    test('an untouched prefill saves the stored value exactly: a note '
        "change doesn't round 97.25 to 97.3", () {
      final precise = storedWeighIn(5, weighInDraft(97.25));
      final form = WeighInFormState.edit(precise, weighIns: [precise]);
      expect(form.buffer, anyOf('97.2', '97.3'));
      final noted = form.withNote('after a run');
      final (_, submission) = noted.save(now);
      expect(
        submission!.draft.input,
        const WeighInInput(97.25, MassUnit.kilogram),
      );
      expect(submission.draft.note, 'after a run');
      // Typing replaces it as usual.
      expect(type(noted, '97.3').save(now).$2!.draft.input.value, 97.3);
      // A unit switch relabels the shown number (TG-002).
      final lb = form.withUnit(MassUnit.pound);
      expect(lb.input!.unit, MassUnit.pound);
      expect(lb.input!.value, double.parse(form.buffer));
    });

    test('m6 Reload takes the stored weigh-in at its new version and keeps '
        'what was changed', () {
      final opened = storedWeighIn(5, weighInDraft(97.4, note: 'a'));
      final now2 = storedWeighIn(
        5,
        weighInDraft(97.6, hour: 8, note: 'b'),
        version: 2,
      );
      // Typed a value only: it stays; the time and note follow the store.
      final typed = type(
        WeighInFormState.edit(opened, weighIns: [opened]),
        '96.8',
      ).withWeighIns([now2]);
      final reloaded = typed.reload()!;
      expect(reloaded.editing, now2);
      expect(reloaded.buffer, '96.8');
      expect(reloaded.prefilled, isFalse);
      expect(reloaded.time, now2.time);
      expect(reloaded.note, 'b');
      expect(reloaded.save(now).$2!.editing!.version, 2);

      // Changed the note only: the value follows the store, the note stays.
      final noted = WeighInFormState.edit(
        opened,
        weighIns: [opened],
      ).withNote('mine').withWeighIns([now2]).reload()!;
      expect(noted.buffer, '97.6');
      expect(noted.prefilled, isTrue);
      expect(noted.note, 'mine');

      // Deleted meanwhile: nothing to reload. Logging: unchanged.
      expect(
        WeighInFormState.edit(
          opened,
          weighIns: [opened],
        ).withWeighIns(const []).reload(),
        isNull,
      );
      final log = logForm(const []);
      expect(log.reload(), same(log));
    });
  });

  group('Save off', () {
    test('out-of-range values disable Save with the range issue', () {
      for (final (keys, unit) in [
        ('19.9', MassUnit.kilogram),
        ('500.1', MassUnit.kilogram),
        ('44', MassUnit.pound),
        ('1102.4', MassUnit.pound),
        ('0', MassUnit.kilogram),
      ]) {
        final form = type(logForm(const [], unit: unit), keys);
        expect(form.issueAt(now), WeighInFormIssue.outOfRange, reason: keys);
        expect(form.save(now).$2, isNull);
      }
      for (final (keys, unit) in [
        ('20', MassUnit.kilogram),
        ('500', MassUnit.kilogram),
        ('44.1', MassUnit.pound),
        ('1102.3', MassUnit.pound),
      ]) {
        expect(
          type(logForm(const [], unit: unit), keys).issueAt(now),
          isNull,
          reason: keys,
        );
      }
    });

    test("WB-003 a future time can't be saved; a time before 1970 is too "
        'early', () {
      final form = type(logForm(const []), '97');
      // Within the 5-minute clock-skew tolerance: fine.
      expect(
        form
            .withTime(EntryTime(now.add(const Duration(minutes: 5)), 180))
            .issueAt(now),
        isNull,
      );
      final future = form.withTime(
        EntryTime(now.add(const Duration(minutes: 6)), 180),
      );
      expect(future.issueAt(now), WeighInFormIssue.future);
      expect(future.save(now).$2, isNull);
      final early = form.withTime(at(LocalDate(1970, 1, 1), 2));
      expect(early.issueAt(now), WeighInFormIssue.tooEarly);
    });

    test('the note is limited by code points and refuses control '
        'characters; an emoji ZWJ sequence or RLM is fine', () {
      final form = type(logForm(const []), '97');
      expect(form.withNote('x' * 200).issueAt(now), isNull);
      // An emoji is one code point (two UTF-16 units): 200 fits, 201 not.
      expect(form.withNote('${'x' * 199}\u{1F600}').issueAt(now), isNull);
      expect(
        form.withNote('${'x' * 200}\u{1F600}').issueAt(now),
        WeighInFormIssue.noteTooLong,
      );
      expect(form.withNote('a\tb').issueAt(now), WeighInFormIssue.noteInvalid);
      expect(
        form
            .withNote('\u{1F468}\u200D\u{1F469} \u200F\u0639\u064A\u062F')
            .issueAt(now),
        isNull,
      );
      expect(form.withNote('  ').save(now).$2!.draft.note, isNull);
    });
  });
}
