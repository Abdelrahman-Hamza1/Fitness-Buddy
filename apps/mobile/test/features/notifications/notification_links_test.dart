import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/presentation/set_row.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';
import '../foods/presentation/support/personal_food_support.dart'
    show applyOps, settle;
import '../foods/presentation/support/search_screen_support.dart';

const _template = '01890abc-def0-7123-8abc-0123456789ab';

/// The tag of the test profile (`local`).
final String _local = NotificationScheduler.profileTagOf('local');

// Saturday weeks; the summary on Saturday 31 October opens 24–30 October.
final LocalDate _sat = LocalDate(2026, 10, 31);

NotificationCandidate _c(NotificationType type, {String? template}) =>
    NotificationCandidate(
      type: type,
      date: _sat,
      minute: 9 * 60,
      templateId: template,
    );

/// Each notification and what its tap must show (NT-024).
final _cases = <(NotificationCandidate, String, Type)>[
  (_c(NotificationType.logReminder), '/today', TodayScreen),
  (_c(NotificationType.proteinCheck), '/today', TodayScreen),
  (_c(NotificationType.pendingProposal), '/today?open=buddy', BuddySheet),
  (_c(NotificationType.weighIn), '/today?open=weigh-in', WeighInSheet),
  (
    _c(NotificationType.weeklySummary),
    '/progress/week/2026-10-24',
    WeeklySummaryScreen,
  ),
  (
    _c(NotificationType.workout, template: _template),
    '/today/workout-log?template=$_template&date=2026-10-31',
    WorkoutLogScreen,
  ),
  (_c(NotificationType.workout), '/workouts', WorkoutsScreen),
  (
    _c(NotificationType.measurement),
    '/progress/measurements',
    MeasurementsScreen,
  ),
  (_c(NotificationType.suhoor), '/today', TodayScreen),
  (_c(NotificationType.iftar), '/today', TodayScreen),
];

