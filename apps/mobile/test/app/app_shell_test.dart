import 'package:fb_mobile/app/theme/app_theme.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Brightness _shown(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(TodayScreen))).brightness;

Override _stored(ThemePreference theme) =>
    themePreferenceProvider.overrideWith((ref) => Stream.value(theme));

void main() {
  testWidgets(
    'UX-010 shell shows the four tabs Today, Progress, Workouts, Me',
    (tester) async {
      await pumpApp(tester);

      final destinations = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((d) => d.label);
      expect(destinations, ['Today', 'Progress', 'Workouts', 'Me']);
      // Today is home.
      expect(_selectedTab(tester), 0);
      expect(find.byType(TodayScreen), findsOneWidget);
    },
  );

  testWidgets(
    "UX-010 tapping a tab shows its content and keeps the other branches' "
    'state',
    (tester) async {
      await pumpApp(tester);
      final todayElement = tester.element(find.byType(TodayScreen));

      final tabs = {
        'Progress': (1, ProgressScreen, 'Charts appear after'),
        'Workouts': (2, WorkoutsScreen, 'Your workouts will'),
        'Me': (3, MeScreen, 'Your foods'),
        'Today': (0, TodayScreen, 'Tell Buddy what you ate'),
      };
      for (final MapEntry(key: label, value: (index, screen, text))
          in tabs.entries) {
        await tester.tap(_tab(label));
        await tester.pumpAndSettle();

        expect(_selectedTab(tester), index, reason: label);
        expect(find.byType(screen), findsOneWidget, reason: label);
        expect(find.textContaining(text), findsOneWidget, reason: label);
        // The other branches stay mounted offstage (indexedStack), so their
        // state survives the switch.
        expect(
          find.byType(TodayScreen, skipOffstage: false),
          findsOneWidget,
          reason: label,
        );
      }

      // Back on Today: the very same element, not a rebuilt screen.
      expect(tester.element(find.byType(TodayScreen)), same(todayElement));
    },
  );

  testWidgets('UX-010 the AppNavigator port switches tabs', (tester) async {
    final container = await pumpApp(tester);

    container.read(appNavigatorProvider).go(const WorkoutsRoute());
    await tester.pumpAndSettle();

    expect(_selectedTab(tester), 2);
    expect(find.byType(WorkoutsScreen), findsOneWidget);
  });

  testWidgets('UX-040 a fresh install opens in dark, even when the system is '
      'light', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await pumpApp(tester);
    expect(_shown(tester), Brightness.dark);
    expect(
      Theme.of(tester.element(find.byType(TodayScreen))).colorScheme,
      AppTheme.dark.colorScheme,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('UX-040 with System chosen, the app follows the system '
      'brightness live', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await pumpApp(tester, overrides: [_stored(ThemePreference.system)]);
    expect(_shown(tester), Brightness.dark);

    // The system switches to light while the app runs.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(_shown(tester), Brightness.light);
    expect(
      Theme.of(tester.element(find.byType(TodayScreen))).colorScheme,
      AppTheme.light.colorScheme,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets('UX-001 UX-040 the first frame is dark and reads no storage; a '
      'stored Light applies after it without animation', (tester) async {
    final read = <String>[];
    await tester.pumpWidget(
      testApp(
        overrides: [
          themePreferenceProvider.overrideWith((ref) {
            read.add('theme');
            return Stream.value(ThemePreference.light);
          }),
        ],
      ),
    );
    // Frame 1: the default, and the setting is not read yet.
    expect(read, isEmpty);
    final first = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(first.themeMode, ThemeMode.dark);
    expect(first.themeAnimationDuration, Duration.zero);

    await tester.pumpAndSettle();
    expect(read, ['theme']);
    final settled = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(settled.themeMode, ThemeMode.light);
    expect(settled.themeAnimationDuration, Duration.zero);
    await unmountApp(tester);
  });

  testWidgets('UX-040 status and navigation bar icons contrast with the theme '
      '(light icons on dark, dark on light); the navigation bar is opaque in '
      "the theme's bottom-bar colour", (tester) async {
    SystemUiOverlayStyle bars() => tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .first
        .value;

    final container = await pumpApp(tester);
    expect(_shown(tester), Brightness.dark);
    expect(bars().statusBarIconBrightness, Brightness.light);
    expect(bars().systemNavigationBarIconBrightness, Brightness.light);
    expect(bars().statusBarColor, const Color(0x00000000));
    expect(
      bars().systemNavigationBarColor,
      AppTheme.dark.colorScheme.surfaceContainer,
    );
    expect(bars().systemNavigationBarColor!.a, 1);

    await container
        .read(settingsActionsProvider)
        .setTheme(ThemePreference.light);
    await settleWrites(tester);
    expect(_shown(tester), Brightness.light);
    expect(bars().statusBarIconBrightness, Brightness.dark);
    expect(bars().systemNavigationBarIconBrightness, Brightness.dark);
    expect(
      bars().systemNavigationBarColor,
      AppTheme.light.colorScheme.surfaceContainer,
    );
    await unmountApp(tester, container);
  });
}
