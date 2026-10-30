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

/// The workout log form for a new session (WO-034, A37 D13), a detail
/// screen of the Workouts tab: on [date] (today when null), with the
/// [exercises] just picked, or a Repeat of session [repeat] (WO-024). Only
/// IDs and the date travel in the URL.
final class WorkoutLogRoute extends AppRoute {
  /// Creates the route.
  const new({this.date, this.repeat, this.template, this.exercises = const []});

  /// The route's path pattern.
  static const path = '/workouts/log';

  /// The query parameter holding [template].
  static const templateParam = 'template';

  /// The query parameter holding [date] (`YYYY-MM-DD`).
  static const dateParam = 'date';

  /// The query parameter holding [repeat].
  static const repeatParam = 'repeat';

  /// The query parameter holding [exercises], comma-separated.
  static const exercisesParam = 'exercises';

  /// The training day; null for today.
  final LocalDate? date;

  /// The session to repeat, or null.
  final String? repeat;

  /// The template to start from, or null (A37c D20).
  final String? template;

  /// The picked exercise IDs, in order.
  final List<String> exercises;

  @override
  String get location {
    final query = {
      dateParam: ?date?.toString(),
      repeatParam: ?repeat,
      templateParam: ?template,
      if (exercises.isNotEmpty) exercisesParam: exercises.join(','),
    };
    return Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// One logged session, in the log form (WO-034, A37 D14): a detail screen
/// of the Workouts tab.
final class WorkoutSessionRoute extends AppRoute {
  /// Creates the route for session [id].
  const new({required this.id});

  /// The route's path pattern.
  static const path = '/workouts/session/:id';

  /// The session.
  final String id;

  @override
  String get location => '/workouts/session/$id';
}

/// Every logged session by date (WO-040): a detail screen of the Workouts
/// tab.
final class WorkoutHistoryRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/workouts/history';

  @override
  String get location => path;
}

/// The optional weekly plan (WO-021, A37 D13): a detail screen of the
/// Workouts tab.
final class WorkoutPlanRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/workouts/plan';

  @override
  String get location => path;
}

/// The starter plans gallery (WO-023, A37 D13, D18): a detail screen of
/// the Workouts tab.
final class WorkoutStarterPlansRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/workouts/starter-plans';

  @override
  String get location => path;
}

/// Every exercise, to browse and open one (WO-041, A37 D13): a detail
/// screen of the Workouts tab.
final class WorkoutExercisesRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/workouts/exercises';

  @override
  String get location => path;
}

/// One exercise's page (WO-041): muscle map, graph, records and history,
/// nested under [WorkoutExercisesRoute]. [id] is a catalog ID or a custom
/// exercise's UUID.
final class WorkoutExerciseRoute extends AppRoute {
  /// Creates the route for exercise [id].
  const new(this.id);

  /// The route's path pattern.
  static const path = '/workouts/exercises/:id';

  /// The exercise.
  final String id;

  @override
  String get location =>
      '${WorkoutExercisesRoute.path}/${Uri.encodeComponent(id)}';
}

/// A new session from Today's planned row (HM-006, A37 D13, D20): the log
/// form started from [template] on [date], nested in the Today tab.
final class TodayWorkoutLogRoute extends AppRoute {
  /// Creates the route.
  const new({required this.template, this.date});

  /// The route's path pattern.
  static const path = '/today/workout-log';

  /// The template to start from.
  final String template;

  /// The training day; null for today.
  final LocalDate? date;

  @override
  String get location => Uri(
    path: path,
    queryParameters: {
      WorkoutLogRoute.templateParam: template,
      WorkoutLogRoute.dateParam: ?date?.toString(),
    },
  ).toString();
}

/// One logged session opened from Today's workout row (HM-006, A37 D13):
/// the same form, nested in the Today tab so its stack stays.
final class TodayWorkoutSessionRoute extends AppRoute {
  /// Creates the route for session [id].
  const new({required this.id});

