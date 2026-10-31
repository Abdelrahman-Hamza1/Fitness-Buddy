import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/design_preview/design_preview.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
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
  WeeklySummaryRoute() => (WeeklySummaryScreen, true),
  NotificationSettingsRoute() => (NotificationSettingsScreen, true),
  WorkoutsRoute() => (WorkoutsScreen, true),
  WorkoutLogRoute() => (WorkoutLogScreen, true),
  WorkoutSessionRoute() => (WorkoutLogScreen, true),
  WorkoutHistoryRoute() => (WorkoutHistoryScreen, true),
  WorkoutPlanRoute() => (WeeklyPlanScreen, true),
  WorkoutStarterPlansRoute() => (StarterPlansScreen, true),
  WorkoutExercisesRoute() => (ExercisePickerScreen, true),
  WorkoutExerciseRoute() => (ExerciseScreen, true),
  ProgressExercisesRoute() => (ExercisePickerScreen, true),
  ProgressExerciseRoute() => (ExerciseScreen, true),
  TodayWorkoutSessionRoute() => (WorkoutLogScreen, true),
  TodayWorkoutLogRoute() => (WorkoutLogScreen, true),
  MeRoute() => (MeScreen, true),
  DesignPreviewRoute() => (DesignPreviewScreen, true),
  FoodSearchRoute() => (FoodSearchScreen, true),
  NewFoodFromSearchRoute() => (PersonalFoodFormScreen, true),
  BarcodeScanRoute() => (BarcodeScanScreen, true),
  NewFoodFromScanRoute() => (PersonalFoodFormScreen, true),
  PersonalFoodsRoute() => (PersonalFoodsScreen, true),
  PersonalFoodRoute() => (PersonalFoodFormScreen, true),
  SavedMealsRoute() => (SavedMealsScreen, true),
  SavedMealRoute() => (SavedMealScreen, true),
  MealSlotsRoute() => (MealSlotsScreen, true),
  RamadanRoute() => (RamadanScreen, true),
  RamadanMealSlotsRoute() => (MealSlotsScreen, true),
  CityPickerRoute() => (CityPickerScreen, true),
  AboutRoute() => (AboutScreen, true),
  TodayWeightGraphRoute() => (WeightGraphScreen, true),
  WeightGraphRoute() => (WeightGraphScreen, true),
  WeightHistoryRoute() => (WeightHistoryScreen, false),
  MeasurementsRoute() => (MeasurementsScreen, true),
  MeasurementTypeRoute() => (MeasurementTypeScreen, true),
  UpdateRequiredRoute() => (UpdateRequiredScreen, false),
  SetupRoute() => (SetupScreen, false),
  SignInRoute() => (SignInScreen, false),
  DeleteAccountRoute() => (DeleteAccountScreen, false),
  ProfileRoute() => (ProfileGoalScreen, true),
  TargetsRoute() => (TargetsScreen, true),
};

/// An entry ID for the change-food routes.
const _entryId = '01890abc-def0-7123-8abc-0123456789ab';

final List<AppRoute> _allRoutes = [
  const TodayRoute(),
  const ProgressRoute(),
  WeeklySummaryRoute(start: LocalDate(2026, 10, 24)),
  const NotificationSettingsRoute(),
  const WorkoutsRoute(),
  const WorkoutLogRoute(),
  const WorkoutSessionRoute(id: _entryId),
  const WorkoutHistoryRoute(),
  const WorkoutPlanRoute(),
  const WorkoutStarterPlansRoute(),
  const WorkoutExercisesRoute(),
  const WorkoutExerciseRoute(_entryId),
  const ProgressExercisesRoute(),
  const ProgressExerciseRoute(_entryId),
  const TodayWorkoutSessionRoute(id: _entryId),
  const TodayWorkoutLogRoute(template: _entryId),
  const MeRoute(),
  const DesignPreviewRoute(),
  const FoodSearchRoute(),
  const NewFoodFromSearchRoute(),
  const BarcodeScanRoute(),
  const NewFoodFromScanRoute(),
  const PersonalFoodsRoute(),
  const PersonalFoodRoute(),
  const SavedMealsRoute(),
  const SavedMealRoute(id: _entryId),
  const MealSlotsRoute(),
  const RamadanRoute(),
  const RamadanMealSlotsRoute(),
  const TodayWeightGraphRoute(),
  const WeightGraphRoute(),
  const WeightHistoryRoute(),
  const MeasurementsRoute(),
  const MeasurementTypeRoute('waist'),
  const CityPickerRoute(),
  const AboutRoute(),
  const UpdateRequiredRoute(),
  const SetupRoute(),
  const SignInRoute(),
  const DeleteAccountRoute(),
  const ProfileRoute(),
  const TargetsRoute(),
];

