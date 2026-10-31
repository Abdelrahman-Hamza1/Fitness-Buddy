import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart' show FbListRow;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart' show ManualClock;
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:fb_mobile/features/design_preview/design_preview.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/progress/application/ramadan_comparison_provider.dart';
import 'package:fb_mobile/features/progress/presentation/ramadan_comparison_card.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' show GoRoute, GoRouter, RouteBase;
import 'package:material_ui/material_ui.dart';

import '../../features/body/support/measurement_harness.dart'
    show mId, measureDraft;
import '../../features/diary/support/diary_fixtures.dart' show fixtureId;
import '../../features/diary/support/diary_harness.dart' show atDay, newEntry;
import '../../features/foods/presentation/support/personal_food_support.dart'
    show aFood, applyOps, settle;
import '../../features/foods/presentation/support/search_screen_support.dart';
import '../../features/onboarding/setup_support.dart' show SetupRun, openSetup;
import '../../features/targets/application/targets_app_harness.dart'
    show setupInput;
import '../../features/workouts/support/workout_harness.dart'
    show benchDraft, lifted, sessionDraft, wid;
import '../../helpers/pump_app.dart';

/// The IDs of what [seedProfile] wrote.
final class SeededProfile {
  new(this.today);

  /// The app's local day when the profile was seeded.
  final LocalDate today;

  /// The custom exercise.
  final String exercise = wid(1);

  /// Yesterday's workout session.
  final String session = wid(10);

  /// The workout template.
  final String template = wid(70);

  /// The saved meal.
  final String savedMeal = fixtureId(990);

  /// The personal food.
  final String personalFood = aFood(1).id;
}

/// The overrides every acceptance test runs with: no food pack (a stubbed
/// search) and no camera (the scan screen's typed-code path).
List<Override> acceptanceOverrides() => [
  searchOverride(FakeFoodSearch()),
  barcodeCameraEnabledProvider.overrideWithValue(false),
];

