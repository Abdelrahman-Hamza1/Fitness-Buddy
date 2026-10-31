import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart' show weighInDraft;
import '../../diary/presentation/slots/slots_support.dart' show button, unmount;
import '../../diary/support/diary_fixtures.dart' show fixtureId;
import 'support/today_support.dart';
import 'today_actions_test.dart' show pumpRig, settle;
import 'today_edit_test.dart' show pad, useTallPhone;

/// Today with a weigh-in of 97.4 kg yesterday (09:00 local, UTC+00:00 on
/// the rig's clock) on a tall phone, so the sheet shows whole.
Future<TodayRig> todayWithWeighIn(WidgetTester tester) async {
  final rig = TodayRig();
  await tester.runAsync(
    () => rig.diary.apply([
      CreateWeighIn(
        fixtureId(500),
        weighInDraft(97.4, date: testYesterday, hour: 9),
      ),
    ]),
  );
  await pumpRig(tester, rig);
  useTallPhone(tester);
  await settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byKey(ValueKey<LocalDate>(testToday)),
      matching: find.byKey(const ValueKey('fb-slide-dot-1')),
    ),
  );
  await settle(tester);
  return rig;
}

Future<List<WeighIn>> stored(WidgetTester tester, TodayRig rig) async =>
    (await tester.runAsync(
      () => WeighInRepository(rig.diary.db).watchLive().first,
    ))!;

/// The weight card of today's page.
Finder todayCard() => find.descendant(
  of: find.byKey(ValueKey<LocalDate>(testToday)),
  matching: find.byType(WeightSlide),
);

/// The ＋ of today's slim weight row.
Finder slimAdd() => find.descendant(
  of: todayCard(),
  matching: find.byKey(const ValueKey('today-weigh-in')),
);

void main() {
  testWidgets('WB-001 UX-005 a weigh-in is logged in 3 taps from Today', (
    tester,
  ) async {
    final rig = await todayWithWeighIn(tester);
    var taps = 0;
    Future<void> tap(Finder finder) async {
      taps++;
      await tester.tap(finder);
      await settle(tester);
    }

    // Tap 1: the card's first row opens the pad, prefilled with 97.4 kg.
    expect(todayCard(), findsOneWidget);
    await tap(slimAdd());
    expect(find.text('Log weigh-in'), findsOneWidget);
    expect(
      tester.widget<FbAmountDisplay>(find.byType(FbAmountDisplay)).amount,
      '97.4',
    );
    // Tap 2: Save. Same value as last time: no typing at all.
    await tap(button('Save'));
    expect(taps, 2);
    var live = await stored(tester, rig);
    expect(live, hasLength(2));
    expect(live.last.localDate, testToday);
    expect(live.last.kg, 97.4);
    expect(find.text('Weigh-in saved: 97.4 kg'), findsOneWidget);
    // Weighed in today: the slim row (D-084), whose ＋ logs again.
    expect(slimAdd(), findsOneWidget);

    // With an unusual value the in-sheet confirm is the third tap (the
    // digits typed on the pad are not counted).
    taps = 0;
    await tap(slimAdd());
    await pad(tester, '101');
    await tap(button('Save'));
    expect(find.textContaining("That's +3.6 kg"), findsOneWidget);
    // The confirmation's answers replace the pinned Save (past its 300 ms
    // double-tap guard).
    await tester.pump(const Duration(milliseconds: 350));
    await tap(button('Save 101.0 kg'));
    expect(taps, 3);
    live = await stored(tester, rig);
    expect(live.map((w) => w.kg), contains(101));
    await unmount(tester, rig);
  });

  testWidgets(
    'HM-005 the weight slide keeps its shape after logging and opens the graph',
    (tester) async {
      final rig = await todayWithWeighIn(tester);
      final height = tester.getSize(todayCard()).height;
      await tester.runAsync(
        () => rig.diary.apply([
          CreateWeighIn(fixtureId(501), weighInDraft(97, date: testToday)),
        ]),
      );
      await settle(tester);
      expect(tester.getSize(todayCard()).height, height);
      await tester.tap(
        find.descendant(of: todayCard(), matching: find.byType(InkWell)).first,
      );
      await settle(tester);
      expect(rig.navigator.pushed, [const TodayWeightGraphRoute()]);
      await tester.tap(slimAdd());
      await settle(tester);
      expect(find.byType(FbAmountDisplay), findsOneWidget);
      await unmount(tester, rig);
    },
  );
  testWidgets('HM-005 past weight slide logs on the viewed day', (
    tester,
  ) async {
    final rig = await todayWithWeighIn(tester);
    await tester.tap(find.byTooltip('Previous day'));
    await settle(tester);
    final add = find.descendant(
      of: find.byKey(ValueKey<LocalDate>(testYesterday)),
      matching: find.byKey(const ValueKey('today-weigh-in')),
    );
    await tester.tap(add);
    await settle(tester);
    await tester.tap(button('Save'));
    await settle(tester);
    final live = await stored(tester, rig);
    expect(live, hasLength(2));
    expect(live.every((w) => w.localDate == testYesterday), isTrue);
    await unmount(tester, rig);
  });
}
