import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/targets.dart';
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

void main() {
  testWidgets('TG-043 the sheet submits only the changed weekdays; an '
      'untouched synced weight (1.8) stays exact', (tester) async {
    final rig = await TargetsScreenRig.open(tester);
    final row = (await rig.data()).settings.single;
    await rig.run(
      (a) => a.setShifting(VersionedId(row.value.id, row.version), {
        DayOfWeek.friday: 1.8,
      }),
    );
    await rig.show(const TargetsRoute());
    await rig.tap('Higher-calorie days');
    // Sunday is the 2nd day of a Saturday week: its row's "More" chip.
    await tester.tap(find.widgetWithText(FbChoiceChip, 'More').at(1));
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Save');

    expect((await _current(rig)).shifts, {
      DayOfWeek.friday: 1.8,
      DayOfWeek.sunday: 1.3,
    });
    await rig.close();
  });

  testWidgets('TG-054 protein 140 g, fat 25 % and fiber 30 g save', (
    tester,
  ) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await rig.tap('Macro targets');
    final grams = find.widgetWithText(FbChoiceChip, 'Grams');
    await tester.tap(grams.first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Protein'), '140');
    await tester.tap(find.widgetWithText(FbChoiceChip, '% of calories').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Fat'), '25');
    await tester.ensureVisible(grams.last);
    await tester.tap(grams.last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Fiber'), '30');
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Save');

    final macros = (await _current(rig)).macros;
    expect(macros.protein?.value, 140);
    expect(macros.protein?.isPercent, isFalse);
    expect(macros.fat?.value, 25);
    expect(macros.fat?.isPercent, isTrue);
    expect(macros.fiberGrams, 30);
    expect(find.text('Your own settings'), findsOneWidget);
    await rig.close();
  });

  testWidgets('D5 Recalculate with your current weight writes a new '
      'generated target with undo', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      overrides: [
        bodyWeightProvider.overrideWith((ref, date) async => 78),
        bodyWeightReaderProvider.overrideWithValue((date) async => 78),
      ],
    );
    await rig.show(const TargetsRoute());
    expect(
      find.text(
        'Your target was worked out at 80 kg. Your current '
        'weight is 78 kg.',
      ),
      findsOneWidget,
    );
    await rig.tapAndSettle('Recalculate with your current weight');

    final version = await _current(rig);
    expect(version.basisWeightKg, 78);
    expect(version.manual, isFalse);
    expect(find.text('Targets updated'), findsOneWidget);
    expect(find.text('Recalculate with your current weight'), findsNothing);
    await rig.close();
  });
}
