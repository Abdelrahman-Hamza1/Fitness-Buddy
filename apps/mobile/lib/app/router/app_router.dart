import 'dart:async';

import 'package:fb_domain/fb_domain.dart' show LocalDate, VersionedId, isUuid;
import 'package:fb_mobile/app/shell/app_shell.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/update_gate.dart';
import 'package:fb_mobile/core/errors/navigation_observer.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/design_preview/design_preview.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// The app's router (S06 plan D2, A2): go_router behind the [AppNavigator]
/// port. `package:go_router` is imported only in `lib/app/router/`.
///
/// Four tabs in a `StatefulShellRoute` (each tab keeps its own navigation
/// stack and state, UX-010), the detail screens nested in a tab (only the dev
/// flavor's design preview so far) and the screens outside the tabs.
///
/// The update gate (S06 plan D10, A1) is a redirect: while an update is
/// required every location shows [UpdateRequiredRoute]; once it is lifted
/// that screen goes back to [TodayRoute].
final class AppRouter implements AppNavigator {
  /// Creates the router, starting at [TodayRoute]. [updateRequired] is the
  /// update gate; the router re-checks its redirect when it changes.
  /// [designPreview] registers the [DesignPreviewRoute] (dev flavor only,
  /// A02 D15).
  new({
    required ValueListenable<bool> updateRequired,
    bool designPreview = false,
  }) : config = _createConfig(updateRequired, designPreview: designPreview);

