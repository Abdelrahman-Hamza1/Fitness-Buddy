import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('SF-040 showFbLicensePage: shows the app name and version', (
    tester,
  ) async {
    await pumpFb(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showFbLicensePage(
            context,
            applicationName: 'Fitness Buddy',
            applicationVersion: '0.1.0',
          ),
          child: const Text('licences'),
        ),
      ),
    );
    await tester.tap(find.text('licences'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('Fitness Buddy'), findsWidgets);
    expect(find.text('0.1.0'), findsWidgets);
  });
}
