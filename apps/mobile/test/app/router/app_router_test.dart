import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/design_preview/design_preview.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/foods/presentation/support/search_screen_support.dart';
import '../../helpers/pump_app.dart';

/// Every route, with the screen it shows and whether the tab bar is shown
/// (the tabs and the screens nested in them).
///
/// The exhaustive `switch` makes this file fail to compile when a route is
/// added, so the new route gets a row here.
(Type screen, bool hasTabBar) _expected(AppRoute route) => switch (route) {
  TodayRoute() => (TodayScreen, true),
  ProgressRoute() => (ProgressScreen, true),
  WorkoutsRoute() => (WorkoutsScreen, true),
  MeRoute() => (MeScreen, true),
  DesignPreviewRoute() => (DesignPreviewScreen, true),
  FoodSearchRoute() => (FoodSearchScreen, true),
  UpdateRequiredRoute() => (UpdateRequiredScreen, false),
};

const List<AppRoute> _allRoutes = [
  TodayRoute(),
  ProgressRoute(),
  WorkoutsRoute(),
  MeRoute(),
  DesignPreviewRoute(),
  FoodSearchRoute(),
  UpdateRequiredRoute(),
];

void main() {
  test('typed routes: locations are unique and tabs are in UX-010 order', () {
    expect(_allRoutes.map((r) => r.location).toSet(), hasLength(7));
    expect(AppRouter.tabs.map((r) => r.location), [
      '/today',
      '/progress',
      '/workouts',
      '/me',
    ]);
    expect(
      [
        ...AppRouter.tabs,
        ...AppRouter.outsideTabs,
        const DesignPreviewRoute(),
        const FoodSearchRoute(),
      ].map((r) => r.location),
      unorderedEquals(_allRoutes.map((r) => r.location)),
    );
  });

  testWidgets('typed routes: every AppRoute location is registered in the '
      'router', (tester) async {
    final container = await pumpApp(
      tester,
      overrides: [searchOverride(FakeFoodSearch())],
    );
    final router = container.read(appRouterProvider);

    for (final route in _allRoutes) {
      final (screen, hasTabBar) = _expected(route);
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
        hasTabBar ? findsOneWidget : findsNothing,
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

  test('A07 D11 the add-food route carries its parameters in the query', () {
    expect(const FoodSearchRoute().location, '/today/add-food');
    expect(
      FoodSearchRoute(date: LocalDate(2026, 10, 20), slotId: 'slot 1').location,
      '/today/add-food?date=2026-10-20&slot=slot+1',
    );
    expect(
      const FoodSearchRoute(slotId: 'lunch').location,
      '/today/add-food?slot=lunch',
    );
  });

  test('A07 D11 the router rebuilds the add-food route from its location, '
      'ignoring bad parameters', () {
    final route = AppRouter.foodSearchRouteOf(
      Uri.parse(
        FoodSearchRoute(
          date: LocalDate(2026, 10, 20),
          slotId: 'slot 1',
        ).location,
      ),
    );
    expect(route.date, LocalDate(2026, 10, 20));
    expect(route.slotId, 'slot 1');

    final bad = AppRouter.foodSearchRouteOf(
      Uri.parse('/today/add-food?date=20-10-2026&slot='),
    );
    expect(bad.date, isNull);
    expect(bad.slotId, isNull);
    expect(
      AppRouter.foodSearchRouteOf(Uri.parse('/today/add-food')).date,
      isNull,
    );
  });

  testWidgets('A07 D11 the add-food screen gets the day and the slot from '
      'the location, and the tab bar stays', (tester) async {
    final container = await pumpApp(
      tester,
      overrides: [searchOverride(FakeFoodSearch())],
    );
    container
        .read(appRouterProvider)
        .go(
          FoodSearchRoute(date: LocalDate(2026, 10, 20), slotId: 'slot-lunch'),
        );
    await tester.pumpAndSettle();

    final screen = tester.widget<FoodSearchScreen>(
      find.byType(FoodSearchScreen),
    );
    expect(screen.date, LocalDate(2026, 10, 20));
    expect(screen.slotId, 'slot-lunch');
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('HM-008 input bar on an empty Today opens search, back returns', (
    tester,
  ) async {
    await pumpApp(tester, overrides: [searchOverride(FakeFoodSearch())]);

    await tester.tap(find.byType(FbInputBar));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSearchScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
