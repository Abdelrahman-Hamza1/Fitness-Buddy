import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/support/db_support.dart' show memoryDatabase;
import '../../../helpers/pump_app.dart';
import 'settings_support.dart';

Finder _sheet(String text) =>
    find.descendant(of: find.byType(FbSheet), matching: find.text(text));

Finder _rowOf(String title) => find.widgetWithText(FbListRow, title);

Finder _in(Finder of, String text) =>
    find.descendant(of: of, matching: find.text(text));

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).last)).brightness;

Future<T?> _stored<T>(
  WidgetTester tester,
  ProviderContainer container,
  SettingKey<T> key,
) => tester.runAsync(() => container.read(settingsStoreProvider).read(key));

void main() {
  testWidgets('LC-010 the Units sheet checks the current choice; Imperial '
      'sets it with Undo, and Undo restores Metric', (tester) async {
    final container = await pumpAt(tester);
    await openMe(tester);
    await tester.tap(_rowOf('Units'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(FbSheet),
        matching: find.byIcon(FbIcons.check),
      ),
      findsOneWidget,
    );

    await tester.tap(_sheet('Imperial'));
    await settleWrites(tester);
    expect(find.text('Units set to imperial'), findsOneWidget);
    expect(_in(_rowOf('Units'), 'Imperial'), findsOneWidget);
    expect(
      await _stored(tester, container, AppSettings.unitSystem),
      UnitSystem.imperial,
    );

    await tester.tap(find.text('Undo'));
    await settleWrites(tester);
    expect(_in(_rowOf('Units'), 'Metric'), findsOneWidget);
    expect(
      await _stored(tester, container, AppSettings.unitSystem),
      UnitSystem.metric,
    );
    await unmountApp(tester, container);
  });

  testWidgets('FD-080 LC-040 Halal switch on by default; turning it off '
      'shows Undo', (tester) async {
    final container = await pumpAt(tester);
    await openMe(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.text('Halal food'));
    await settleWrites(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Halal food turned off'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(await _stored(tester, container, AppSettings.halal), isFalse);

    await tester.tap(find.text('Undo'));
    await settleWrites(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(await _stored(tester, container, AppSettings.halal), isTrue);
    await unmountApp(tester, container);
  });

  testWidgets('UX-040 #75 D-083 Theme sheet: a fresh install is light; Dark '
      'switches the app to dark at once; the choice survives a restart (new '
      'ProviderScope over the same DB); Undo restores the previous choice', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    final phone = TestPhone();
    final db = memoryDatabase();
    final container = await pumpAt(
      tester,
      phone: phone,
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    await openMe(tester);
    // The default (D-083), though the test platform is dark.
    expect(_brightness(tester), Brightness.light);
    expect(_in(_rowOf('Theme'), 'Light'), findsOneWidget);

    await tester.tap(_rowOf('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(_sheet('Dark'));
    await settleWrites(tester);
    expect(_brightness(tester), Brightness.dark);
    expect(find.text('Theme set to Dark'), findsOneWidget);
    expect(_in(_rowOf('Theme'), 'Dark'), findsOneWidget);

    // A restart: a new container over the same database opens dark.
    await unmountApp(tester, container);
    container.dispose();
    final restarted = await pumpAt(
      tester,
      phone: phone,
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    expect(_brightness(tester), Brightness.dark);
    // The first stored value applies without the theme animation (D6).
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeAnimationDuration,
      Duration.zero,
    );

    await openMe(tester);
    await tester.tap(_rowOf('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(_sheet('Light'));
    await settleWrites(tester);
    expect(_brightness(tester), Brightness.light);
    // Later changes animate.
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeAnimationDuration,
      kThemeAnimationDuration,
    );
    await tester.tap(find.text('Undo'));
    await settleWrites(tester);
    expect(_brightness(tester), Brightness.dark);
    expect(
      await _stored(tester, restarted, AppSettings.theme),
      ThemePreference.dark,
    );
    await unmountApp(tester, restarted);
  });
}