/// The change sets of a realistic profile, in order: a profile,
/// goal and targets; 3 entries a day for the last 30 days and 5 today in
/// several meals; a saved meal; a personal food; 31 daily weigh-ins; a
/// waist measurement; a custom exercise, two sessions and a template.
/// [historyDays] (≤ 290) lengthens the diary history and [extraSessions]
/// (≤ 300) adds older workouts, for benchmarks that need long lists.
List<List<ChangeOp>> profileSeed(
  SeededProfile seeded, {
  int historyDays = 30,
  int extraSessions = 0,
}) {
  assert(historyDays <= 290 && extraSessions <= 300, 'ID ranges');
  final today = seeded.today;
  final first = today.plusDays(-30);
  final batches = <List<ChangeOp>>[];
  void apply(List<ChangeOp> ops) => batches.add(ops);

  apply([
    PutProfile(setupInput().profile),
    PutGoalPhase(
      GoalPhaseRecord(
        id: fixtureId(980),
        revision: 1,
        start: first,
        type: GoalType.lose,
        expression: GoalExpression.targetRate(80, .5),
        weightInputUnit: MassUnit.kilogram,
      ),
    ),
    PutTargetSettings(
      TargetSettingsRecord(
        id: fixtureId(981),
        revision: 1,
        effectiveFrom: first,
        baseKcal: 2200,
        basisWeightKg: 86,
      ),
    ),
  ]);
  const slots = [
    DefaultSlots.breakfastId,
    DefaultSlots.lunchId,
    DefaultSlots.dinnerId,
  ];
  apply([
    LogEntries([
      for (var d = 1; d <= historyDays; d++)
        for (var s = 0; s < 3; s++)
          newEntry(
            d * 3 + s,
            when: atDay(today.plusDays(-d), 8 + s * 5),
            slotId: slots[s],
            kcal: 150 + (d * 37 + s * 11) % 150,
          ),
    ]),
  ]);
  apply([
    LogEntries([
      for (var n = 0; n < 5; n++)
        newEntry(
          900 + n,
          when: atDay(today, 8 + n * 2),
          slotId: slots[n % 3],
          kcal: 120 + n * 40,
        ),
    ]),
  ]);
  apply([
    SaveMeal(
      savedMealId: seeded.savedMeal,
      name: 'Usual breakfast',
      source: MealSource.entries([fixtureId(900), fixtureId(903)]),
      expected: SourceVersions(
        entries: [
          VersionedId(fixtureId(900), 1),
          VersionedId(fixtureId(903), 1),
        ],
      ),
    ),
  ]);
  apply([CreatePersonalFood(aFood(1).id, aFood(1).draft)]);
  apply([
    for (var d = 0; d < 30; d++)
      CreateWeighIn(
        fixtureId(700 + d),
        WeighInDraft(
          time: EntryTime.local(LocalDateTime(first.plusDays(d), hour: 7), 0),
          input: WeighInInput(
            ((88 - d * 0.05 + (d % 4) * 0.2) * 10).roundToDouble() / 10,
            MassUnit.kilogram,
          ),
        ),
      ),
    // Today's, at midnight (never in the future), so Today shows the slim
    // weight row.
    CreateWeighIn(
      fixtureId(730),
      WeighInDraft(
        time: EntryTime.local(LocalDateTime(today), 0),
        input: const WeighInInput(86.4, MassUnit.kilogram),
      ),
    ),
    CreateMeasurement(mId(1), measureDraft(92, date: today.plusDays(-3))),
  ]);
  apply([
    CreateCustomExercise(seeded.exercise, benchDraft()),
    LogWorkoutSession(
      wid(11),
      sessionDraft(date: today.plusDays(-4), exerciseRow: 21),
    ),
    LogWorkoutSession(
      seeded.session,
      sessionDraft(
        date: today.plusDays(-1),
        sets: [lifted(40, 8, 82.5), lifted(41, 8, 82.5), lifted(42, 6, 85)],
      ),
    ),
    for (var i = 0; i < extraSessions; i++)
      LogWorkoutSession(
        wid(1000 + i),
        sessionDraft(
          date: today.plusDays(-5 - i),
          exerciseRow: 2000 + i,
          sets: [
            for (var k = 0; k < 3; k++) lifted(3000 + i * 3 + k, 8, 60 + k * 5),
          ],
        ),
      ),
    CreateWorkoutTemplate(
      seeded.template,
      WorkoutTemplateDraft(
        name: 'Push day',
        items: [
          TemplateItemDraft(
            id: wid(71),
            exerciseId: seeded.exercise,
            sets: 3,
            reps: 10,
          ),
        ],
      ),
    ),
  ]);
  return batches;
}

/// Seeds [profileSeed] through the app's single writer.
Future<SeededProfile> seedProfile(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final today = EntryTime.now(container.read(clockProvider)).localDate;
  final seeded = SeededProfile(today);
  for (final ops in profileSeed(seeded)) {
    final result = await applyOps(tester, container, ops);
    expect(result.toString(), startsWith('Applied'), reason: '$ops');
  }
  await settle(tester);
  return seeded;
}

/// Every routed screen a user can reach on a set-up profile, with the IDs
/// of [s]. Setup is reached on an unconfigured profile instead
/// ([visitSetupPages]): a set-up profile closes it. The dev-only design
/// preview is left out; the update screen is shown through its gate
/// (`showRoute`). [visitEveryRoute] fails when this list misses a route the
/// router registers, or lists one twice.
List<AppRoute> everyRoute(SeededProfile s) => [
  const TodayRoute(),
  const ProgressRoute(),
  WeeklySummaryRoute(start: s.today.plusDays(-7)),
  const NotificationSettingsRoute(),
  const WorkoutsRoute(),
  const WorkoutLogRoute(),
  WorkoutSessionRoute(id: s.session),
  const WorkoutHistoryRoute(),
  const WorkoutPlanRoute(),
  const WorkoutStarterPlansRoute(),
  const WorkoutExercisesRoute(),
  WorkoutExerciseRoute(s.exercise),
  const ProgressExercisesRoute(),
  ProgressExerciseRoute(s.exercise),
  TodayWorkoutSessionRoute(id: s.session),
  TodayWorkoutLogRoute(template: s.template),
  const MeRoute(),
  const FoodSearchRoute(),
  const NewFoodFromSearchRoute(),
  const BarcodeScanRoute(),
  const NewFoodFromScanRoute(),
  const PersonalFoodsRoute(),
  PersonalFoodRoute(id: s.personalFood),
  const PersonalFoodRoute(),
  const SavedMealsRoute(),
  SavedMealRoute(id: s.savedMeal),
  const MealSlotsRoute(),
  const RamadanRoute(),
  const RamadanMealSlotsRoute(),
  const CityPickerRoute(),
  const AboutRoute(),
  const TodayWeightGraphRoute(),
  const WeightGraphRoute(),
  const WeightHistoryRoute(),
  const MeasurementsRoute(),
  const MeasurementTypeRoute('waist'),
  const ProfileRoute(),
  const TargetsRoute(),
  const SignInRoute(),
  const DeleteAccountRoute(),
  const UpdateRequiredRoute(),
];