void main() {
  test('NT-024 every notification type links to its place', () {
    const calendar = WeekCalendar();
    expect(
      {for (final (c, _, _) in _cases) c.type},
      NotificationType.values.toSet(),
      reason: 'every type has a case',
    );
    for (final (candidate, location, _) in _cases) {
      expect(
        notificationRoute(candidate, calendar: calendar).location,
        location,
        reason: '${candidate.type}',
      );
    }
  });

  testWidgets('NT-024 each deep link opens the right screen or sheet', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      overrides: [
        searchOverride(FakeFoodSearch()),
        barcodeCameraEnabledProvider.overrideWithValue(false),
      ],
    );
    final router = container.read(appRouterProvider);
    for (final (_, location, shown) in _cases) {
      // From another tab, as a tap from the notification shade would.
      router.go(const MeRoute());
      await tester.pumpAndSettle();
      await router.openLocation(location);
      await tester.pumpAndSettle();
      expect(find.byType(shown), findsOneWidget, reason: location);
      if (shown == BuddySheet || shown == WeighInSheet) {
        // Today cleared the request: a rebuild doesn't open it again.
        expect(router.config.state.uri.toString(), TodayRoute.path);
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        expect(find.byType(shown), findsNothing, reason: '$location closed');
      }
    }
    await unmountApp(tester, container);
  });

  testWidgets('NT-024 a tap while running and the tap that started the app '
      'both open their link', (tester) async {
    final phone = TestPhone(notifications: true);
    final platform = phone.notificationPlatform
      ..launchPayload = NotificationScheduler.payloadOf(
        profileTag: _local,
        at: DateTime.utc(2026, 10, 31, 6),
        title: 't',
        body: 'b',
        location: '/progress/week/2026-10-24',
      );
    final container = await pumpApp(tester, phone: phone);
    // The bootstrap starts it after account recovery (app_bootstrap_test);
    // here directly.
    await container.read(notificationCoordinatorProvider).start();
    await tester.pumpAndSettle();
    expect(find.byType(WeeklySummaryScreen), findsOneWidget);
    expect(platform.launchPayload, isNull);

    platform.onTap!(
      NotificationScheduler.payloadOf(
        profileTag: _local,
        at: DateTime.utc(2026, 10, 31, 6),
        title: 't',
        body: 'b',
        location: '/progress/measurements',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MeasurementsScreen), findsOneWidget);

    // Not ours, or another profile's (A40 review 1): ignored.
    platform.onTap!('https://example.com');
    platform.onTap!(
      NotificationScheduler.payloadOf(
        profileTag: NotificationScheduler.profileTagOf('someone-else'),
        at: DateTime.utc(2026, 10, 31, 6),
        title: 't',
        body: 'b',
        location: '/today',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MeasurementsScreen), findsOneWidget);
    await unmountApp(tester, container);
  });

  test('A40 D9 Today reads its open parameter; an unknown one is ignored', () {
    expect(
      AppRouter.todayRouteOf(Uri.parse('/today?open=weigh-in')).open,
      TodayOpen.weighIn,
    );
    expect(AppRouter.todayRouteOf(Uri.parse('/today?open=x')).open, isNull);
    expect(
      AppRouter.weeklySummaryStartOf(Uri.parse('/progress/week/x')),
      isNull,
    );
    expect(
      AppRouter.weeklySummaryStartOf(Uri.parse('/progress/week/2026-10-24')),
      LocalDate(2026, 10, 24),
    );
  });

  testWidgets('A40 review 3 a link into a tab with a dirty form asks first: '
      'keep editing cancels the link, discard follows it', (tester) async {
    final container = await pumpApp(
      tester,
      overrides: [
        searchOverride(FakeFoodSearch()),
        barcodeCameraEnabledProvider.overrideWithValue(false),
      ],
    );
    final router = container.read(appRouterProvider)
      ..go(const NewFoodFromSearchRoute());
    await settle(tester);
    await tester.enterText(
      find
          .descendant(
            of: find.byType(PersonalFoodFormScreen),
            matching: find.byType(TextField),
          )
          .first,
      'Draft',
    );
    await tester.pump();
    Finder sheetButton(int index) => find
        .descendant(of: find.byType(FbSheet), matching: find.byType(FbButton))
        .at(index);

    unawaited(router.openLocation('/today'));
    await settle(tester);
    expect(find.byType(FbSheet), findsOneWidget);
    await tester.tap(sheetButton(0)); // keep editing
    await settle(tester);
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);

    unawaited(router.openLocation('/today'));
    await settle(tester);
    await tester.tap(sheetButton(1)); // discard
    await settle(tester);
    expect(router.config.state.matchedLocation, TodayRoute.path);
    expect(
      find.byType(PersonalFoodFormScreen, skipOffstage: false),
      findsNothing,
    );
    await unmountApp(tester, container);
  });

  testWidgets("A40 review 3 a link into Workouts runs an open workout's "
      'visit exit first (edits saved, visit finished)', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);
    const exercise = '0199e3c2-0000-7000-8000-000000000001';
    await applyOps(tester, container, [
      CreateCustomExercise(
        exercise,
        CustomExerciseDraft(
          name: 'Cable fly',
          type: ExerciseType.weightReps,
          equipment: Equipment.cable,
          primaryMuscle: Muscle.chest,
        ),
      ),
    ]);
    router.go(const WorkoutLogRoute(exercises: [exercise]));
    await settle(tester);
    final fields = find.descendant(
      of: find.byType(SetRow),
      matching: find.byType(EditableText),
    );
    await tester.enterText(fields.at(0), '80');
    await tester.enterText(fields.at(1), '8');
    await tester.tap(
      find.descendant(of: find.byType(SetRow), matching: find.byType(Checkbox)),
    );
    await tester.pump();

    unawaited(router.openLocation('/workouts'));
    await settle(tester);
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    final sessions = await tester.runAsync(
      () =>
          WorkoutRepository(container.read(appDatabaseProvider)).allSessions(),
    );
    expect(
      sessions!.single.draft.exercises.single.sets.single.values,
      const SetValues(reps: 8, kg: 80),
    );
    await unmountApp(tester, container);
  });

  testWidgets('A40 review 4 a summary link shows its week even when the '
      'summary screen is already open on another week', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);
    final today = container.read(clockProvider).nowUtc();
    final current = const WeekCalendar().weekStartOf(
      LocalDate(today.year, today.month, today.day),
    );
    final lastWeek = current.plusDays(-7);
    Finder block(LocalDate start) =>
        find.byKey(ValueKey('weekly-summary-$start'));

    await router.openLocation(WeeklySummaryRoute(start: lastWeek).location);
    await tester.pumpAndSettle();
    expect(block(lastWeek), findsOneWidget);
    // Browse to this week with ›, then the same link again.
    await tester.tap(find.byKey(const ValueKey('weekly-summary-next')));
    await tester.pumpAndSettle();
    expect(block(current), findsOneWidget);
    await router.openLocation(WeeklySummaryRoute(start: lastWeek).location);
    await tester.pumpAndSettle();
    expect(block(lastWeek), findsOneWidget);
    expect(block(current), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('A40 fix-check the same workout link keeps the live visit; a '
      'different one finishes it and opens a fresh screen', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);
    const exercise = '0199e3c2-0000-7000-8000-000000000001';
    await applyOps(tester, container, [
      CreateCustomExercise(
        exercise,
        CustomExerciseDraft(
          name: 'Cable fly',
          type: ExerciseType.weightReps,
          equipment: Equipment.cable,
          primaryMuscle: Muscle.chest,
        ),
      ),
    ]);
    final first = const WorkoutLogRoute(exercises: [exercise]).location;
    await router.openLocation(first);
    await settle(tester);
    final live = tester.state(find.byType(WorkoutLogScreen));
    final fields = find.descendant(
      of: find.byType(SetRow),
      matching: find.byType(EditableText),
    );
    await tester.enterText(fields.at(0), '80');
    await tester.enterText(fields.at(1), '8');
    await tester.tap(
      find.descendant(of: find.byType(SetRow), matching: find.byType(Checkbox)),
    );
    await tester.pump();

    // The same link again: nothing happens to the open visit.
    await router.openLocation(first);
    await settle(tester);
    expect(tester.state(find.byType(WorkoutLogScreen)), same(live));
    // The visit is still open: its exit (and its one Undo) hasn't run.
    expect(container.read(undoStackProvider).latest, isNull);

    // Another visit (yesterday's): the open one runs its exit, then a new
    // screen with its own state, not the finished one.
    final today = container.read(clockProvider).nowUtc();
    final other = WorkoutLogRoute(
      exercises: const [exercise],
      date: LocalDate(today.year, today.month, today.day).plusDays(-1),
    ).location;
    unawaited(router.openLocation(other));
    await settle(tester);
    expect(router.config.state.uri.toString(), other);
    final fresh = tester.state(find.byType(WorkoutLogScreen));
    expect(fresh, isNot(same(live)));
    expect(container.read(undoStackProvider).latest, isNotNull);
    // The fresh visit takes edits.
    await tester.enterText(fields.at(0), '60');
    await tester.pump();
    expect(tester.widget<EditableText>(fields.at(0)).controller.text, '60');
    await unmountApp(tester, container);
  });

  testWidgets('A40 fix-check 2 the same workout link while its tab is hidden '
      'brings the live visit back, without finishing it', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);
    const exercise = '0199e3c2-0000-7000-8000-000000000001';
    await applyOps(tester, container, [
      CreateCustomExercise(
        exercise,
        CustomExerciseDraft(
          name: 'Cable fly',
          type: ExerciseType.weightReps,
          equipment: Equipment.cable,
          primaryMuscle: Muscle.chest,
        ),
      ),
    ]);
    final link = const WorkoutLogRoute(exercises: [exercise]).location;
    await router.openLocation(link);
    await settle(tester);
    final live = tester.state(find.byType(WorkoutLogScreen));
    final fields = find.descendant(
      of: find.byType(SetRow),
      matching: find.byType(EditableText),
    );
    await tester.enterText(fields.at(0), '80');
    await tester.enterText(fields.at(1), '8');
    await tester.tap(
      find.descendant(of: find.byType(SetRow), matching: find.byType(Checkbox)),
    );
    await tester.pump();

    // Switch to Me, then the same reminder again.
    router.go(const MeRoute());
    await settle(tester);
    await router.openLocation(link);
    await settle(tester);
    expect(router.config.state.uri.toString(), link);
    expect(tester.state(find.byType(WorkoutLogScreen)), same(live));
    // Not finished: no exit ran (its one Undo), and edits still save.
    expect(container.read(undoStackProvider).latest, isNull);
    await tester.enterText(fields.at(0), '82.5');
    await settle(tester);
    expect(tester.widget<EditableText>(fields.at(0)).controller.text, '82.5');
    // Leaving through Workouts' re-tap path still finishes it once.
    await router.openLocation('/workouts');
    await settle(tester);
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(container.read(undoStackProvider).latest, isNotNull);
    final sessions = await tester.runAsync(
      () =>
          WorkoutRepository(container.read(appDatabaseProvider)).allSessions(),
    );
    expect(
      sessions!.single.draft.exercises.single.sets.single.values,
      const SetValues(reps: 8, kg: 82.5),
    );
    await unmountApp(tester, container);
  });
}