  /// The route's path pattern.
  static const path = '/today/workout/:id';

  /// The session.
  final String id;

  @override
  String get location => '/today/workout/$id';
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

/// The add-food search's "Create … as your own food" (A09 D9, D10): the form
/// for a new personal food, nested under the search so the stack and the tab
/// bar stay.
///
/// [date] and [slotId] are the search's, so that once the food is saved the
/// food sheet can open for the same day and meal. The name the user searched
/// for never travels in the URL (backlog #42): it is handed over through a
/// one-shot provider.
final class NewFoodFromSearchRoute extends AppRoute {
  /// Creates the route.
  const new({this.date, this.slotId});

  /// The route's path pattern.
  static const path = '/today/add-food/new-food';

  /// The diary day the search was adding to; null for today.
  final LocalDate? date;

  /// The meal slot the search was adding to; null for the time of day.
  final String? slotId;

  @override
  String get location {
    final query = {
      FoodSearchRoute.dateParam: ?date?.toString(),
      FoodSearchRoute.slotParam: ?slotId,
    };
    return Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// The barcode scanner (FD-030, A28a D14): a detail screen of the Today tab,
/// opened by the input bar's barcode button. [date] and [slotId] are where a
/// scanned product is logged (today and the time's meal when null).
final class BarcodeScanRoute extends AppRoute {
  /// Creates the route.
  const new({this.date, this.slotId});

  /// The route's path pattern.
  static const path = '/today/scan';

  /// The diary day to add to; null for today.
  final LocalDate? date;

  /// The meal slot to add to; null to choose by the time of day.
  final String? slotId;

  @override
  String get location {
    final query = {
      FoodSearchRoute.dateParam: ?date?.toString(),
      FoodSearchRoute.slotParam: ?slotId,
    };
    return Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// "Add it yourself" from the scanner (A28a D9, D10): the new personal-food
/// form, nested under the scanner, prefilled with the barcode (and what Open
/// Food Facts knows for an incomplete product) through a one-shot provider;
/// nothing private travels in the URL. Once saved, the food sheet opens for
/// [date] and [slotId].
final class NewFoodFromScanRoute extends AppRoute {
  /// Creates the route.
  const new({this.date, this.slotId});

  /// The route's path pattern.
  static const path = '/today/scan/new-food';

  /// The diary day the scan was adding to; null for today.
  final LocalDate? date;

  /// The meal slot the scan was adding to; null for the time of day.
  final String? slotId;

  @override
  String get location {
    final query = {
      FoodSearchRoute.dateParam: ?date?.toString(),
      FoodSearchRoute.slotParam: ?slotId,
    };
    return Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// Your foods (A09 D10): the list of the user's own foods, a detail screen of
/// the Me tab.
final class PersonalFoodsRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/foods';

  @override
  String get location => path;
}

/// One personal food's form (A09 D10): the new-food form without an [id], the
/// edit form with one. Only the ID travels in the URL.
final class PersonalFoodRoute extends AppRoute {
  /// Creates the route; [id] is null for a new food.
  const new({this.id});

  /// The path of the new-food form.
  static const newPath = '/me/foods/new';

  /// The route's path pattern for an existing food.
  static const path = '/me/foods/:id';

  /// The food to edit; null for a new food.
  final String? id;

  @override
  String get location => id == null ? newPath : '/me/foods/$id';
}

/// Saved meals (A09 D10): the list of the user's saved meals, a detail screen
/// of the Me tab.
final class SavedMealsRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/meals';

  @override
  String get location => path;
}

/// One saved meal (A09 D10, D11): its items, and Log with a meal and a day.
/// Only the ID travels in the URL (backlog #42).
final class SavedMealRoute extends AppRoute {
  /// Creates the route for the saved meal [id].
  const new({required this.id});

  /// The route's path pattern.
  static const path = '/me/meals/:id';

  /// The saved meal to show.
  final String id;

  @override
  String get location => '/me/meals/$id';
}

/// The city picker (A10 D7, LC-033): a detail screen of the Me tab. No
/// parameters: the chosen city is read from, and written to, the settings.
final class CityPickerRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/city';

  @override
  String get location => path;
}

/// Meal times (A10 D13, DY-010): rename, add, remove, reorder and set the
/// time windows of the day's meals. A detail screen of the Me tab (A09 owns
/// `/me/meals`, the saved meals). No parameters.
final class MealSlotsRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/meal-times';

  @override
  String get location => path;
}

/// The weight graph opened from Today's weight card (A15 D12): a detail
/// screen of the Today tab, so Back returns to Today. No parameters.
final class TodayWeightGraphRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/today/weight';

  @override
  String get location => path;
}

/// The weight graph opened from the Progress tab (A15 D12). Same screen as
/// [TodayWeightGraphRoute]. No parameters.
final class WeightGraphRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/progress/weight';