  static GoRouter _createConfig(
    ValueListenable<bool> gate, {
    required bool designPreview,
  }) => GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
    observers: [createErrorNavigationObserver()],
    initialLocation: TodayRoute.path,
    refreshListenable: gate,
    redirect: (_, state) =>
        redirect(state.matchedLocation, updateRequired: gate.value),
    // An unknown location (e.g. a stale deep link) goes home instead of
    // showing go_router's error page.
    onException: (_, _, router) => router.go(TodayRoute.path),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(
          currentIndex: shell.currentIndex,
          // Tapping the selected tab again returns to its first screen.
          onTabSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          child: shell,
        ),
        // Order = the tab order in AppShell.
        branches: [
          for (final route in tabs)
            StatefulShellBranch(
              routes: [
                _goRoute(
                  route,
                  // Detail screens nest in their tab, so the tab bar stays
                  // and the tab keeps its stack.
                  children: [
                    if (route is TodayRoute) _foodSearchRoute(),
                    if (route is MeRoute) ...[
                      _personalFoodsRoute(),
                      _savedMealsRoute(),
                      _goRoute(const MealSlotsRoute(), nested: true),
                      _goRoute(const CityPickerRoute(), nested: true),
                      _goRoute(const AboutRoute(), nested: true),
                      if (designPreview)
                        _goRoute(const DesignPreviewRoute(), nested: true),
                    ],
                  ],
                ),
              ],
            ),
        ],
      ),
      for (final route in outsideTabs) _goRoute(route),
    ],
  );

  /// The tab routes, in tab order (UX-010).
  static const List<AppRoute> tabs = [
    TodayRoute(),
    ProgressRoute(),
    WorkoutsRoute(),
    MeRoute(),
  ];

  /// The routes shown outside the tabs (full screen, no tab bar).
  static const List<AppRoute> outsideTabs = [UpdateRequiredRoute()];

  /// The go_router configuration, for `MaterialApp.router`.
  final GoRouter config;

  /// Where to send [location] instead, or null to show it (the update gate).
  static String? redirect(String location, {required bool updateRequired}) {
    final atUpdateScreen = location == UpdateRequiredRoute.path;
    if (updateRequired && !atUpdateScreen) return UpdateRequiredRoute.path;
    if (!updateRequired && atUpdateScreen) return TodayRoute.path;
    return null;
  }

  static GoRoute _goRoute(
    AppRoute route, {
    List<RouteBase> children = const [],
    bool nested = false,
  }) => GoRoute(
    // A nested route's path is relative to its parent's.
    path: nested ? route.location.split('/').last : route.location,
    name: route.location,
    builder: (_, _) => _screen(route),
    routes: children,
  );

  // The one route with parameters so far: it rebuilds its typed route from
  // the query string (A07 D11), so the screen never parses a URL.
  static GoRoute _foodSearchRoute() => GoRoute(
    path: FoodSearchRoute.path.split('/').last,
    name: FoodSearchRoute.path,
    // A swap with a broken target must never become an add (A08 D7).
    redirect: (_, state) =>
        isMalformedFoodSearch(state.uri) ? TodayRoute.path : null,
    builder: (_, state) => _screen(foodSearchRouteOf(state.uri)),
    routes: [
      // "Create … as your own food" (A09 D9): nested under the search.
      GoRoute(
        path: NewFoodFromSearchRoute.path.split('/').last,
        name: NewFoodFromSearchRoute.path,
        builder: (_, state) => _screen(newFoodRouteOf(state.uri)),
      ),
    ],
  );

  // Your foods (A09 D10). `new` comes before `:id`, so it is never read as
  // an ID; a malformed ID goes to the list (A08 D7 pattern).
  static GoRoute _personalFoodsRoute() => GoRoute(
    path: PersonalFoodsRoute.path.split('/').last,
    name: PersonalFoodsRoute.path,
    builder: (_, _) => _screen(const PersonalFoodsRoute()),
    routes: [
      GoRoute(
        path: PersonalFoodRoute.newPath.split('/').last,
        name: PersonalFoodRoute.newPath,
        builder: (_, _) => _screen(const PersonalFoodRoute()),
      ),
      GoRoute(
        path: ':id',
        name: '/me/foods/:id',
        redirect: (_, state) => isUuid(state.pathParameters['id'] ?? '')
            ? null
            : PersonalFoodsRoute.path,
        builder: (_, state) =>
            _screen(PersonalFoodRoute(id: state.pathParameters['id'])),
      ),
    ],
  );

  // Saved meals (A09 D10): a malformed ID goes to the list.
  static GoRoute _savedMealsRoute() => GoRoute(
    path: SavedMealsRoute.path.split('/').last,
    name: SavedMealsRoute.path,
    builder: (_, _) => _screen(const SavedMealsRoute()),
    routes: [
      GoRoute(
        path: ':id',
        name: '/me/meals/:id',
        redirect: (_, state) => isUuid(state.pathParameters['id'] ?? '')
            ? null
            : SavedMealsRoute.path,
        builder: (_, state) =>
            _screen(SavedMealRoute(id: state.pathParameters['id']!)),
      ),
    ],
  );

  /// The change-food target in [location]: null when there is none or it is
  /// malformed. See [isMalformedFoodSearch].
  static VersionedId? _replaceOf(Uri location) {
    final id = location.queryParameters[FoodSearchRoute.replaceParam];
    final version = int.tryParse(
      location.queryParameters[FoodSearchRoute.versionParam] ?? '',
    );
    if (id == null || version == null || version < 1 || !isUuid(id)) {
      return null;
    }
    return VersionedId(id, version);
  }

  /// Whether [location] asks to change a food but names no valid item: a
  /// `replace` or `version` parameter without a UUID and a version of at
  /// least 1. Such a location goes to Today instead of the search.
  @visibleForTesting
  static bool isMalformedFoodSearch(Uri location) {
    final params = location.queryParameters;
    final asked =
        params.containsKey(FoodSearchRoute.replaceParam) ||
        params.containsKey(FoodSearchRoute.versionParam);
    return asked && _replaceOf(location) == null;
  }

  /// The [FoodSearchRoute] a location stands for. A missing or malformed
  /// parameter is ignored (today, and the slot of the time of day); a
  /// malformed change-food target is turned away before this (see
  /// [isMalformedFoodSearch]).
  @visibleForTesting
  static FoodSearchRoute foodSearchRouteOf(Uri location) {
    final date = location.queryParameters[FoodSearchRoute.dateParam];
    final slot = location.queryParameters[FoodSearchRoute.slotParam];
    return FoodSearchRoute(
      date: date == null ? null : LocalDate.tryParse(date),
      slotId: slot == null || slot.isEmpty ? null : slot,
      replace: _replaceOf(location),
    );
  }

  /// The [NewFoodFromSearchRoute] a location stands for; a missing or
  /// malformed parameter is ignored, as for [foodSearchRouteOf].
  @visibleForTesting
  static NewFoodFromSearchRoute newFoodRouteOf(Uri location) {
    final search = foodSearchRouteOf(location);
    return NewFoodFromSearchRoute(date: search.date, slotId: search.slotId);
  }

  // Exhaustive: a new AppRoute without a screen doesn't compile.
  static Widget _screen(AppRoute route) => switch (route) {
    TodayRoute() => const TodayScreen(),
    ProgressRoute() => const ProgressScreen(),
    WorkoutsRoute() => const WorkoutsScreen(),
    MeRoute() => const MeScreen(),
    DesignPreviewRoute() => const DesignPreviewScreen(),
    FoodSearchRoute(:final date, :final slotId, :final replace) =>
      FoodSearchScreen(date: date, slotId: slotId, replace: replace),
    NewFoodFromSearchRoute(:final date, :final slotId) =>
      PersonalFoodFormScreen(addTo: (date: date, slotId: slotId)),
    PersonalFoodsRoute() => const PersonalFoodsScreen(),
    PersonalFoodRoute(:final id) => PersonalFoodFormScreen(id: id),
    SavedMealsRoute() => const SavedMealsScreen(),
    SavedMealRoute(:final id) => SavedMealScreen(id: id),
    MealSlotsRoute() => const MealSlotsScreen(),
    CityPickerRoute() => const CityPickerScreen(),
    AboutRoute() => const AboutScreen(),
    UpdateRequiredRoute() => const UpdateRequiredScreen(),
  };

  @override
  void go(AppRoute route) => config.go(route.location);

  @override
  void push(AppRoute route) => unawaited(config.push<void>(route.location));

  @override
  void pop() {
    if (config.canPop()) config.pop();
  }

  /// Releases the router's listeners.
  void dispose() => config.dispose();
}

/// The app's single [AppRouter]; also serves as the [AppNavigator]
/// (`lib/app/app_scope.dart`). Follows [updateRequiredProvider].
@Riverpod(keepAlive: true)
AppRouter appRouter(Ref ref) {
  final updateRequired = ValueNotifier(false);
  ref.listen(
    updateRequiredProvider,
    (_, required) => updateRequired.value = required,
    fireImmediately: true,
  );
  final router = AppRouter(
    updateRequired: updateRequired,
    // The design preview exists in the dev flavor only (A02 D15).
    designPreview: ref.read(appConfigProvider).flavor == AppFlavor.dev,
  );
  ref.onDispose(() {
    router.dispose();
    updateRequired.dispose();
  });
  return router;
}