/// The screen [route] must show. The exhaustive switch makes this file fail
/// to compile when a route type is added.
Type screenOf(AppRoute route) => switch (route) {
  TodayRoute() => TodayScreen,
  ProgressRoute() => ProgressScreen,
  WeeklySummaryRoute() => WeeklySummaryScreen,
  NotificationSettingsRoute() => NotificationSettingsScreen,
  WorkoutsRoute() => WorkoutsScreen,
  WorkoutLogRoute() => WorkoutLogScreen,
  WorkoutSessionRoute() => WorkoutLogScreen,
  WorkoutHistoryRoute() => WorkoutHistoryScreen,
  WorkoutPlanRoute() => WeeklyPlanScreen,
  WorkoutStarterPlansRoute() => StarterPlansScreen,
  WorkoutExercisesRoute() => ExercisePickerScreen,
  WorkoutExerciseRoute() => ExerciseScreen,
  ProgressExercisesRoute() => ExercisePickerScreen,
  ProgressExerciseRoute() => ExerciseScreen,
  TodayWorkoutSessionRoute() => WorkoutLogScreen,
  TodayWorkoutLogRoute() => WorkoutLogScreen,
  MeRoute() => MeScreen,
  DesignPreviewRoute() => DesignPreviewScreen,
  FoodSearchRoute() => FoodSearchScreen,
  NewFoodFromSearchRoute() => PersonalFoodFormScreen,
  BarcodeScanRoute() => BarcodeScanScreen,
  NewFoodFromScanRoute() => PersonalFoodFormScreen,
  PersonalFoodsRoute() => PersonalFoodsScreen,
  PersonalFoodRoute() => PersonalFoodFormScreen,
  SavedMealsRoute() => SavedMealsScreen,
  SavedMealRoute() => SavedMealScreen,
  MealSlotsRoute() => MealSlotsScreen,
  RamadanRoute() => RamadanScreen,
  RamadanMealSlotsRoute() => MealSlotsScreen,
  CityPickerRoute() => CityPickerScreen,
  AboutRoute() => AboutScreen,
  TodayWeightGraphRoute() => WeightGraphScreen,
  WeightGraphRoute() => WeightGraphScreen,
  WeightHistoryRoute() => WeightHistoryScreen,
  MeasurementsRoute() => MeasurementsScreen,
  MeasurementTypeRoute() => MeasurementTypeScreen,
  UpdateRequiredRoute() => UpdateRequiredScreen,
  SetupRoute() => SetupScreen,
  SignInRoute() => SignInScreen,
  DeleteAccountRoute() => DeleteAccountScreen,
  ProfileRoute() => ProfileGoalScreen,
  TargetsRoute() => TargetsScreen,
};

/// Every screen path the router registers (full path templates), from its
/// route tree: the authority [everyRoute] is checked against.
Set<String> registeredPaths(GoRouter router) {
  final paths = <String>{};
  void walk(List<RouteBase> routes, String parent) {
    for (final route in routes) {
      var base = parent;
      if (route is GoRoute) {
        base = route.path.startsWith('/')
            ? route.path
            : '${parent == '/' ? '' : parent}/${route.path}';
        paths.add(base);
      }
      walk(route.routes, base);
    }
  }

  walk(router.configuration.routes, '/');
  return paths;
}

