import 'dart:async';

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
    // 96.9375 → 96.46875; rate (96.47 − 98) / 4 = −0.38 kg/week.
    await rig.seed(
      tester,
      weekly([28, 21, 14, 7, 0], [98, 97.5, 97, 96.5, 96]),
    );
    await pumpCard(tester, rig);
    final texts = cardTexts(tester);
    // The trend is the title line, the rate its own line (m4).
    expect(texts.take(3), ['Weight', 'Trend 96.5 kg', '${minus}0.4 kg/week']);
    expect(texts, contains('Last weigh-in 96.0 kg · Today'));
    final main = tester.widget<Text>(find.text('Trend 96.5 kg'));
    final rate = tester.widget<Text>(find.text('${minus}0.4 kg/week'));
    final last = tester.widget<Text>(
      find.text('Last weigh-in 96.0 kg · Today'),
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
      find.bySemanticsLabel('Last weigh-in 96.0 kilograms, Today. Edit'),
      findsOneWidget,
    );
    await unmount(tester, rig);
  });

  testWidgets('UX-050 with no weigh-ins the card invites the first one', (
    tester,
  ) async {
    final rig = SheetRig();
    await pumpCard(tester, rig);
    expect(cardTexts(tester), ['Weight', 'Log your first weigh-in']);
    expect(find.byIcon(FbIcons.edit), findsNothing);
    expect(
      find.bySemanticsLabel('Weight. Log your first weigh-in'),
      findsOneWidget,
    );

    // Row 1 opens the log sheet.
    await tester.tap(find.text('Log your first weigh-in'));
    await settle(tester);
    expect(find.text('Log weigh-in'), findsOneWidget);
    expect(whenChip(tester), 'Today, 3:00 PM');
    await unmount(tester, rig);
  });

  testWidgets('WB-011 with one weigh-in the card says the rate comes after 2 '
      'weeks', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [weighInDraft(97.4, date: day17.plusDays(-1))]);
    await pumpCard(tester, rig);
    final texts = cardTexts(tester);
    expect(texts, contains('Trend 97.4 kg'));
    expect(texts, contains('Weekly rate after 2 weeks of weigh-ins'));
    expect(texts, contains('Last weigh-in 97.4 kg · Yesterday'));
    // M2: no cadence line and no suggestion until the rate is there.
    expect(find.textContaining('weigh-ins in 4 weeks'), findsNothing);
    expect(find.textContaining('weigh-in in 4 weeks'), findsNothing);
    expect(find.textContaining('Weighing in'), findsNothing);
    expect(
      find.bySemanticsLabel(
        'Weight trend 97.4 kilograms. Weekly rate after 2 weeks of '
        'weigh-ins. Log a weigh-in',
      ),
      findsOneWidget,
    );
    await unmount(tester, rig);

    // Still under 2 weeks of history (13 days): the same.
    final young = SheetRig();
    final tips = MemoryTipStore();
    await young.seed(tester, weekly([13, 6], [97.4, 97.2]));
    await pumpCard(tester, young, tips: tips);
    expect(
      cardTexts(tester),
      contains('Weekly rate after 2 weeks of weigh-ins'),
    );
    expect(find.textContaining('in 4 weeks'), findsNothing);
    expect(find.textContaining('Weighing in'), findsNothing);
    expect(tips.writes, 0);
    await unmount(tester, young);
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
        weighInDraft(97, date: day17.plusDays(-i * 3)),
    ]);
    await pumpCard(tester, frequent, tips: untouched);
    expect(find.textContaining('in 4 weeks'), findsNothing);
    expect(find.text(tip), findsNothing);
    expect(untouched.writes, 0);
    await unmount(tester, frequent);
  });

  testWidgets('LC-010 the imperial setting shows lb for the trend, rate and '
      'last weigh-in', (tester) async {
    final rig = SheetRig()..units.value = UnitSystem.imperial;
    await rig.seed(
      tester,
      weekly([28, 21, 14, 7, 0], [98, 97.5, 97, 96.5, 96]),
    );
    await pumpCard(tester, rig);
    final texts = cardTexts(tester);
    // 96.46875 kg = 212.7 lb; −0.3828 kg/week = −0.8 lb/week.
    expect(texts, containsAll(['Trend 212.7 lb', '${minus}0.8 lb/week']));
    expect(texts, contains('Last weigh-in 211.6 lb · Today'));
    expect(
      find.bySemanticsLabel(
        'Weight trend 212.7 pounds, ${minus}0.8 pounds per week. 4 '
        'weigh-ins in 4 weeks · trend updates slowly. Log a weigh-in',
      ),
      findsOneWidget,
    );
    await unmount(tester, rig);
  });

  testWidgets('UX-051 loading shows a skeleton; an error shows Try again', (
    tester,
  ) async {
    final rig = SheetRig();
    final pending = StreamController<List<WeighIn>>();
    addTearDown(pending.close);
    await pumpCard(
      tester,
      rig,
      extra: [weighInsProvider.overrideWith((ref) => pending.stream)],
    );
    expect(find.byType(FbSkeleton), findsOneWidget);
    pending.add(const []);
    await settle(tester);
    expect(find.byType(FbSkeleton), findsNothing);
    await unmount(tester, rig);

    final failing = SheetRig();
    var fail = true;
    await pumpCard(
      tester,
      failing,
      extra: [
        weighInsProvider.overrideWith(
          (ref) => fail
              ? Stream<List<WeighIn>>.error(StateError('read'))
              : Stream.value(const <WeighIn>[]),
        ),
      ],
    );
    expect(find.text("Couldn't load your weigh-ins."), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('Log your first weigh-in'), findsOne);
    await unmount(tester, failing);
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

  testWidgets("WB-012 the honesty line and suggestion show on today's page "
      'only', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, weekly([21, 14, 7], [98, 97.5, 97]));
    // The same day, not as today's page.
    await pumpCard(tester, rig, isToday: false);
    expect(find.textContaining('in 4 weeks'), findsNothing);
    expect(find.textContaining('Weighing in'), findsNothing);
    expect(cardTexts(tester), contains(startsWith('Trend ')));
    await unmount(tester, rig);
  });

  testWidgets('WB-012 with no weigh-ins in the last 4 weeks the card shows no '
      'weekly rate', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, weekly([40, 33], [98, 97]));
    await pumpCard(tester, rig);
    final texts = cardTexts(tester);
    expect(texts, contains('Trend 97.5 kg · from Mon, Sep 14'));
    expect(texts.any((t) => t.contains('/week')), isFalse);
    expect(texts.any((t) => t.contains('Weekly rate')), isFalse);
    // n4: the date shows once, on the trend row; no extra honesty line.
    expect(texts, contains('Last weigh-in 97.0 kg'));
    expect(texts.where((t) => t.contains('Sep 14')), hasLength(1));
    // Row 3 opens the weight graph (A15a D12).
    expect(texts, hasLength(4));
    expect(texts.last, 'Weight graph');
    await unmount(tester, rig);

    // Exactly 28 days since the last weigh-in: outside the last 4 weeks.
    final edge = SheetRig();
    await edge.seed(tester, weekly([42, 35, 28], [98, 97.5, 97]));
    await pumpCard(tester, edge);
    final edgeTexts = cardTexts(tester);
    expect(edgeTexts, contains(startsWith('Trend ')));
    expect(edgeTexts.first, 'Weight');
    expect(edgeTexts[1], contains(' · from '));
    expect(edgeTexts.any((t) => t.contains('/week')), isFalse);
    await unmount(tester, edge);
  });

  testWidgets('M3 a past day before the first weigh-in invites one for that '
      'day, not the first one', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, weekly([7, 0], [98, 97]));
    await pumpCard(tester, rig, date: day17.plusDays(-10));
    // The graph row shows on every day page once there are weigh-ins
    // (A15a D12).
    expect(cardTexts(tester), [
      'Weight',
      'No weigh-ins by this day. Tap to add one.',
      'Weight graph',
    ]);
    expect(
      find.bySemanticsLabel(
        'Weight. No weigh-ins by this day. Tap to add one.',
      ),
      findsOneWidget,
    );
    await unmount(tester, rig);
  });

  testWidgets('security: a weigh-in with kg 1e306 does not break the card', (
    tester,
  ) async {
    final rig = SheetRig();
    final absurd = WeighIn(
      id: fixtureId(1),
      version: 1,
      time: weighInDraft(1, hour: 6).time,
      localDate: day17,
      kg: 1e306,
      input: const WeighInInput(1e306, MassUnit.kilogram),
    );
    final fine = storedWeighIn(2, weighInDraft(97.4, date: day17.plusDays(-1)));
    await pumpCard(
      tester,
      rig,
      extra: [
        weighInsProvider.overrideWith((ref) => Stream.value([fine, absurd])),
      ],
    );
    expect(tester.takeException(), isNull);
    final texts = cardTexts(tester);
    expect(texts, contains('Trend 97.4 kg'));
    expect(texts, contains('Last weigh-in 97.4 kg · Yesterday'));
    await unmount(tester, rig);

    // Only absurd rows: the card is empty, as without weigh-ins.
    final only = SheetRig();
    await pumpCard(
      tester,
      only,
      extra: [
        weighInsProvider.overrideWith((ref) => Stream.value([absurd])),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(cardTexts(tester), ['Weight', 'Log your first weigh-in']);
    await unmount(tester, only);
  });

  testWidgets('the last weigh-in row opens it for editing', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, [
      weighInDraft(97.2, hour: 6),
      weighInDraft(97.8, hour: 9),
    ]);
    await pumpCard(tester, rig);
    // The latest of the day, not the trend's choice (the earliest).
    expect(cardTexts(tester), contains('Trend 97.2 kg'));
    await tester.tap(find.text('Last weigh-in 97.8 kg · Today'));
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
