import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

class _Opener extends StatelessWidget {
  const new({required this.initial, required this.out});

  final TimeOfDay initial;
  final List<TimeOfDay?> out;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async =>
        out.add(await showFbTimePicker(context, initialTime: initial)),
    child: const Text('open'),
  );
}

void main() {
  testWidgets('D18 showFbTimePicker returns the time it opened on when '
      'confirmed', (tester) async {
    final out = <TimeOfDay?>[];
    await pumpFb(
      tester,
      _Opener(initial: const TimeOfDay(hour: 13, minute: 30), out: out),
      height: 900,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Select time'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(out.single, const TimeOfDay(hour: 13, minute: 30));
  });

  testWidgets('D18 showFbTimePicker returns null when cancelled', (
    tester,
  ) async {
    final out = <TimeOfDay?>[];
    await pumpFb(
      tester,
      _Opener(initial: const TimeOfDay(hour: 8, minute: 0), out: out),
      height: 900,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(out.single, isNull);
  });

  testWidgets('D18 showFbTimePicker is themed from the app theme', (
    tester,
  ) async {
    await pumpFb(
      tester,
      const _Opener(initial: TimeOfDay(hour: 8, minute: 0), out: []),
      height: 900,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(Dialog)));
    expect(
      theme.timePickerTheme.backgroundColor,
      theme.colorScheme.surfaceContainer,
    );
    expect(
      tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
      isNotNull,
    );
  });
}
