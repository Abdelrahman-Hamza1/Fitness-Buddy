import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

class _Opener extends StatelessWidget {
  const new({required this.initial, required this.last, required this.out});

  final DateTime initial;
  final DateTime last;
  final List<DateTime?> out;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async => out.add(
      await showFbDatePicker(context, initialDate: initial, lastDate: last),
    ),
    child: const Text('open'),
  );
}

void main() {
  final last = DateTime(2026, 10, 20);

  testWidgets('HM-009 DY-003 showFbDatePicker: no date after lastDate can be '
      'picked', (tester) async {
    final out = <DateTime?>[];
    await pumpFb(
      tester,
      _Opener(initial: DateTime(2026, 10, 15), last: last, out: out),
      height: 900,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 21 is after lastDate: a tap changes nothing.
    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(out, [DateTime(2026, 10, 15)]);
  });
}
