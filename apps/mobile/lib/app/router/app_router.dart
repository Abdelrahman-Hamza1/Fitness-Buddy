import 'dart:async';

import 'package:fb_domain/fb_domain.dart'
    show LocalDate, VersionedId, checkExerciseId, isUuid;
import 'package:fb_mobile/app/router/tab_tap.dart';
import 'package:fb_mobile/app/shell/app_shell.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/update_gate.dart';
import 'package:fb_mobile/core/errors/navigation_observer.dart';
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
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
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
/// Four tabs in a `StatefulShellRoute`, the detail screens nested in their
/// tab and the screens outside the tabs. **Tab taps** (UX-010, A45 D11):
/// another tab opens at its root screen, unless a screen in it holds
/// unsaved edits, which it keeps; the current tab goes back to its root
/// (asking first when a screen holds unsaved edits, [UnsavedEdits]), and at
/// its root scrolls to the top ([AppTab], `ScrollToTopOnTabReselect`).
///
/// The update gate (S06 plan D10, A1) is a redirect: while an update is
/// required every location shows [UpdateRequiredRoute]; once it is lifted
/// that screen goes back to [TodayRoute].
final class AppRouter implements AppNavigator {
  /// Creates the router, starting at [TodayRoute]. [updateRequired] is the
  /// update gate; the router re-checks its redirect when it changes.
  /// [designPreview] registers the [DesignPreviewRoute] (dev flavor only,
  /// A02 D15).
  /// [onReselect] hears a re-tap of the current tab at its root;
  /// [unsavedEdits] tells which tabs hold a screen with unsaved edits.
  new({
    required ValueListenable<bool> updateRequired,
    bool designPreview = false,
    this.onReselect,
    this.onActivate,
    this.unsavedEdits,
  }) : assert(tabs.length == AppTab.values.length, 'one AppTab per tab') {
    config = _createConfig(updateRequired, designPreview: designPreview);
    // Each tab keeps its own stack: remember where each one is.
    config.routerDelegate.addListener(_recordLocation);
  }

  /// The location each tab shows (its kept stack's top), by tab index.
  final Map<int, String> _tabLocations = {};

  void _recordLocation() {
    final uri = config.routerDelegate.currentConfiguration.uri;
    final index = _tabOf(uri.path);
    if (index >= 0) _tabLocations[index] = uri.toString();
  }

  static int _tabOf(String path) => tabs.indexWhere(
    (t) => path == t.location || path.startsWith('${t.location}/'),
  );

  /// Called with the tab tapped again while it shows its root screen.
  final ValueChanged<AppTab>? onReselect;

  /// Called with a tab the user switches to from another tab (screens kept
  /// by the indexed stack refresh on it, e.g. A38's check-in retry).
  final ValueChanged<AppTab>? onActivate;

  /// The screens holding unsaved edits, by navigator.
  final UnsavedEdits? unsavedEdits;

  /// Each tab's navigator, in tab order (a notification's link asks the
  /// target tab's dirty screen first, [openLocation]).
  final List<GlobalKey<NavigatorState>> _branchKeys = [
    for (final route in tabs)
      GlobalKey<NavigatorState>(debugLabel: route.location),
  ];

