import 'package:fb_domain/fb_domain.dart' show LocalDate, VersionedId;

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
/// - `AppNavigator` has `push` and `pop` for it ([DesignPreviewRoute] is the
///   first, dev flavor only).
///
/// [FoodSearchRoute] is the first route with parameters: typed fields,
/// carried in the query string (`/today/add-food?date=2026-10-22&slot=s1`).
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

/// The add-food search (FD-020; A07 D11): a detail screen of the Today tab.
///
/// [date] is the diary day to add to and [slotId] the meal slot; both are
/// optional (today, and the slot of the current time). Only simple values
/// travel in the URL: the food itself never does.
///
/// With [replace] the search changes the food of that logged item instead of
/// adding one (DY-021, A08 D7): the item's ID and the version the user saw.
/// A malformed pair never reaches the screen (the router sends it to Today),
/// so a swap can't silently become an add.
final class FoodSearchRoute extends AppRoute {
  /// Creates the route.
  const new({this.date, this.slotId, this.replace});

  /// The route's path pattern.
  static const path = '/today/add-food';

  /// The query parameter holding [date] (`YYYY-MM-DD`).
  static const dateParam = 'date';

  /// The query parameter holding [slotId].
  static const slotParam = 'slot';

  /// The query parameter holding the ID of the item to replace.
  static const replaceParam = 'replace';

  /// The query parameter holding the version of the item to replace.
  static const versionParam = 'version';

  /// The diary day to add to; null for today.
  final LocalDate? date;

  /// The meal slot to add to; null to choose by the time of day.
  final String? slotId;

  /// The logged item whose food is replaced, at the version shown; null to
  /// add a new item.
  final VersionedId? replace;

  @override
  String get location {
    final query = {
      dateParam: ?date?.toString(),
      slotParam: ?slotId,
      if (replace case final item?) ...{
        replaceParam: item.id,
        versionParam: '${item.expectedVersion}',
      },
    };
    return Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
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

/// The design preview (A02 D15): a detail screen of the Me tab with the
/// component gallery, the token pages and the mockups.
///
/// Only registered in the dev flavor; elsewhere the location is unknown and
/// goes to Today.
final class DesignPreviewRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/design-preview';

  @override
  String get location => path;
}
