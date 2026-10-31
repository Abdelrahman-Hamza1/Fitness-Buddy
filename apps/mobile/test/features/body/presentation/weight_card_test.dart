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

List<Override> _slideOverrides(
  SheetRig rig,
  MemoryTipStore? tips,
  List<Override> extra,
) => [
  ...rig.overrides,
  weightTipStoreProvider.overrideWithValue(tips ?? MemoryTipStore()),
  ...extra,
];

const String minus = '−';

/// [date]'s weight card on a real in-memory profile ([rig]), with the
/// suggestion state in [tips].
Future<void> pumpCard(
  WidgetTester tester,
  SheetRig rig, {
  LocalDate? date,
  bool? isToday,
  bool selected = true,
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
      overrides: [..._slideOverrides(rig, tips, extra)],
      child: phoneApp(
        Scaffold(
          body: ListView(
            children: [
              WeightSlide(
                date: day,
                isToday: isToday ?? day == day17,
                selected: selected,
              ),
            ],
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
    find.descendant(of: find.byType(WeightSlide), matching: find.byType(Text)),
  ))
    t.data ?? '',
];

/// Weekly weigh-ins on the days [daysAgo] before the 17th, with [kgs].
List<WeighInDraft> weekly(List<int> daysAgo, List<double> kgs) => [
  for (final (i, ago) in daysAgo.indexed)
    weighInDraft(kgs[i], date: day17.plusDays(-ago)),
];

// Covers: HM-005, WB-011, WB-012
void main() {
  testWidgets('HM-005 weight slide shows trend, last weigh-in and log button', (
    tester,
  ) async {
    final rig = SheetRig();
    await rig.seed(
      tester,
      weekly([29, 22, 15, 8, 1], [98, 97.5, 97, 96.5, 96]),
    );
    await pumpCard(tester, rig);
    expect(find.text('Trend 96.5 kg'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-weigh-in')), findsOneWidget);
    expect(find.byType(FbSparkline), findsOneWidget);
    await unmount(tester, rig);
  });
  testWidgets('WB-012 an unseen slide does not show or mark the monthly tip', (
    tester,
  ) async {
    final rig = SheetRig();
    final tips = MemoryTipStore();
    await rig.seed(tester, weekly([21, 14, 7], [98, 97.5, 97]));
    await pumpCard(tester, rig, tips: tips, selected: false);
    expect(tips.state, CadenceTipState.initial);
    await pumpCard(tester, rig, tips: tips);
    expect(tips.state.shownOn, day17);
    await unmount(tester, rig);
  });
}