/// The paths the route sweep doesn't visit on a set-up profile: setup
/// ([visitSetupPages] covers it) and the dev-only design preview.
final Set<String> _notInRouteSweep = {
  SetupRoute.path,
  const DesignPreviewRoute().location,
};

/// Calls [check] on the screen as it is, then scrolls every vertical list of
/// [within] through its whole length, a little less than a screen at a time
/// (so lazy items are built and laid out), calling [check] at each stop, and
/// back to the top.
Future<void> scrollThrough(
  WidgetTester tester,
  Finder within,
  Future<void> Function(String where) check,
) async {
  await check('top');
  final lists = find
      .descendant(
        of: within,
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      )
      .evaluate()
      .toList();
  for (final (i, element) in lists.indexed) {
    if (!element.mounted) continue;
    final state = (element as StatefulElement).state as ScrollableState;
    var stops = 0;
    while (state.mounted &&
        state.position.hasContentDimensions &&
        state.position.pixels < state.position.maxScrollExtent &&
        stops < 40) {
      final position = state.position;
      position.jumpTo(
        (position.pixels + position.viewportDimension * 0.8).clamp(
          0,
          position.maxScrollExtent,
        ),
      );
      await settle(tester);
      stops++;
      await check('list $i at ${state.position.pixels.round()} px');
    }
    if (state.mounted && state.position.pixels > 0) {
      state.position.jumpTo(0);
      await settle(tester);
    }
  }
}

/// Visits every route of [everyRoute] in the app of [container]: shows it,
/// requires its screen, then scrolls it through ([scrollThrough]), calling
/// [check] at each stop. Fails when a route the router registers isn't
/// visited, or one is visited twice. Leaves the app on Today.
Future<void> visitEveryRoute(
  WidgetTester tester,
  ProviderContainer container,
  SeededProfile seeded,
  Future<void> Function(String where) check,
) async {
  final router = container.read(appRouterProvider).config;
  final visited = <String>[];
  for (final route in everyRoute(seeded)) {
    final name = route is PersonalFoodRoute && route.id == null
        ? 'NewPersonalFoodRoute'
        : '${route.runtimeType}';
    showRoute(container, route);
    await settle(tester);
    final screen = find.byType(screenOf(route));
    expect(screen, findsOneWidget, reason: '$name shows its screen');
    visited.add(router.state.fullPath ?? '?');
    await scrollThrough(tester, screen, (step) => check('$name $step'));
  }
  expect(
    visited.toSet().length,
    visited.length,
    reason: 'a route is visited twice: $visited',
  );
  expect(
    registeredPaths(router).difference(_notInRouteSweep),
    visited.toSet(),
    reason: 'everyRoute must visit every registered screen path',
  );
  showRoute(container, const TodayRoute());
  await settle(tester);
}

/// Today's page of [date].
Finder dayPage(LocalDate date) => find.byKey(ValueKey<LocalDate>(date));

