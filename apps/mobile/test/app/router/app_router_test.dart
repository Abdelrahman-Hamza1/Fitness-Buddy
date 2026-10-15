import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

/// Every route, with the screen it shows and whether it is a tab.
///
/// The exhaustive `switch` makes this file fail to compile when a route is
/// added, so the new route gets a row here.
(Type screen, bool isTab) _expected(AppRoute route) => switch (route) {
  TodayRoute() => (TodayScreen, true),
  ProgressRoute() => (ProgressScreen, true),
  WorkoutsRoute() => (WorkoutsScreen, true),
  MeRoute() => (MeScreen, true),
  UpdateRequiredRoute() => (UpdateRequiredScreen, false),
};

const List<AppRoute> _allRoutes = [
  TodayRoute(),
  ProgressRoute(),
  WorkoutsRoute(),
  MeRoute(),
  UpdateRequiredRoute(),
];

void main() {
  test('typed routes: locations are unique and tabs are in UX-010 order', () {
    expect(_allRoutes.map((r) => r.location).toSet(), hasLength(5));
    expect(AppRouter.tabs.map((r) => r.location), [
      '/today',
      '/progress',
      '/workouts',
      '/me',
    ]);
    expect(
      [...AppRouter.tabs, ...AppRouter.outsideTabs].map((r) => r.location),
      unorderedEquals(_allRoutes.map((r) => r.location)),
    );
    expect(
      AppRouter.tabs.map((r) => r.location),
      _allRoutes.where((r) => _expected(r).$2).map((r) => r.location),
    );
  });

  testWidgets('typed routes: every AppRoute location is registered in the '
      'router', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);

    for (final route in _allRoutes) {
      final (screen, isTab) = _expected(route);
      showRoute(container, route);
      await tester.pumpAndSettle();

      expect(
        router.config.state.matchedLocation,
        route.location,
        reason: '$route',
      );
      expect(find.byType(screen), findsOneWidget, reason: '$route');
      expect(
        find.byType(NavigationBar),
        isTab ? findsOneWidget : findsNothing,
        reason: '$route',
      );
    }
  });

  test('update gate redirect: up sends every location to the update screen, '
      'down sends the update screen home', () {
    for (final route in _allRoutes) {
      final location = route.location;
      final isUpdate = route is UpdateRequiredRoute;
      expect(
        AppRouter.redirect(location, updateRequired: true),
        isUpdate ? isNull : UpdateRequiredRoute.path,
        reason: location,
      );
      expect(
        AppRouter.redirect(location, updateRequired: false),
        isUpdate ? TodayRoute.path : isNull,
        reason: location,
      );
    }
  });

  testWidgets('the update screen is not reachable while no update is needed', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).go(const UpdateRequiredRoute());
    await tester.pumpAndSettle();

    expect(find.byType(UpdateRequiredScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('an unknown location goes to Today', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider)..go(const MeRoute());
    await tester.pumpAndSettle();

    router.config.go('/no-such-screen');
    await tester.pumpAndSettle();

    expect(router.config.state.matchedLocation, TodayRoute.path);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
