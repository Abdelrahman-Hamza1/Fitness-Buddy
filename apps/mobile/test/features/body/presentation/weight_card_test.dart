import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weight_tip_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/memory_tip_store.dart';
import '../support/weigh_in_sheet_support.dart';

const String minus = '−';

/// [date]'s weight card on a real in-memory profile ([rig]), with the
/// suggestion state in [tips].
Future<void> pumpCard(
  WidgetTester tester,
  SheetRig rig, {
  LocalDate? date,
  bool? isToday,
  MemoryTipStore? tips,
  List<Override> extra = const [],
}) async {
  tester.view
    ..physicalSize = const Size(360, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final day = date ?? day17;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...rig.overrides,
        weightTipStoreProvider.overrideWithValue(tips ?? MemoryTipStore()),
        ...extra,
      ],
      child: phoneApp(
        Scaffold(
          body: ListView(
            children: [WeightCard(date: day, isToday: isToday ?? day == day17)],
          ),
        ),
      ),
    ),
  );
  await settle(tester);
}

/// The card's texts, in order.
List<String> cardTexts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(of: find.byType(WeightCard), matching: find.byType(Text)),
  ))
    t.data ?? '',
];

/// Weekly weigh-ins on the days [daysAgo] before the 17th, with [kgs].
List<WeighInDraft> weekly(List<int> daysAgo, List<double> kgs) => [
  for (final (i, ago) in daysAgo.indexed)
    weighInDraft(kgs[i], date: day17.plusDays(-ago)),
];

void main() {
  testWidgets('HM-005 WB-011 the card shows the trend and weekly rate, and '
      'the latest raw weigh-in smaller', (tester) async {
    final rig = SheetRig();
    // Weekly, each moving the trend halfway (D1): 98 → 97.75 → 97.375 →
    // 96.9375 → 96.46875; rate (96.47 − 98) / 4 = −0.38 kg/week. The last
    // one yesterday: a day with a weigh-in shows the slim row (A45 D9).
    await rig.seed(
      tester,
      weekly([29, 22, 15, 8, 1], [98, 97.5, 97, 96.5, 96]),
    );
    await pumpCard(tester, rig);
    final texts = cardTexts(tester);
    // The trend is the title line, the rate its own line (m4).
    expect(texts.take(3), ['Weight', 'Trend 96.5 kg', '${minus}0.4 kg/week']);
    expect(texts, contains('Last weigh-in 96.0 kg · Yesterday'));
    final main = tester.widget<Text>(find.text('Trend 96.5 kg'));
    final rate = tester.widget<Text>(find.text('${minus}0.4 kg/week'));
    final last = tester.widget<Text>(
      find.text('Last weigh-in 96.0 kg · Yesterday'),
    );
    expect(rate.style!.fontSize, lessThan(main.style!.fontSize!));
    expect(last.style!.fontSize, lessThan(rate.style!.fontSize!));
    // Screen readers hear the units in full (m5).
    expect(
      find.bySemanticsLabel(
        'Weight trend 96.5 kilograms, ${minus}0.4 kilograms per week. 4 '
        'weigh-ins in 4 weeks · trend updates slowly. Log a weigh-in',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Last weigh-in 96.0 kilograms, Yesterday. Edit'),
      findsOneWidget,
    );
    await unmount(tester, rig);
  });

  testWidgets('WB-012 sparse weigh-ins show the honesty line; the suggestion '
      'appears at most once a month', (tester) async {
    final drafts = weekly([21, 14, 7], [98, 97.5, 97]);
    const line = '3 weigh-ins in 4 weeks · trend updates slowly';
    const tip = 'Weighing in 2–3 times a week makes the trend steadier.';

    final rig = SheetRig();
    final tips = MemoryTipStore();
    await rig.seed(tester, drafts);
    await pumpCard(tester, rig, tips: tips);
    expect(find.text(line), findsOneWidget);
    expect(find.text(tip), findsOneWidget);
    // Recorded after the frame that showed it.
    expect(tips.state, CadenceTipState(shownOn: day17));
    // It stays for the day until dismissed.
    await tester.tap(find.text('Got it'));
    await settle(tester);
    expect(find.text(tip), findsNothing);
    expect(find.text(line), findsOneWidget);
    expect(tips.state, CadenceTipState(shownOn: day17, dismissed: true));
    await unmount(tester, rig);

    for (final (shownDaysAgo, shows) in [(29, false), (30, true)]) {
      final again = SheetRig();
      final store = MemoryTipStore(
        CadenceTipState(
          shownOn: day17.plusDays(-shownDaysAgo),
          dismissed: true,
        ),
      );
      await again.seed(tester, drafts);
      await pumpCard(tester, again, tips: store);
      expect(
        find.text(tip),
        shows ? findsOneWidget : findsNothing,
        reason: 'shown $shownDaysAgo days ago',
      );
      expect(find.text(line), findsOneWidget);
      await unmount(tester, again);
    }

    // Frequent weigh-ins: no line, no suggestion, no preference read.
    final frequent = SheetRig();
    final untouched = MemoryTipStore();
    await frequent.seed(tester, [
      for (var i = 0; i < 8; i++)
        weighInDraft(97, date: day17.plusDays(-i * 3 - 1)),
    ]);
    await pumpCard(tester, frequent, tips: untouched);
    expect(find.textContaining('in 4 weeks'), findsNothing);
    expect(find.text(tip), findsNothing);
    expect(untouched.writes, 0);
    await unmount(tester, frequent);
  });

  testWidgets('HM-009 a past day shows the trend as of that day and logs to '
      'that day', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, weekly([14, 7, 0], [98, 97, 96]));
    final page = day17.plusDays(-10);
    await pumpCard(tester, rig, date: page);
    final texts = cardTexts(tester);
    // As of the 7th: only the weigh-in of the 3rd counts.
    expect(texts, contains('Trend 98.0 kg'));
    expect(texts, contains('Last weigh-in 98.0 kg · Sat, Oct 3'));
    expect(texts, isNot(contains(contains('in 4 weeks'))));

    await tester.tap(find.text('Trend 98.0 kg'));
    await settle(tester);
    expect(whenChip(tester), 'Wed, Oct 7, 3:00 PM');
    await typeOnPad(tester, '97.8');
    await tester.tap(button('Save'));
    await settle(tester);
    final stored = (await rig.live(tester)).where((w) => w.localDate == page);
    expect(stored.single.kg, 97.8);
    expect(find.text('Weigh-in saved: 97.8 kg for Wed, Oct 7'), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('the last weigh-in row opens it for editing', (tester) async {
    final rig = SheetRig();
    final yesterday = day17.plusDays(-1);
    await rig.seed(tester, [
      weighInDraft(97.2, date: yesterday, hour: 6),
      weighInDraft(97.8, date: yesterday, hour: 9),
    ]);
    await pumpCard(tester, rig);
    // The latest of the day, not the trend's choice (the earliest).
    expect(cardTexts(tester), contains('Trend 97.2 kg'));
    await tester.tap(find.text('Last weigh-in 97.8 kg · Yesterday'));
    await settle(tester);
    expect(find.text('Edit weigh-in'), findsOneWidget);
    expect(shownAmount(tester), '97.8');
    await unmount(tester, rig);
  });
}

/// The weigh-in sheet's "When" chip value.
String whenChip(WidgetTester tester) => tester
    .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, 'When'))
    .value!;
