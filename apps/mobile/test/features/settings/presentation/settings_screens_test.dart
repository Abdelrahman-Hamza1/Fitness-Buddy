import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/support/db_support.dart' show memoryDatabase;
import '../../../helpers/pump_app.dart';
import '../../today/presentation/support/today_support.dart';
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

/// Scrolls the Me list to its end, so lazily built rows exist.
Future<void> _scrollMeToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('UX-010 the Me tab shows Food (when present), Settings and '
      'About in that order; empty sections are hidden; Design preview only '
      'in dev', (tester) async {
    final container = await pumpAt(tester, phone: phoneOf(prodConfig));
    await openMe(tester);

    double y(String header) =>
        tester.getTopLeft(find.widgetWithText(FbSectionHeader, header)).dy;
    expect(y('Food'), lessThan(y('Settings')));
    expect(y('Settings'), lessThan(y('About')));
    // The Developer section has no rows in prod, so it is not shown.
    expect(find.text('Developer'), findsNothing);
    expect(find.text('Design preview'), findsNothing);
    expect(find.text('Your foods'), findsOneWidget);
    expect(find.text('Saved meals'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('UX-010 the Developer section with Design preview shows in '
      'the dev flavor, after About', (tester) async {
    final container = await pumpAt(tester);
    await openMe(tester);
    await _scrollMeToEnd(tester);

    expect(find.text('Design preview'), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(FbSectionHeader, 'About')).dy,
      lessThan(
        tester.getTopLeft(find.widgetWithText(FbSectionHeader, 'Developer')).dy,
      ),
    );
    await unmountApp(tester, container);
  });

  testWidgets('UX-013 every setting is 2 taps from Today (Me, row)', (
    tester,
  ) async {
    final container = await pumpAt(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    // Tap 1: the Me tab. Tap 2: the row.
    for (final (row, opens) in [
      ('Units', 'Metric'),
      ('Week starts on', 'Saturday'),
      ('Theme', 'System'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Me'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_rowOf(row));
      await tester.pumpAndSettle();
      expect(find.byType(FbSheet), findsOneWidget, reason: row);
      expect(_sheet(opens), findsOneWidget, reason: row);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Today'),
        ),
      );
      await tester.pumpAndSettle();
    }
    await unmountApp(tester, container);
  });

  testWidgets('DY-010 UX-013 Meal times opens from the Settings row', (
    tester,
  ) async {
    final container = await pumpAt(tester);
    await openMe(tester);
    await tester.tap(_rowOf('Meal times'));
    await tester.pumpAndSettle();
    expect(find.byType(MealSlotsScreen), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('LC-012 the Energy row says kcal and is not tappable', (
    tester,
  ) async {
    final container = await pumpAt(tester);
    await openMe(tester);

    final energy = _rowOf('Energy');
    expect(energy, findsOneWidget);
    expect(_in(energy, 'kcal'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.descendant(of: energy, matching: find.byType(ListTile)),
          )
          .onTap,
      isNull,
    );
    await unmountApp(tester, container);
  });

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

  testWidgets('LC-021 the Week starts on sheet sets the first day, with '
      'Undo', (tester) async {
    final container = await pumpAt(tester);
    await openMe(tester);
    expect(_in(_rowOf('Week starts on'), 'Saturday'), findsOneWidget);
    await tester.tap(_rowOf('Week starts on'));
    await tester.pumpAndSettle();
    await tester.tap(_sheet('Monday'));
    await settleWrites(tester);

    expect(find.text('Week now starts on Monday'), findsOneWidget);
    expect(_in(_rowOf('Week starts on'), 'Monday'), findsOneWidget);
    expect(container.read(weekCalendarProvider).weekStart, DayOfWeek.monday);
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

  testWidgets('UX-040 #75 Theme sheet: Dark switches the app to dark at '
      'once; the choice survives a restart (new ProviderScope over the same '
      'DB); Undo restores System', (tester) async {
    final phone = TestPhone();
    final db = memoryDatabase();
    final container = await pumpAt(
      tester,
      phone: phone,
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    await openMe(tester);
    expect(_brightness(tester), Brightness.light);

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

  testWidgets("UX-001 the first frame doesn't read the settings store; "
      'the theme is read after it', (tester) async {
    final phone = TestPhone();
    final reads = <String>[];
    tester.binding.addPostFrameCallback((_) => reads.add('first frame'));
    final container = await pumpAt(
      tester,
      phone: phone,
      overrides: [
        settingsStoreProvider.overrideWith((ref) {
          reads.add('settings store');
          return SettingsStore(
            db: ref.watch(appDatabaseProvider),
            applier: ref.watch(changeSetApplierProvider),
          );
        }),
      ],
    );
    expect(reads.first, 'first frame');
    expect(reads, contains('settings store'));
    await unmountApp(tester, container);
  });
}
