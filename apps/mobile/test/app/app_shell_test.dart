import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/theme/app_theme.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

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
    "UX-010 tapping a tab shows its placeholder and keeps the other branches' "
    'state',
    (tester) async {
      await pumpApp(tester);
      final todayElement = tester.element(find.byType(TodayScreen));

      final tabs = {
        'Progress': (1, ProgressScreen, 'Charts appear after'),
        'Workouts': (2, WorkoutsScreen, 'Your workouts will'),
        'Me': (3, MeScreen, 'Your profile and settings'),
        'Today': (0, TodayScreen, 'Search for a food'),
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

  testWidgets('UX-040 theme follows the system brightness (light and dark)', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    Brightness shown() =>
        Theme.of(tester.element(find.byType(TodayScreen))).brightness;

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await pumpApp(tester);
    expect(shown(), Brightness.dark);
    expect(
      Theme.of(tester.element(find.byType(TodayScreen))).colorScheme,
      AppTheme.dark.colorScheme,
    );

    // The system switches to light while the app runs.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(shown(), Brightness.light);
    expect(
      Theme.of(tester.element(find.byType(TodayScreen))).colorScheme,
      AppTheme.light.colorScheme,
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(find.byType(FitnessBuddyApp), findsOneWidget);
  });
}
