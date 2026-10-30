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