void main() {
  test('typed routes: locations are unique and tabs are in UX-010 order', () {
    expect(
      _allRoutes.map((r) => r.location).toSet(),
      hasLength(_allRoutes.length),
    );
    expect(AppRouter.tabs.map((r) => r.location), [
      '/today',
      '/progress',
      '/workouts',
      '/me',
    ]);
    // A15b D17: the weight history is full screen, outside the tabs.
    expect(
      AppRouter.outsideTabs.map((r) => r.location),
      contains('/weight-history'),
    );
    expect(
      [
        ...AppRouter.tabs,
        ...AppRouter.outsideTabs,
        const DesignPreviewRoute(),
        const FoodSearchRoute(),
        const NewFoodFromSearchRoute(),
        const BarcodeScanRoute(),
        const NewFoodFromScanRoute(),
        const PersonalFoodsRoute(),
        const PersonalFoodRoute(),
        const SavedMealsRoute(),
        const SavedMealRoute(id: _entryId),
        const MealSlotsRoute(),
        const RamadanRoute(),
        const RamadanMealSlotsRoute(),
        const CityPickerRoute(),
        const AboutRoute(),
        const TodayWeightGraphRoute(),
        const WeightGraphRoute(),
        const MeasurementsRoute(),
        const MeasurementTypeRoute('waist'),
        const ProfileRoute(),
        const TargetsRoute(),
        const WorkoutLogRoute(),
        const WorkoutSessionRoute(id: _entryId),
        const WorkoutHistoryRoute(),
        const WorkoutPlanRoute(),
        const WorkoutStarterPlansRoute(),
        const WorkoutExercisesRoute(),
        const WorkoutExerciseRoute(_entryId),
        const ProgressExercisesRoute(),
        const ProgressExerciseRoute(_entryId),
        const TodayWorkoutSessionRoute(id: _entryId),
        const TodayWorkoutLogRoute(template: _entryId),
        WeeklySummaryRoute(start: LocalDate(2026, 10, 24)),
        const NotificationSettingsRoute(),
      ].map((r) => r.location),
      unorderedEquals(_allRoutes.map((r) => r.location)),
    );
  });

  testWidgets('typed routes: every AppRoute location is registered in the '
      'router', (tester) async {
    final container = await pumpApp(
      tester,
      overrides: [
        searchOverride(FakeFoodSearch()),
        barcodeCameraEnabledProvider.overrideWithValue(false),
      ],
    );
    final router = container.read(appRouterProvider);

    for (final route in _allRoutes) {
      final (screen, hasTabBar) = _expected(route);
      showRoute(container, route);
      await tester.pumpAndSettle();

      // The matched location has no query string (A37c: the Today log
      // route always carries its template there).
      expect(
        router.config.state.matchedLocation,
        Uri.parse(route.location).path,
        reason: '$route',
      );
      expect(find.byType(screen), findsOneWidget, reason: '$route');
      expect(
        find.byType(NavigationBar),
        hasTabBar ? findsOneWidget : findsNothing,
        reason: '$route',
      );
    }
    await unmountApp(tester, container);
  });

  testWidgets('D10 a malformed saved meal ID goes to the list', (tester) async {
    final container = await pumpApp(
      tester,
      overrides: [searchOverride(FakeFoodSearch())],
    );
    final router = container.read(appRouterProvider);

    router.config.go('/me/meals/not-an-id');
    await tester.pumpAndSettle();

    expect(router.config.state.matchedLocation, SavedMealsRoute.path);
    expect(find.byType(SavedMealsScreen), findsOneWidget);
    expect(find.byType(SavedMealScreen), findsNothing);
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

  test('D7 the change-food route carries the item and its version in the '
      'query, and the router rebuilds it', () {
    final route = FoodSearchRoute(
      date: LocalDate(2026, 10, 20),
      slotId: 'slot-lunch',
      replace: VersionedId(_entryId, 3),
    );
    expect(
      route.location,
      '/today/add-food?date=2026-10-20&slot=slot-lunch'
      '&replace=$_entryId&version=3',
    );
    final back = AppRouter.foodSearchRouteOf(Uri.parse(route.location));
    expect(back.replace, VersionedId(_entryId, 3));
    expect(back.date, LocalDate(2026, 10, 20));
    expect(AppRouter.isMalformedFoodSearch(Uri.parse(route.location)), isFalse);
    expect(
      AppRouter.isMalformedFoodSearch(Uri.parse('/today/add-food')),
      isFalse,
    );
    expect(const FoodSearchRoute().replace, isNull);
  });

  test('D7 a replace without a valid UUID and a version of at least 1 is '
      'malformed', () {
    for (final query in [
      'replace=$_entryId', // no version
      'version=2', // no item
      'replace=$_entryId&version=0',
      'replace=$_entryId&version=-1',
      'replace=$_entryId&version=two',
      'replace=$_entryId&version=',
      'replace=not-a-uuid&version=1',
      'replace=${_entryId.toUpperCase()}&version=1',
      'replace=&version=1',
    ]) {
      final location = Uri.parse('/today/add-food?$query');
      expect(AppRouter.isMalformedFoodSearch(location), isTrue, reason: query);
      expect(
        AppRouter.foodSearchRouteOf(location).replace,
        isNull,
        reason: query,
      );
    }
  });

  testWidgets('D7 a valid replace parameter opens the search in change-food '
      'mode', (tester) async {
    final container = await pumpApp(
      tester,
      overrides: [searchOverride(FakeFoodSearch())],
    );
    container
        .read(appRouterProvider)
        .go(
          FoodSearchRoute(
            date: LocalDate(2026, 10, 20),
            replace: VersionedId(_entryId, 2),
          ),
        );
    await tester.pumpAndSettle();

    final screen = tester.widget<FoodSearchScreen>(
      find.byType(FoodSearchScreen),
    );
    expect(screen.replace, VersionedId(_entryId, 2));
    expect(find.text('Change food'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
