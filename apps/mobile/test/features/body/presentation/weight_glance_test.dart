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
  testWidgets('HM-005 WB-011 A57 D3 weekly weigh-ins: the weight half shows '
      'the latest weigh-in as entered and its day, and opens the weigh-in '
      'sheet', (tester) async {
    final rig = SheetRig();
    await rig.seed(
      tester,
      weekly([29, 22, 15, 8, 1], [98, 97.5, 97, 96.5, 96.2]),
    );
    await pumpIn(tester, rig, WeightGlance(date: day17, isToday: true));
    final tile = tester.widget<FbGlanceTile>(find.byKey(_glance));
    expect(tile.icon, FbIcons.weight);
    expect(tile.text, '96.2 kg · yesterday');
    expect(tile.semanticLabel, contains('since the weigh-in before'));
    await tester.tap(find.byKey(_glance));
    await settle(tester);
    expect(find.byType(WeighInSheet), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('HM-005 WB-011 frequent weigh-ins: the weight half shows the '
      'trend and its weekly rate; Progress shows "last" next to it', (
    tester,
  ) async {
    final rig = SheetRig();
    await rig.seed(tester, [
      for (var ago = 20; ago >= 0; ago--)
        weighInDraft(98 - (20 - ago) * .1, date: day17.plusDays(-ago)),
    ]);
    await pumpIn(tester, rig, WeightGlance(date: day17, isToday: true));
    final tile = tester.widget<FbGlanceTile>(find.byKey(_glance));
    expect(tile.text, contains('kg/week'));
    expect(tile.text, isNot(contains('96.0')));
    expect(tile.semanticLabel, contains('last weigh-in 96.0 kilograms today'));
    await pumpIn(tester, rig, const WeightSection());
    expect(find.text('Trend weight'), findsOneWidget);
    expect(find.textContaining('last 96.0 kg · today · '), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('WB-011 weekly weigh-ins: Progress shows the latest as entered '
      'and the change since the one before', (tester) async {
    final rig = SheetRig();
    await rig.seed(tester, weekly([20, 10], [108.8, 107.7]));
    await pumpIn(tester, rig, const WeightSection());
    expect(find.text('107.7 kg'), findsOneWidget);
    expect(
      find.text('\u22121.1 kg since last weigh-in (10 days)'),
      findsOneWidget,
    );
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
