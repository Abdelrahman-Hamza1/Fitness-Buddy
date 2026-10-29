import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/presentation/slots/slots_support.dart' show pickTime;
import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/weigh_in_sheet_support.dart';

/// The "When" chip's value.
String whenValue(WidgetTester tester) => tester
    .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, 'When'))
    .value!;

/// Picks [day] of the current month in the open date picker, then [hour12]
/// : [minute] in the time picker that follows.
Future<void> pickWhen(
  WidgetTester tester,
  int day,
  int hour12,
  int minute, {
  required bool pm,
}) async {
  await tester.tap(find.widgetWithText(FbChoiceChip, 'When'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(Dialog), matching: find.text('$day')),
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await pickTime(tester, hour12, minute, pm: pm);
}

final LocalDate yesterday = day17.plusDays(-1);

void main() {
  testWidgets('WB-001 the pad opens prefilled with the latest weigh-in in '
      'the shown unit; the first digit replaces it', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [
      weighInDraft(98.2, date: yesterday.plusDays(-1)),
      weighInDraft(97.4, date: yesterday),
    ]);
    await openSheet(tester, rig);
    expect(find.text('Log weigh-in'), findsOneWidget);
    expect(shownAmount(tester), '97.4');
    expect(shownUnit(tester), 'kg');
    expect(isEnabled(tester, button('Save')), isTrue);

    await typeOnPad(tester, '9');
    expect(shownAmount(tester), '9');
    await typeOnPad(tester, '6.8');
    expect(shownAmount(tester), '96.8');
    await unmount(tester, rig);

    // The imperial setting shows the latest one converted to lb.
    final imperial = SheetRig()..units.value = UnitSystem.imperial;
    await imperial.seed(tester, [weighInDraft(97.4, date: yesterday)]);
    await openSheet(tester, imperial);
    expect(shownAmount(tester), '214.7');
    expect(shownUnit(tester), 'lb');
    await unmount(tester, imperial);
  });

  testWidgets('TG-002 the pad accepts kg or lb whatever the setting; '
      'switching relabels the typed number', (tester) async {
    final rig = SheetRig();
    await openSheet(tester, rig);
    expect(shownAmount(tester), '0');
    expect(isEnabled(tester, button('Save')), isFalse);
    await typeOnPad(tester, '214');
    await tester.tap(
      find.descendant(of: find.byType(FbUnitPicker), matching: find.text('lb')),
    );
    await tester.pump();
    expect(shownAmount(tester), '214');
    expect(shownUnit(tester), 'lb');

    await tester.tap(button('Save'));
    await settle(tester);
    final stored = (await rig.live(tester)).single;
    expect(stored.input, const WeighInInput(214, MassUnit.pound));
    expect(stored.kg, 97.07);
    expect(find.text('Weigh-in saved: 214.0 lb'), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('UX-030 logging pushes an undo entry and shows Weigh-in saved '
      'with Undo', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97.4, date: yesterday)]);
    await openSheet(tester, rig);
    await typeOnPad(tester, '97');
    // The pad's Done closes the pad (m3); Save stays pinned.
    await tester.tap(
      find.descendant(
        of: find.byType(FbNumberPad),
        matching: find.text('Done'),
      ),
    );
    await tester.pump();
    expect(find.byType(FbNumberPad), findsNothing);
    expect(find.text('Log weigh-in'), findsOneWidget);
    expect(await rig.live(tester), hasLength(1));
    // Tapping the amount opens the pad again.
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    expect(find.byType(FbNumberPad), findsOneWidget);
    await tester.tap(button('Save'));
    await settle(tester);
    expect(find.byType(FbNumberPad), findsNothing);
    expect(find.text('Weigh-in saved: 97.0 kg'), findsOneWidget);
    expect(rig.stack.latest!.label.key, 'weighInLogged');
    expect(await rig.live(tester), hasLength(2));

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await rig.live(tester)).single.kg, 97.4);
    await unmount(tester, rig);
  });

  testWidgets('WB-005 an implausible change shows the in-sheet confirm; Save '
      'saves, Edit returns to the pad', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97, date: yesterday)]);
    await openSheet(tester, rig);
    await typeOnPad(tester, '100');
    await tester.tap(button('Save'));
    await settle(tester);
    const message =
        "That's +3.0 kg from your weigh-in yesterday (97.0 kg). Save it?";
    expect(find.text(message), findsOneWidget);
    expect(find.byType(FbNumberPad), findsNothing);
    expect(await rig.live(tester), hasLength(1));
    // Its answers replace the pinned Save; the banner is the message only.
    expect(button('Save'), findsNothing);
    expect(button('Save 100.0 kg'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FbInlineBanner),
        matching: find.byType(FbButton),
      ),
      findsNothing,
    );

    // Edit: back to the pad, nothing saved.
    await pastConfirmGuard(tester);
    await tester.tap(button('Edit'));
    await settle(tester);
    expect(find.text(message), findsNothing);
    expect(find.byType(FbNumberPad), findsOneWidget);
    expect(shownAmount(tester), '100');

    await tester.tap(button('Save'));
    await settle(tester);
    await pastConfirmGuard(tester);
    await tester.tap(button('Save 100.0 kg'));
    await settle(tester);
    expect(find.text('Weigh-in saved: 100.0 kg'), findsOneWidget);
    expect((await rig.live(tester)).map((w) => w.kg), containsAll([97, 100]));
    await unmount(tester, rig);
  });

  testWidgets('WB-005 Did you mean lb: Save as lb stores 214 lb / 97.07 kg', (
    tester,
  ) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97, date: yesterday)]);
    await openSheet(tester, rig);
    await typeOnPad(tester, '214');
    await tester.tap(button('Save'));
    await settle(tester);
    expect(find.text('Did you mean 214.0 lb (97.1 kg)?'), findsOneWidget);
    expect(button('Keep kg'), findsOneWidget);
    expect(button('Save'), findsNothing);

    await pastConfirmGuard(tester);
    await tester.tap(button('Save as 214.0 lb'));
    await settle(tester);
    final added = (await rig.live(tester)).singleWhere((w) => w.kg != 97);
    expect(added.input, const WeighInInput(214, MassUnit.pound));
    expect(added.kg, 97.07);
    expect(find.text('Weigh-in saved: 214.0 lb'), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('WB-003 a second weigh-in on a day shows the earlier one and '
      'the use-for-trend switch', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97.2, hour: 6, minute: 50)]);
    await openSheet(tester, rig);
    expect(
      find.text('Also on this day: 97.2 kg at 6:50 AM · used for the trend'),
      findsOneWidget,
    );
    final toggle = find.widgetWithText(
      FbSwitchRow,
      'Use this weigh-in for '
      'the trend',
    );
    expect(tester.widget<FbSwitchRow>(toggle).value, isFalse);

    await typeOnPad(tester, '97.8');
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<FbSwitchRow>(toggle).value, isTrue);
    await tester.tap(button('Save'));
    await settle(tester);
    final live = await rig.live(tester);
    final added = live.singleWhere((w) => w.id != fixtureId(1));
    expect(added.preferredForDay, isTrue);
    expect(DayChoice.of(live).single.id, added.id);
    await unmount(tester, rig);
  });

  testWidgets('WB-003 date and time default to now, can be changed, and a '
      "future time can't be saved", (tester) async {
    final rig = SheetRig();
    await openSheet(tester, rig);
    expect(whenValue(tester), 'Today, 3:00 PM');
    await typeOnPad(tester, '97.4');

    // A later time today is in the future: Save is off, the hint says why.
    await pickWhen(tester, 17, 11, 0, pm: true);
    expect(whenValue(tester), 'Today, 11:00 PM');
    expect(
      find.text('This time is in the future. Choose an earlier time.'),
      findsOneWidget,
    );
    expect(isEnabled(tester, button('Save')), isFalse);

    await pickWhen(tester, 16, 7, 30, pm: false);
    expect(whenValue(tester), 'Yesterday, 7:30 AM');
    expect(isEnabled(tester, button('Save')), isTrue);
    await tester.tap(button('Save'));
    await settle(tester);
    final stored = (await rig.live(tester)).single;
    expect(stored.localDate, yesterday);
    expect(stored.time.localDateTime.hour, 7);
    expect(stored.time.localDateTime.minute, 30);
    expect(find.text('Weigh-in saved: 97.4 kg for yesterday'), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('HM-009 opened from a past day page, the sheet logs to that day '
      "at now's clock time (PA3)", (tester) async {
    final rig = SheetRig();
    final day = day17.plusDays(-3);
    await openSheet(tester, rig, date: day);
    expect(whenValue(tester), 'Wed, Oct 14, 3:00 PM');
    await typeOnPad(tester, '97.4');
    await tester.tap(button('Save'));
    await settle(tester);
    final stored = (await rig.live(tester)).single;
    expect(stored.localDate, day);
    expect(stored.time.localDateTime.hour, 15);
    await unmount(tester, rig);
  });

  testWidgets("editing a weigh-in's date hides the use-for-trend switch and "
      'clears its preference', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [
      weighInDraft(97.2, hour: 6),
      weighInDraft(97.8, hour: 9),
    ]);
    final day = await rig.live(tester);
    await tester.runAsync(
      () => rig.h.apply([
        ChooseTrendWeighIn(
          day17,
          chosen: day.last.versionedId,
          dayWeighIns: [for (final w in day) w.versionedId],
        ),
      ]),
    );
    final preferred = (await rig.live(tester))
        .singleWhere((w) => w.id == fixtureId(2));
    expect(preferred.preferredForDay, isTrue);

    await openSheet(tester, rig, edit: preferred);
    expect(find.text('Edit weigh-in'), findsOneWidget);
    final toggle = find.byType(FbSwitchRow);
    expect(tester.widget<FbSwitchRow>(toggle).value, isTrue);

    await pickWhen(tester, 16, 9, 0, pm: false);
    expect(find.byType(FbSwitchRow), findsNothing);
    await tester.tap(button('Save'));
    await settle(tester);
    final moved = (await rig.live(tester))
        .singleWhere((w) => w.id == fixtureId(2));
    expect(moved.localDate, yesterday);
    expect(moved.preferredForDay, isFalse);
    expect(find.text('Weigh-in updated: 97.8 kg'), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('out-of-range values disable Save and show the range hint', (
    tester,
  ) async {
    final rig = SheetRig();
    await openSheet(tester, rig);
    // "19" can still become "190": Save is off, but no hint yet (m2).
    await typeOnPad(tester, '19');
    expect(find.textContaining('Enter a weight'), findsNothing);
    expect(isEnabled(tester, button('Save')), isFalse);
    await typeOnPad(tester, '.5');
    expect(
      find.text('Enter a weight between 20 kg and 500 kg'),
      findsOneWidget,
    );
    expect(isEnabled(tester, button('Save')), isFalse);
    await tester.tap(
      find.descendant(of: find.byType(FbUnitPicker), matching: find.text('lb')),
    );
    await tester.pump();
    expect(
      find.text('Enter a weight between 45 lb and 1,102 lb'),
      findsOneWidget,
    );
    await typeOnPad(tester, '<<<<150');
    expect(find.textContaining('Enter a weight'), findsNothing);
    expect(isEnabled(tester, button('Save')), isTrue);
    await unmount(tester, rig);
  });

  testWidgets('edit mode saves changes and deletes with undo; a weigh-in '
      'changed meanwhile shows the changed message', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97.4, note: 'after Eid')]);
    final shown = (await rig.live(tester)).single;

    await openSheet(tester, rig, edit: shown);
    expect(shownAmount(tester), '97.4');
    expect(find.text('after Eid'), findsOneWidget);
    await typeOnPad(tester, '96.4');
    await tester.tap(button('Save'));
    await settle(tester);
    expect(find.text('Weigh-in updated: 96.4 kg'), findsOneWidget);
    expect((await rig.live(tester)).single.kg, 96.4);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await rig.live(tester)).single.kg, 97.4);
    await unmount(tester, rig);

    // The weigh-in changed since `shown` was read (the undo above).
    final stale = SheetRig();
    await stale.seed(tester, [weighInDraft(97.4)]);
    final old = (await stale.live(tester)).single;
    await tester.runAsync(
      () => stale.h.apply([UpdateWeighIn(old.id, 1, weighInDraft(97.5))]),
    );
    await openSheet(tester, stale, edit: old);
    await typeOnPad(tester, '96');
    await tester.tap(button('Save'));
    await settle(tester);
    const changed =
        'This weigh-in changed since you opened it. Reload to see the '
        'latest. What you typed stays.';
    expect(find.text(changed), findsOneWidget);
    expect((await stale.live(tester)).single.kg, 97.5);
    // Reload (m6): the stored weigh-in at its new version, what was typed
    // stays; saving then works.
    await tester.tap(find.text('Reload'));
    await settle(tester);
    expect(find.text(changed), findsNothing);
    expect(shownAmount(tester), '96');
    await tester.tap(button('Save'));
    await settle(tester);
    final saved = (await stale.live(tester)).single;
    expect(saved.kg, 96);
    expect(saved.version, 3);
    expect(find.text('Weigh-in updated: 96.0 kg'), findsOneWidget);
    await unmount(tester, stale);

    final del = SheetRig();
    await del.seed(tester, [weighInDraft(97.4)]);
    await openSheet(tester, del, edit: (await del.live(tester)).single);
    await tester.tap(button('Delete weigh-in'));
    await settle(tester);
    expect(find.text('Weigh-in deleted'), findsOneWidget);
    expect(await del.live(tester), isEmpty);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await del.live(tester), hasLength(1));
    await unmount(tester, del);
  });

  testWidgets('a double tap on Save logs once', (tester) async {
    final rig = SheetRig();
    await openSheet(tester, rig);
    await typeOnPad(tester, '97.4');
    await tester.tap(button('Save'));
    await tester.tap(button('Save'), warnIfMissed: false);
    await settle(tester);
    expect(await rig.live(tester), hasLength(1));
    await unmount(tester, rig);
  });

  testWidgets('M1 an implausible value and a double tap on Save store '
      'nothing', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97, date: yesterday)]);
    await openSheet(tester, rig);
    await typeOnPad(tester, '100');
    // The second tap lands before the next frame (on Save), then right after
    // it (on the confirmation's own Save): both are ignored.
    await tester.tap(button('Save'));
    await tester.tap(button('Save'));
    await tester.pump();
    expect(button('Save 100.0 kg'), findsOneWidget);
    await tester.tap(button('Save 100.0 kg'));
    await settle(tester);
    expect(await rig.live(tester), hasLength(1));
    expect(find.textContaining("That's +3.0 kg"), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('M1 a likely unit mix-up and a double tap on Save never store '
      '214 kg', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97, date: yesterday)]);
    await openSheet(tester, rig);
    await typeOnPad(tester, '214');
    await tester.tap(button('Save'));
    await tester.tap(button('Save'));
    await tester.pump();
    // Whichever answer the second tap of a double tap lands on.
    await tester.tap(button('Keep kg'));
    await tester.tap(button('Save as 214.0 lb'));
    await settle(tester);
    expect(await rig.live(tester), hasLength(1));
    expect(find.text('Did you mean 214.0 lb (97.1 kg)?'), findsOneWidget);
    // Past the guard an answer is deliberate: saving as lb stores 214 lb,
    // never 214 kg.
    await pastConfirmGuard(tester);
    expect(button('Save as 214.0 lb'), findsOneWidget);
    await tester.tap(button('Save as 214.0 lb'));
    await settle(tester);
    final live = await rig.live(tester);
    expect(live.map((w) => w.kg), isNot(contains(214)));
    expect(
      live.map((w) => w.input),
      contains(const WeighInInput(214, MassUnit.pound)),
    );
    await unmount(tester, rig);
  });

  testWidgets('n6 the note field closes the pad; the amount opens it '
      'again', (tester) async {
    final rig = SheetRig();
    await openSheet(tester, rig);
    expect(find.byType(FbNumberPad), findsOneWidget);
    await tester.tap(find.widgetWithText(FbChoiceChip, 'Add a note'));
    await tester.pumpAndSettle();
    expect(find.byType(FbTextField), findsOneWidget);
    expect(find.byType(FbNumberPad), findsNothing);
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    expect(find.byType(FbNumberPad), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets("m6 logging when the day's other weigh-ins changed says so; "
      'saving again works', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97.2, hour: 6, minute: 50)]);
    final shown = await rig.live(tester);
    // The sheet sees the day as it was; meanwhile another weigh-in lands.
    final view = StreamController<List<WeighIn>>.broadcast();
    addTearDown(view.close);
    await openSheet(
      tester,
      rig,
      extra: [
        weighInsProvider.overrideWith((ref) async* {
          yield shown;
          yield* view.stream;
        }),
      ],
    );
    await tester.runAsync(
      () => rig.h.apply([
        CreateWeighIn(fixtureId(9), weighInDraft(97.3, hour: 8)),
      ]),
    );
    await typeOnPad(tester, '97.8');
    await tester.tap(find.byType(FbSwitchRow));
    await tester.pump();
    await tester.tap(button('Save'));
    await settle(tester);
    expect(
      find.text(
        'Other weigh-ins on this day changed. Check the trend choice and '
        'save again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reload'), findsNothing);
    expect(await rig.live(tester), hasLength(2));
    // The form gets the day as it is now: the retry saves.
    view.add(await rig.live(tester));
    await settle(tester);
    await tester.tap(button('Save'));
    await settle(tester);
    expect(await rig.live(tester), hasLength(3));
    await unmount(tester, rig);
  });

  testWidgets('security: a synced weigh-in with kg 1e306 does not break the '
      'sheet', (tester) async {
    final rig = SheetRig();
    final absurd = WeighIn(
      id: fixtureId(1),
      version: 1,
      time: weighInDraft(1, hour: 6).time,
      localDate: day17,
      kg: 1e306,
      input: const WeighInInput(1e306, MassUnit.kilogram),
    );
    await openSheet(
      tester,
      rig,
      extra: [
        weighInsProvider.overrideWith((ref) => Stream.value([absurd])),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(shownAmount(tester), '0');
    expect(find.textContaining('Also on this day'), findsNothing);
    await typeOnPad(tester, '97');
    expect(isEnabled(tester, button('Save')), isTrue);
    await unmount(tester, rig);
  });

  testWidgets('UX-051 a load failure says so, keeps Save off and offers Try '
      'again', (tester) async {
    final rig = SheetRig();
    var fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides,
          weighInsProvider.overrideWith(
            (ref) => fail
                ? Stream<List<WeighIn>>.error(StateError('read'))
                : Stream.value(const <WeighIn>[]),
          ),
        ],
        child: phoneApp(const SheetHost()),
      ),
    );
    await tester.tap(find.text(openLabel));
    await settle(tester);
    expect(find.text("Couldn't load your weigh-ins."), findsOneWidget);
    expect(find.byType(FbNumberPad), findsNothing);
    expect(isEnabled(tester, button('Save')), isFalse);

    fail = false;
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text("Couldn't load your weigh-ins."), findsNothing);
    expect(find.byType(FbNumberPad), findsOneWidget);
    await unmount(tester, rig);
  });
}