  GoRouter _createConfig(
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
          onTabSelected: (index) => _selectTab(shell, index),
          child: shell,
        ),
        // Order = the tab order in AppShell.
        branches: [
          for (final (index, route) in tabs.indexed)
            StatefulShellBranch(
              navigatorKey: _branchKeys[index],
              routes: [
                _goRoute(
                  route,
                  // Detail screens nest in their tab, so the tab bar stays
                  // and the tab keeps its stack.
                  children: [
                    if (route is TodayRoute) ...[
                      _foodSearchRoute(),
                      _barcodeScanRoute(),
                      _goRoute(const TodayWeightGraphRoute(), nested: true),
                      _sessionRoute(
                        TodayWorkoutSessionRoute.path,
                        TodayRoute.path,
                        (id) => TodayWorkoutSessionRoute(id: id),
                      ),
                      _todayWorkoutLogRoute(),
                    ],
                    if (route is WorkoutsRoute) ...[
                      _workoutLogRoute(),
                      _sessionRoute(
                        WorkoutSessionRoute.path,
                        WorkoutsRoute.path,
                        (id) => WorkoutSessionRoute(id: id),
                      ),
                      _goRoute(const WorkoutHistoryRoute(), nested: true),
                      _goRoute(const WorkoutPlanRoute(), nested: true),
                      _goRoute(const WorkoutStarterPlansRoute(), nested: true),
                      _exercisesRoute(
                        WorkoutExercisesRoute.path,
                        WorkoutExerciseRoute.path,
                        const WorkoutExercisesRoute(),
                        WorkoutExerciseRoute.new,
                      ),
                    ],
                    if (route is ProgressRoute) ...[
                      _weeklySummaryRoute(),
                      _goRoute(const WeightGraphRoute(), nested: true),
                      _measurementsRoute(),
                      _exercisesRoute(
                        ProgressExercisesRoute.path,
                        ProgressExerciseRoute.path,
                        const ProgressExercisesRoute(),
                        ProgressExerciseRoute.new,
                      ),
                    ],
                    if (route is MeRoute) ...[
                      _personalFoodsRoute(),
                      _savedMealsRoute(),
                      _goRoute(const MealSlotsRoute(), nested: true),
                      _goRoute(const CityPickerRoute(), nested: true),
                      _goRoute(const ProfileRoute(), nested: true),
                      _goRoute(const TargetsRoute(), nested: true),
                      _goRoute(const AboutRoute(), nested: true),
                      _goRoute(const NotificationSettingsRoute(), nested: true),
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
  static const List<AppRoute> outsideTabs = [
    UpdateRequiredRoute(),
    SetupRoute(),
    SignInRoute(),
    DeleteAccountRoute(),
    WeightHistoryRoute(),
  ];

  /// The go_router configuration, for `MaterialApp.router`.
  late final GoRouter config;

  /// Runs the tab rules ([tabTapAction]) for a tap on tab [index].
  void _selectTab(StatefulNavigationShell shell, int index) {
    // A branch never visited has no navigator yet: it is at its root.
    final navigator = shell.route.branches[index].navigatorKey.currentState;
    final action = tabTapAction(
      sameTab: index == shell.currentIndex,
      atRoot: !(navigator?.canPop() ?? false),
      holdsEdits: unsavedEdits?.holds(navigator) ?? false,
    );
    if (index != shell.currentIndex) onActivate?.call(AppTab.values[index]);
    switch (action) {
      case TabTapAction.goRoot:
        shell.goBranch(index, initialLocation: true);
      case TabTapAction.keepStack:
        shell.goBranch(index);
      case TabTapAction.scrollTop:
        onReselect?.call(AppTab.values[index]);
      case TabTapAction.confirmThenRoot:
        unawaited(_confirmThenRoot(shell, index, navigator!));
    }
  }

  /// Asks the screen with unsaved edits in tab [index]; goes to the tab's
  /// root only on a confirmed discard, and only if the tab is still shown.
  Future<void> _confirmThenRoot(
    StatefulNavigationShell shell,
    int index,
    NavigatorState navigator,
  ) async {
    if (!await unsavedEdits!.confirm(navigator)) return;
    final tab = tabs[index].location;
    final path = config.routerDelegate.currentConfiguration.uri.path;
    if (path != tab && !path.startsWith('$tab/')) return;
    shell.goBranch(index, initialLocation: true);
  }

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
    // Today reads the sheet a notification asks it to open (A40 D9).
    builder: (_, state) =>
        _screen(route is TodayRoute ? todayRouteOf(state.uri) : route),
    routes: children,
  );

  /// The [TodayRoute] a location stands for: an unknown `open` is ignored.
  @visibleForTesting
  static TodayRoute todayRouteOf(Uri location) => TodayRoute(
    open: TodayOpen.of(location.queryParameters[TodayRoute.openParam]),
  );

  // One week's summary (A39a D2): a malformed date goes to the tab.
  static GoRoute _weeklySummaryRoute() {
    final parts = WeeklySummaryRoute.path.split('/');
    return GoRoute(
      path: parts.sublist(parts.length - 2).join('/'),
      name: WeeklySummaryRoute.path,
      redirect: (_, state) =>
          weeklySummaryStartOf(state.uri) == null ? ProgressRoute.path : null,
      builder: (_, state) =>
          _screen(WeeklySummaryRoute(start: weeklySummaryStartOf(state.uri)!)),
    );
  }

  /// The week start in a weekly summary location, or null when malformed.
  @visibleForTesting
  static LocalDate? weeklySummaryStartOf(Uri location) {
    final segments = location.pathSegments;
    return segments.length == 3 ? LocalDate.tryParse(segments.last) : null;
  }

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

  // The barcode scanner (A28a D14) and its "Add it yourself" form; both read
  // only the day and the meal from the query string, like the search.
  static GoRoute _barcodeScanRoute() => GoRoute(
    path: BarcodeScanRoute.path.split('/').last,
    name: BarcodeScanRoute.path,
    builder: (_, state) {
      final search = foodSearchRouteOf(state.uri);
      return _screen(
        BarcodeScanRoute(date: search.date, slotId: search.slotId),
      );
    },
    routes: [
      GoRoute(
        path: NewFoodFromScanRoute.path.split('/').last,
        name: NewFoodFromScanRoute.path,
        builder: (_, state) {
          final search = foodSearchRouteOf(state.uri);
          return _screen(
            NewFoodFromScanRoute(date: search.date, slotId: search.slotId),
          );
        },
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

  // Measurements (A15b D18): the list and one type's screen by its key.
  static GoRoute _measurementsRoute() => GoRoute(
    path: MeasurementsRoute.path.split('/').last,
    name: MeasurementsRoute.path,
    builder: (_, _) => _screen(const MeasurementsRoute()),
    routes: [
      GoRoute(
        path: ':${MeasurementTypeRoute.typeParam}',
        name: MeasurementTypeRoute.path,
        builder: (_, state) => _screen(
          MeasurementTypeRoute(
            state.pathParameters[MeasurementTypeRoute.typeParam] ?? '',
          ),
        ),
      ),
    ],
  );

  // Every exercise and one exercise's page (A37 D13), in the Workouts or
  // the Progress tab; a malformed exercise ID goes back to the list.
  static GoRoute _exercisesRoute(
    String listPath,
    String pagePath,
    AppRoute list,
    AppRoute Function(String id) page,
  ) => GoRoute(
    path: listPath.split('/').last,
    name: listPath,
    builder: (_, _) => _screen(list),
    routes: [
      GoRoute(
        path: ':id',
        name: pagePath,
        redirect: (_, state) =>
            isExerciseId(state.pathParameters['id'] ?? '') ? null : listPath,
        builder: (_, state) => _screen(page(state.pathParameters['id']!)),
      ),
    ],
  );

  /// Whether [id] is a catalog exercise ID or a UUID.
  @visibleForTesting
  static bool isExerciseId(String id) {
    try {
      checkExerciseId(id, 'id');
      return true;
      // A malformed ID is turned away, never guessed.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return false;
    }
  }

  // A new workout (A37 D13): the date and the session to repeat come from
  // the query string; malformed ones are ignored (today, no repeat).
  static GoRoute _workoutLogRoute() => GoRoute(
    path: WorkoutLogRoute.path.split('/').last,
    name: WorkoutLogRoute.path,
    builder: (_, state) =>
        _visit(state.uri, _screen(workoutLogRouteOf(state.uri))),
  );

  // A new workout from Today's planned row (A37 D13, D20); without a valid
  // template it goes back to Today.
  static GoRoute _todayWorkoutLogRoute() => GoRoute(
    path: TodayWorkoutLogRoute.path.split('/').last,
    name: TodayWorkoutLogRoute.path,
    redirect: (_, state) =>
        workoutLogRouteOf(state.uri).template == null ? TodayRoute.path : null,
    builder: (_, state) {
      final log = workoutLogRouteOf(state.uri);
      return _visit(
        state.uri,
        _screen(TodayWorkoutLogRoute(template: log.template!, date: log.date)),
      );
    },
  );

  /// A workout log screen keyed to its location: go_router keeps a
  /// route's widget state across query or ID changes, so a link to another
  /// visit (a notification) must build a fresh screen and controller, never
  /// reuse the finished one (A40 fix-check).
  static Widget _visit(Uri location, Widget screen) =>
      KeyedSubtree(key: ValueKey('visit:$location'), child: screen);

  /// The [WorkoutLogRoute] a location stands for.
  @visibleForTesting
  static WorkoutLogRoute workoutLogRouteOf(Uri location) {
    final params = location.queryParameters;
    final date = params[WorkoutLogRoute.dateParam];
    final repeat = params[WorkoutLogRoute.repeatParam];
    final template = params[WorkoutLogRoute.templateParam];
    return WorkoutLogRoute(
      date: date == null ? null : LocalDate.tryParse(date),
      repeat: repeat != null && isUuid(repeat) ? repeat : null,
      template: template != null && isUuid(template) ? template : null,
      exercises: [
        for (final id in (params[WorkoutLogRoute.exercisesParam] ?? '').split(
          ',',
        ))
          if (isExerciseId(id)) id,
      ],
    );
  }

  // One session by ID (A37 D13, D14), nested in [home]'s tab; a malformed
  // ID goes back to [home].
  static GoRoute _sessionRoute(
    String pattern,
    String home,
    AppRoute Function(String id) route,
  ) {
    final parts = pattern.split('/');
    return GoRoute(
      path: parts.sublist(parts.length - 2).join('/'),
      name: pattern,
      redirect: (_, state) =>
          isUuid(state.pathParameters['id'] ?? '') ? null : home,
      builder: (_, state) =>
          _visit(state.uri, _screen(route(state.pathParameters['id']!))),
    );
  }

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
    TodayRoute(:final open) => TodayScreen(open: open),
    ProgressRoute() => const ProgressScreen(),
    WeeklySummaryRoute(:final start) => WeeklySummaryScreen(start: start),
    WorkoutsRoute() => const WorkoutsScreen(),
    WorkoutLogRoute(
      :final date,
      :final repeat,
      :final template,
      :final exercises,
    ) =>
      WorkoutLogScreen.newSession(
        date: date,
        repeatOf: repeat,
        template: template,
        exercises: exercises,
      ),
    TodayWorkoutLogRoute(:final date, :final template) =>
      WorkoutLogScreen.newSession(
        date: date,
        template: template,
        inToday: true,
      ),
    WorkoutSessionRoute(:final id) => WorkoutLogScreen.session(id),
    TodayWorkoutSessionRoute(:final id) => WorkoutLogScreen.session(
      id,
      inToday: true,
    ),
    WorkoutHistoryRoute() => const WorkoutHistoryScreen(),
    WorkoutPlanRoute() => const WeeklyPlanScreen(),
    WorkoutStarterPlansRoute() => const StarterPlansScreen(),
    WorkoutExercisesRoute() => const ExercisePickerScreen.browse(
      tab: ExerciseBrowseTab.workouts,
    ),
    WorkoutExerciseRoute(:final id) => ExerciseScreen(
      exerciseId: id,
      tab: ExerciseBrowseTab.workouts,
    ),
    ProgressExercisesRoute() => const ExercisePickerScreen.browse(
      tab: ExerciseBrowseTab.progress,
    ),
    ProgressExerciseRoute(:final id) => ExerciseScreen(
      exerciseId: id,
      tab: ExerciseBrowseTab.progress,
    ),
    MeRoute() => const MeScreen(),
    DesignPreviewRoute() => const DesignPreviewScreen(),
    FoodSearchRoute(:final date, :final slotId, :final replace) =>
      FoodSearchScreen(date: date, slotId: slotId, replace: replace),
    NewFoodFromSearchRoute(:final date, :final slotId) =>
      PersonalFoodFormScreen(addTo: (date: date, slotId: slotId)),
    BarcodeScanRoute(:final date, :final slotId) => BarcodeScanScreen(
      date: date,
      slotId: slotId,
    ),
    NewFoodFromScanRoute(:final date, :final slotId) => PersonalFoodFormScreen(
      addTo: (date: date, slotId: slotId),
      fromScan: true,
    ),
    PersonalFoodsRoute() => const PersonalFoodsScreen(),
    PersonalFoodRoute(:final id) => PersonalFoodFormScreen(id: id),
    SavedMealsRoute() => const SavedMealsScreen(),
    SavedMealRoute(:final id) => SavedMealScreen(id: id),
    MealSlotsRoute() => const MealSlotsScreen(),
    CityPickerRoute() => const CityPickerScreen(),
    AboutRoute() => const AboutScreen(),
    NotificationSettingsRoute() => const NotificationSettingsScreen(),
    TodayWeightGraphRoute() || WeightGraphRoute() => const WeightGraphScreen(),
    WeightHistoryRoute() => const WeightHistoryScreen(),
    MeasurementsRoute() => const MeasurementsScreen(),
    MeasurementTypeRoute(:final key) => MeasurementTypeScreen(typeKey: key),
    UpdateRequiredRoute() => const UpdateRequiredScreen(),
    SetupRoute() => const SetupScreen(),
    SignInRoute() => const SignInScreen(),
    DeleteAccountRoute() => const DeleteAccountScreen(),
    ProfileRoute() => const ProfileGoalScreen(),
    TargetsRoute() => const TargetsScreen(),
  };

  @override
  void go(AppRoute route) => config.go(route.location);

  @override
  void push(AppRoute route) => unawaited(config.push<void>(route.location));

  /// Shows [location] (a notification's deep link, A40 D9); an unknown
  /// one goes to Today (the config's `onException`). Going there replaces
  /// the target tab's stack, so a screen in it with unsaved edits is asked
  /// first, like a tab re-tap (A45 D12): a dirty form asks to discard, a
  /// workout runs its visit's exit; keeping the edits cancels the link (A40
  /// review 3). Other tabs keep their stacks. A link to where the app
  /// already is does nothing; one to where a hidden tab already is just
  /// brings that tab back.
  Future<void> openLocation(String location) async {
    // Already there (e.g. a second tap on the same workout reminder): keep
    // the live screen and its visit (A40 fix-check).
    if (config.state.uri.toString() == location) return;
    final index = _tabOf(Uri.tryParse(location)?.path ?? location);
    if (index >= 0 && _tabLocations[index] == location) {
      // The target tab, hidden behind another, already shows it (a second
      // tap on the same reminder from Me): bring the tab back with its
      // live screen, never run its exit (A40 fix-check 2).
      config.go(location);
      return;
    }
    final navigator = index < 0 ? null : _branchKeys[index].currentState;
    final edits = unsavedEdits;
    if (edits != null && edits.holds(navigator)) {
      if (!await edits.confirm(navigator!)) return;
    }
    config.go(location);
  }

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
  // A new router (and navigator) per profile generation (A33 re-check 3).
  ref.watch(profileGenerationProvider);
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
    onReselect: ref.read(tabReselectProvider.notifier).fire,
    onActivate: ref.read(tabActivationProvider.notifier).fire,
    unsavedEdits: ref.read(unsavedEditsProvider),
  );
  ref.onDispose(() {
    // After the current frame's work: on a generation switch the old
    // MaterialApp (still holding this router) unmounts in the same frame.
    scheduleMicrotask(() {
      router.dispose();
      updateRequired.dispose();
    });
  });
  return router;
}
