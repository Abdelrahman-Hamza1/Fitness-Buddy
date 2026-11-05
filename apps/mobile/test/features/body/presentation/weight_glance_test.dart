import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weight_tip_store.dart';
import 'package:fb_mobile/features/progress/presentation/weight_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/memory_tip_store.dart';
import '../support/weigh_in_sheet_support.dart';

/// [child] on a real in-memory profile ([rig]), with the suggestion state
/// in [tips].
Future<void> pumpIn(
  WidgetTester tester,
  SheetRig rig,
  Widget child, {
  MemoryTipStore? tips,
  List<Override> extra = const [],
}) async {
  tester.view
    ..physicalSize = const Size(360, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...rig.overrides,
        weightTipStoreProvider.overrideWithValue(tips ?? MemoryTipStore()),
        ...extra,
      ],
      child: phoneApp(Scaffold(body: ListView(children: [child]))),
    ),
  );
  await settle(tester);
}

const ValueKey<String> _glance = ValueKey('today-glance-weight');

/// Weekly weigh-ins on the days [daysAgo] before the 17th, with [kgs].
List<WeighInDraft> weekly(List<int> daysAgo, List<double> kgs) => [
  for (final (i, ago) in daysAgo.indexed)
    weighInDraft(kgs[i], date: day17.plusDays(-ago)),
];

// Covers: HM-005, WB-011, WB-012
void main() {
  testWidgets('HM-005 WB-011 A57 D3 the weight half shows the as-of trend and '
      'the weekly rate, and opens the weigh-in sheet', (tester) async {
    final rig = SheetRig();
    await rig.seed(
      tester,
      weekly([29, 22, 15, 8, 1], [98, 97.5, 97, 96.5, 96]),
    );
    await pumpIn(tester, rig, WeightGlance(date: day17, isToday: true));
    final tile = tester.widget<FbGlanceTile>(find.byKey(_glance));
    expect(tile.icon, FbIcons.weight);
    // The numbers are data: the trend and a weekly rate.
    expect(tile.text, contains('96.5'));
    expect(tile.text, contains('/'));
    await tester.tap(find.byKey(_glance));
    await settle(tester);
    expect(find.byType(WeighInSheet), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('HM-005 A57 D3 before any weigh-in the weight half invites one', (
    tester,
  ) async {
    final rig = SheetRig();
    await pumpIn(tester, rig, WeightGlance(date: day17, isToday: true));
    expect(tester.widget<FbGlanceTile>(find.byKey(_glance)).icon, FbIcons.add);
    await unmount(tester, rig);
  });

  testWidgets('WB-012 A57 T-T6 the weigh-in tip shows on Progress and is '
      'marked shown once', (tester) async {
    final rig = SheetRig();
    final tips = MemoryTipStore();
    await rig.seed(tester, weekly([21, 14, 7], [98, 97.5, 97]));
    await pumpIn(tester, rig, const WeightSection(), tips: tips);
    expect(find.byKey(const ValueKey('progress-weight-tip')), findsOneWidget);
    expect(tips.state.shownOn, day17);
    // Today's line never shows it.
    await pumpIn(
      tester,
      rig,
      WeightGlance(date: day17, isToday: true),
      tips: tips,
    );
    expect(find.byKey(const ValueKey('progress-weight-tip')), findsNothing);
    await unmount(tester, rig);
  });
}
