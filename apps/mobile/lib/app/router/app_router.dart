import 'package:fb_mobile/app/shell/app_shell.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/config/update_gate.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
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
/// stack and state, UX-010) and the screens outside the tabs.
///
/// The update gate (S06 plan D10, A1) is a redirect: while an update is
/// required every location shows [UpdateRequiredRoute]; once it is lifted
/// that screen goes back to [TodayRoute].
final class AppRouter implements AppNavigator {
  /// Creates the router, starting at [TodayRoute]. [updateRequired] is the
  /// update gate; the router re-checks its redirect when it changes.
  new({required ValueListenable<bool> updateRequired})
    : config = _createConfig(updateRequired);

  static GoRouter _createConfig(ValueListenable<bool> gate) => GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
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
            StatefulShellBranch(routes: [_goRoute(route)]),
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

  static GoRoute _goRoute(AppRoute route) =>
      GoRoute(path: route.location, builder: (_, _) => _screen(route));

  // Exhaustive: a new AppRoute without a screen doesn't compile.
  static Widget _screen(AppRoute route) => switch (route) {
    TodayRoute() => const TodayScreen(),
    ProgressRoute() => const ProgressScreen(),
    WorkoutsRoute() => const WorkoutsScreen(),
    MeRoute() => const MeScreen(),
    UpdateRequiredRoute() => const UpdateRequiredScreen(),
  };

  @override
  void go(AppRoute route) => config.go(route.location);

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
  final router = AppRouter(updateRequired: updateRequired);
  ref.onDispose(() {
    router.dispose();
    updateRequired.dispose();
  });
  return router;
}