  @override
  String get location => path;
}

/// Body measurements (A15b D18): a detail screen of the Progress tab.
final class MeasurementsRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/progress/measurements';

  @override
  String get location => path;
}

/// One measurement type's graph and entries (A15b D18), nested under
/// [MeasurementsRoute]. [key] is a `MeasurementTypeRef.key` (`waist`,
/// `custom-<uuid>`); an unknown or removed one shows the removed state.
final class MeasurementTypeRoute extends AppRoute {
  /// Creates the route for the type [key].
  const new(this.key);

  /// The route's path pattern.
  static const path = '/progress/measurements/:type';

  /// The path parameter holding [key].
  static const typeParam = 'type';

  /// The type's key.
  final String key;

  @override
  String get location =>
      '${MeasurementsRoute.path}/${Uri.encodeComponent(key)}';
}

/// Exercise progress from the Progress tab (IN-006, A37 D13): the same
/// list as [WorkoutExercisesRoute], nested in the Progress tab.
final class ProgressExercisesRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/progress/exercises';

  @override
  String get location => path;
}

/// One exercise's page from the Progress tab (IN-006): the same screen as
/// [WorkoutExerciseRoute], nested under [ProgressExercisesRoute].
final class ProgressExerciseRoute extends AppRoute {
  /// Creates the route for exercise [id].
  const new(this.id);

  /// The route's path pattern.
  static const path = '/progress/exercises/:id';

  /// The exercise.
  final String id;

  @override
  String get location =>
      '${ProgressExercisesRoute.path}/${Uri.encodeComponent(id)}';
}

/// Past weigh-ins as rows (A15b D17): full screen outside the tabs, opened
/// from the weight graph. No parameters.
final class WeightHistoryRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/weight-history';

  @override
  String get location => path;
}

/// Me › Profile & goal (A13c D13, TG-001/010–012): a detail screen of the
/// Me tab.
final class ProfileRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/profile';

  @override
  String get location => path;
}

/// Me › Targets (A13c D14, TG-021/040–044/054, SF-012): a detail screen of
/// the Me tab.
final class TargetsRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/targets';

  @override
  String get location => path;
}

/// About (A10 D14, SF-040): a detail screen of the Me tab.
final class AboutRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/me/about';

  @override
  String get location => path;
}

/// Setup (UX-060, A13 D10): the five-page profile, goal and targets flow,
/// a full screen outside the tabs. Opened from Today's setup row and Me;
/// never a startup redirect (UX-001). No parameters.
final class SetupRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/setup';

  @override
  String get location => path;
}

/// Sign in or create an account (AC-001, AC-003, A33): a full screen
/// outside the tabs, opened from Me › Account, the guest prompt and the
/// session-expired banner. Never a startup redirect (signing in is never
/// required). No parameters.
final class SignInRoute extends AppRoute {
  /// Creates the route.
  const new();

  /// The route's path pattern.
  static const path = '/sign-in';

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
