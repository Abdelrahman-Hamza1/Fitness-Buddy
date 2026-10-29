import 'dart:io';

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

  testWidgets('SF-040 the licences page shows the brand mark as the '
      'application icon', (tester) async {
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
    expect(
      find.descendant(
        of: find.byType(LicensePage),
        matching: find.byType(FbBrandMark),
      ),
      findsWidgets,
    );
  });

  test('SF-040 the licence registry lists Inter, Noto Sans Arabic and Nunito '
      'with their OFL text', () {
    expect([
      for (final (name, _) in fbFontLicenses) name,
    ], unorderedEquals(['Inter', 'Noto Sans Arabic', 'Nunito']));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final (_, file) in fbFontLicenses) {
      final text = File('assets/fonts/$file').readAsStringSync();
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'), reason: file);
      // Declared as an asset, so the licence page can load it.
      expect(pubspec, contains('- assets/fonts/$file'), reason: file);
    }
  });
}
