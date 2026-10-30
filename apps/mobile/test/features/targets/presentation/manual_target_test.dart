import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/targets/presentation/below_limit_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'targets_screens_support.dart';

/// The version in effect today.
Future<TargetSettingsRecord> _current(TargetsScreenRig rig) async {
  final data = await rig.data();
  return TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], rig.today)!;
}

/// Opens Targets › Set my own target and applies [kcal].
Future<TargetsScreenRig> _enter(WidgetTester tester, String kcal) async {
  final rig = await TargetsScreenRig.open(tester, route: const TargetsRoute());
  await rig.tap('Set my own target');
  await tester.enterText(find.widgetWithText(TextField, 'Daily target'), kcal);
  await tester.pumpAndSettle();
  await rig.tapAndSettle('Use this target');
  return rig;
}

void main() {
  testWidgets('SF-012 a manual target below the floor opens the warning '
      'screen; Use stays disabled until the box is checked; applying sets a '
      'fixed manual target', (tester) async {
    final rig = await _enter(tester, '1000');
    expect(find.byType(BelowLimitScreen), findsOneWidget);
    expect(
      find.textContaining('below your safety floor of 1,750'),
      findsOneWidget,
    );
    final use = find.widgetWithText(FbButton, 'Use 1,000 kcal');
    expect(tester.widget<FbButton>(use).onPressed, isNull);

    await rig.tap('I understand and want to use 1,000 kcal a day');
    expect(tester.widget<FbButton>(use).onPressed, isNotNull);
    await rig.tapAndSettle('Use 1,000 kcal');

    final version = await _current(rig);
    expect(version.manual, isTrue);
    expect(version.acknowledged, isTrue);
    expect(version.mode, TargetMode.fixed);
    expect(version.baseKcal, 1000);
    expect(find.byType(BelowLimitScreen), findsNothing);
    expect(find.text('Targets updated'), findsOneWidget);
    await rig.close();
  });

  testWidgets('SF-011 a manual target implying more than 1%/week loss shows '
      'the warning with the implied rate', (tester) async {
    final rig = await _enter(tester, '1800');
    expect(find.byType(BelowLimitScreen), findsOneWidget);
    expect(
      find.textContaining('means losing about 0.83 kg a week'),
      findsOneWidget,
    );
    await rig.close();
  });

  testWidgets('SF-012 Go back writes nothing and keeps the number', (
    tester,
  ) async {
    final rig = await _enter(tester, '1000');
    final before = await _current(rig);
    await rig.tapAndSettle('Go back');
    expect(find.byType(BelowLimitScreen), findsNothing);
    // Back on the sheet with the number as typed (UX-052).
    expect(find.widgetWithText(TextField, '1000'), findsOneWidget);
    final after = await _current(rig);
    expect(after.id, before.id);
    expect(after.manual, isFalse);
    expect((await rig.data()).settings, hasLength(1));
    await rig.close();
  });

  testWidgets('SF-012 a manual target within the limits applies directly '
      'with undo', (tester) async {
    final rig = await _enter(tester, '2000');
    expect(find.byType(BelowLimitScreen), findsNothing);
    final version = await _current(rig);
    expect(version.manual, isTrue);
    expect(version.acknowledged, isFalse);
    expect(version.mode, TargetMode.weekly);
    expect(find.text('Targets updated'), findsOneWidget);
    expect(find.text('Use the calculated target'), findsOneWidget);

    await rig.tapAndSettle('Undo');
    expect((await _current(rig)).manual, isFalse);
    await rig.close();
  });
}
