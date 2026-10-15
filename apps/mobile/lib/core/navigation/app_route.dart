/// The app's typed routes (S06 plan D2, A2).
///
/// Hand-written and free of go_router, so features can navigate without
/// depending on the router package or on `app/`. The router (in
/// `lib/app/router/`) maps each route to its screen with an exhaustive
/// `switch`, so a new route without a screen fails to compile.
///
/// Routes with parameters (the first detail screen, e.g. a meal) take this
/// shape:
/// - the route class holds its typed fields and builds [location] from them
///   (`/today/meal/<id>`), and keeps a static `path` pattern
///   (`/today/meal/:id`);
/// - the router registers the static pattern and rebuilds the typed route
///   from go_router's state with a `fromState`-style factory in
///   `lib/app/router/` (route classes stay free of go_router);
/// - a detail route nests inside its tab's branch, so the tab bar stays and
///   the tab keeps its stack;
/// - `AppNavigator` gains `push` and `pop` with that first detail screen.
sealed class AppRoute {
  /// Creates a route.
  const new();

  /// The location to navigate to, e.g. `/today`.
  String get location;
}

/// The Today tab (home, UX-010).
final class TodayRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/today';

  @override
  String get location => path;
}

/// The Progress tab (UX-010).
final class ProgressRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/progress';

  @override
  String get location => path;
}

/// The Workouts tab (UX-010).
final class WorkoutsRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/workouts';

  @override
  String get location => path;
}

/// The Me tab: profile, goals, targets, memory, settings (UX-010).
final class MeRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me';

  @override
  String get location => path;
}

/// The "update needed" screen, outside the tabs (S06 plan D10).
///
/// Only the router targets it (its update-gate redirect); features never
/// navigate here.
final class UpdateRequiredRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/update-required';

  @override
  String get location => path;
}