/// Opens every meal on [date]'s Today page. Its list is lazy, so the meals
/// are opened while scrolling down to them; the list ends back at the top.
/// Returns how many were opened.
Future<int> openTodayMeals(WidgetTester tester, LocalDate date) async {
  final page = dayPage(date);
  final list = tester.state<ScrollableState>(
    find
        .descendant(
          of: page,
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  final opened = <String>{};
  for (var stop = 0; stop < 40; stop++) {
    final keys = [
      for (final tile in tester.widgetList<SlotHeaderTile>(
        find.descendant(of: page, matching: find.byType(SlotHeaderTile)),
      ))
        tile.section.key,
    ];
    for (final key in keys) {
      if (!opened.add(key)) continue;
      final header = find.descendant(
        of: page,
        matching: find.byWidgetPredicate(
          (w) => w is SlotHeaderTile && w.section.key == key,
        ),
      );
      // An earlier meal opening can push this one out of the built range;
      // it is opened when the scroll reaches it again.
      if (header.evaluate().isEmpty) {
        opened.remove(key);
        continue;
      }
      await tester.ensureVisible(header);
      await settle(tester);
      await tester.tap(header);
      await settle(tester);
    }
    final position = list.position;
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      (position.pixels + position.viewportDimension * 0.6).clamp(
        0,
        position.maxScrollExtent,
      ),
    );
    await settle(tester);
  }
  list.position.jumpTo(0);
  await settle(tester);
  return opened.length;
}

/// The states that aren't routes, from Today: every meal of today expanded
/// with one entry's details open, Buddy's chat sheet and the weigh-in sheet.
/// Each is checked and scrolled through, then closed.
Future<void> visitStates(
  WidgetTester tester,
  SeededProfile seeded,
  Future<void> Function(String where) check,
) async {
  // A snackbar from an earlier route would cover the input bar.
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
      .clearSnackBars();
  await settle(tester);

  // Today with every meal open and an entry's details shown.
  final page = dayPage(seeded.today);
  final opened = await openTodayMeals(tester, seeded.today);
  expect(opened, greaterThanOrEqualTo(3), reason: "today's meals");
  final list = tester.state<ScrollableState>(
    find
        .descendant(
          of: page,
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  final row = find.descendant(
    of: page,
    matching: find.widgetWithText(FbListRow, 'Food 900'),
  );
  await tester.scrollUntilVisible(
    row,
    100,
    scrollable: find.byWidget(list.widget),
  );
  await settle(tester);
  await tester.tap(row.first);
  await settle(tester);
  await scrollThrough(
    tester,
    find.byType(TodayScreen),
    (step) => check('Today expanded $step'),
  );

  // The input bar sits below the day pages, on the Today screen.
  final input = find.textContaining('Tell Buddy');
  expect(input, findsWidgets, reason: "Today's input bar");
  await tester.tap(input.first);
  await settle(tester);
  expect(find.byType(BuddySheet), findsOneWidget);
  await scrollThrough(
    tester,
    find.byType(BuddySheet),
    (step) => check('Buddy sheet $step'),
  );
  await tester.binding.handlePopRoute();
  await settle(tester);
  final add = find.descendant(
    of: find.descendant(of: page, matching: find.byType(WeightCard)),
    matching: find.byKey(WeightCard.slimAddKey),
  );
  expect(add, findsOneWidget, reason: "the weight row's plus");
  await tester.ensureVisible(add);
  await settle(tester);
  await tester.tap(add);
  await settle(tester);
  expect(find.byType(WeighInSheet), findsOneWidget);
  await scrollThrough(
    tester,
    find.byType(WeighInSheet),
    (step) => check('weigh-in sheet $step'),
  );
  await tester.binding.handlePopRoute();
  await settle(tester);
}

/// Setup's pages on a fresh, unconfigured profile (a set-up one closes
/// setup): each page required, checked and scrolled through, then the next
/// with the minimal answers, up to "Your targets". [overrides] as for the
/// route sweep (theme).
Future<void> visitSetupPages(
  WidgetTester tester,
  List<Override> overrides,
  Future<void> Function(String where) check,
) async {
  final container = await openSetup(tester, overrides: overrides);
  final run = SetupRun(tester);
  Future<void> page(int n) async {
    final screen = find.byType(SetupScreen);
    expect(screen, findsOneWidget, reason: 'setup page $n');
    await scrollThrough(tester, screen, (step) => check('Setup $n $step'));
  }

  await page(1);
  await run.you();
  await page(1);
  await run.next();
  await page(2);
  await run.tap('Moderately active');
  await run.next();
  await page(3);
  await run.tap('Lose weight');
  await run.next();
  await page(4);
  await run.next();
  await page(5);
  expect(find.text('Save'), findsOneWidget, reason: 'the last page');
  await unmountApp(tester, container);
}

/// Waits for [work], started in the test's zone, letting both real time
/// (the database) and the test's clock (the app's own timers) run.
Future<T> _finish<T>(WidgetTester tester, Future<T> work) async {
  var done = false;
  unawaited(work.whenComplete(() => done = true));
  for (var i = 0; i < 200 && !done; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done, isTrue, reason: 'the work finished');
  return await work;
}

/// Ramadan 1448 (Umm al-Qura): Mon 2027-02-08 … Mon 2027-03-08.
final LocalDate _ramadanDay = LocalDate(2027, 2, 15);

/// Ramadan's screens and states (A41a) on a seeded profile whose clock is a
/// day of Ramadan 1448 with the mode on: Today with the Ramadan meals (all
/// opened), then with the day marked not fasting; Settings › Ramadan; the
/// Ramadan meal times; Progress with the Ramadan comparison card; Targets.
/// Each is required, checked and scrolled through. [overrides] as for the
/// route sweep (theme).
Future<void> visitRamadan(
  WidgetTester tester,
  List<Override> overrides,
  Future<void> Function(String where) check,
) async {
  // Midday in Palestine (UTC+2 in winter).
  final clock = ManualClock(
    DateTime.utc(_ramadanDay.year, _ramadanDay.month, _ramadanDay.day, 10),
    offsetMinutes: 120,
  );
  useAcceptanceWindow(tester);
  final container = await pumpApp(
    tester,
    overrides: [
      ...overrides,
      clockProvider.overrideWithValue(clock),
      // The real decisions, not the test default (`ramadanOff`).
      ramadanSettingsProvider.overrideWith(
        (ref) =>
            ref.watch(settingsStoreProvider).watch(AppSettings.ramadanSeasons),
      ),
    ],
  );
  final seeded = await seedProfile(tester, container);
  expect(seeded.today, _ramadanDay);
  final actions = container.read(settingsActionsProvider);
  final turnedOn = await _finish(
    tester,
    actions.setRamadanSeason(RamadanSeason(hijriYear: 1448, on: true)),
  );
  expect(turnedOn, isA<SettingsDone>(), reason: 'Ramadan mode on');
  await settle(tester);
  Future<void> route(AppRoute route, String name) async {
    showRoute(container, route);
    await settle(tester);
    final screen = find.byType(screenOf(route));
    expect(screen, findsOneWidget, reason: name);
    await scrollThrough(tester, screen, (step) => check('$name $step'));
  }

  await route(const TodayRoute(), 'Ramadan Today');
  final slots = await _finish(
    tester,
    container.read(daySlotsProvider(_ramadanDay).future),
  );
  expect(slots.ramadan, isNotNull, reason: 'a Ramadan day');
  expect(slots.mode, SlotMode.ramadan);
  expect(await openTodayMeals(tester, _ramadanDay), greaterThanOrEqualTo(2));
  await scrollThrough(
    tester,
    find.byType(TodayScreen),
    (step) => check('Ramadan Today meals open $step'),
  );
  final notFasting = await _finish(
    tester,
    actions.setNotFasting(_ramadanDay, notFasting: true),
  );
  expect(notFasting, isA<SettingsDone>(), reason: 'marked not fasting');
  await settle(tester);
  final marked = await _finish(
    tester,
    container.read(daySlotsProvider(_ramadanDay).future),
  );
  expect(marked.notFasting, isTrue);
  await route(const TodayRoute(), 'Ramadan Today not fasting');
  await route(const RamadanRoute(), 'RamadanRoute');
  await route(const RamadanMealSlotsRoute(), 'RamadanMealSlotsRoute');
  await route(const ProgressRoute(), 'Ramadan Progress');
  final keep = container.listen(ramadanComparisonProvider, (_, _) {});
  final comparison = await _finish(
    tester,
    container.read(ramadanComparisonProvider.future),
  );
  keep.close();
  expect(comparison, isNotNull, reason: 'the Ramadan comparison has data');
  await tester.scrollUntilVisible(
    find.byType(RamadanComparisonCard),
    200,
    scrollable: find
        .descendant(
          of: find.byType(ProgressScreen),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await settle(tester);
  await check('Ramadan comparison card');
  await route(const TargetsRoute(), 'Ramadan Targets');
  await unmountApp(tester, container);
}

/// The sweep's phone size: 360 × 800 dp, narrower than the A55.
void useAcceptanceWindow(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
