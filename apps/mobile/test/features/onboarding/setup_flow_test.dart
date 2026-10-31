import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';
import 'setup_support.dart';

SetupDraft _draft(ProviderContainer c, [SetupMode mode = SetupMode.setup]) =>
    c.read(setupFlowProvider(mode)).value!;

Future<T> _db<T>(WidgetTester tester, Future<T> Function() read) async =>
    (await tester.runAsync(read)) as T;

Future<TargetsData> _targets(WidgetTester tester, ProviderContainer c) =>
    _db(tester, () => TargetsRepository(c.read(appDatabaseProvider)).read());

void main() {
  testWidgets("UX-060 UX-052 Continue stays on the page until the page's "
      "answers are complete, then says what's missing; Back keeps every "
      'answer; the bar counts the pages of the run', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    // Goal, about you, activity, training, plan (no account step here).
    expect(_draft(c).pages, hasLength(5));
    expect(find.text('What brings you here?'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 5'), findsOneWidget);
    // Continue is always on (UX-052); empty, it names what's missing.
    expect(button(tester, 'Continue').onPressed, isNotNull);
    await run.next();
    expect(find.text('What brings you here?'), findsOneWidget);
    expect(find.text('Choose one to continue.'), findsOneWidget);
    await run.tap('Lose weight');
    await run.next();

    expect(find.text('A bit about you'), findsOneWidget);
    expect(find.text('Choose one to continue.'), findsNothing);
    await run.next();
    expect(find.text('A bit about you'), findsOneWidget);
    expect(_draft(c).firstProblem, SetupField.sex);
    await run.you();
    await run.enter('Current weight', '600');
    await run.next();
    expect(find.text('A bit about you'), findsOneWidget, reason: 'range');
    expect(find.textContaining('Enter a weight between'), findsOneWidget);
    await run.enter('Current weight', '80');
    await run.next();

    expect(find.text('How active are you?'), findsOneWidget);
    await run.tap('Moderately active');
    await run.next();
    expect(find.text('Do you work out?'), findsOneWidget);
    await run.next();
    expect(find.text('Choose one to continue.'), findsOneWidget);
    await run.tap('Yes, I mix it up');

    // Back three times: everything answered is still there.
    for (var i = 0; i < 3; i++) {
      await run.back();
    }
    expect(find.text('What brings you here?'), findsOneWidget);
    final draft = _draft(c);
    expect(draft.goal.type, GoalType.lose);
    expect(draft.birthYear, '1990');
    expect(draft.activity, ActivityLevel.moderate);
    expect(draft.training, TrainingChoice.mixItUp);
    await run.next();
    expect(find.text('1990'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 "Looks good" writes once, returns to Today with '
      '"Targets set" and Undo; Undo brings back the setup row and removes '
      'the first weigh-in', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.toPlan();
    expect(find.text("Here's your plan"), findsOneWidget);
    expect(find.text('kcal a day'), findsOneWidget);
    // The explanation is there on demand.
    expect(find.textContaining('Your energy use'), findsNothing);
    await run.tap('How is this worked out?');
    expect(find.byType(TargetExplanationView), findsOneWidget);
    await run.next('Looks good');
    await settleWrites(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(SetupScreen), findsNothing);
    expect(find.text('Targets set'), findsOneWidget);
    expect(find.text('kcal left today'), findsOneWidget);
    expect(find.text('Set up your targets'), findsNothing);
    final db = c.read(appDatabaseProvider);
    final weighIns = await _db(
      tester,
      () => WeighInRepository(db).watchLive().first,
    );
    expect(weighIns.single.input, const WeighInInput(80, MassUnit.kilogram));
    var data = await _targets(tester, c);
    expect(
      (data.profile != null, data.phases.length, data.settings.length),
      (true, 1, 1),
    );

    await tester.tap(find.text('Undo'));
    await settleWrites(tester);
    expect(find.text('Set up your targets'), findsOneWidget);
    data = await _targets(tester, c);
    expect(data.profile, isNull);
    expect(data.settings, isEmpty);
    expect(
      await _db(tester, () => WeighInRepository(db).watchLive().first),
      isEmpty,
    );
    await unmountApp(tester, c);
  });

  testWidgets('D-088 "Just see what I eat" skips the body questions and '
      'writes nothing; "I want a plan" opens the starter plans', (
    tester,
  ) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.tap('Just see what I eat');
    // Goal and training only: no body questions, no plan.
    expect(_draft(c).pages, [SetupPage.goal, SetupPage.training]);
    await run.next();
    expect(find.text('Do you work out?'), findsOneWidget);
    await run.tap('Yes, I want a plan');
    await run.next();
    await settleWrites(tester);
    expect(find.byType(StarterPlansScreen), findsOneWidget);
    final data = await _targets(tester, c);
    expect(data.profile, isNull);
    expect(data.settings, isEmpty);
    await unmountApp(tester, c);
  });

  testWidgets('D-088 a skipped training question opens Today even after '
      '"I want a plan" was picked', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.tap('Just see what I eat');
    await run.next();
    await run.tap('Yes, I want a plan');
    await run.tap('Skip');
    await settleWrites(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(StarterPlansScreen), findsNothing);
    await unmountApp(tester, c);
  });

  testWidgets('D-088 a skipped question means no plan and no targets: Today '
      'keeps "Set up your targets"', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.tap('Keep my weight');
    await run.next();
    await run.enter('Birth year', '1990');
    await run.tap('Skip');
    expect(find.text('How active are you?'), findsOneWidget);
    expect(_draft(c).pages, isNot(contains(SetupPage.plan)));
    await run.tap('Skip');
    await run.tap('Not right now');
    await run.next();
    await settleWrites(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Set up your targets'), findsOneWidget);
    expect((await _targets(tester, c)).profile, isNull);
    await unmountApp(tester, c);
  });

  testWidgets('D-088 "Change the numbers" changes the plan in place', (
    tester,
  ) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.toPlan();
    final before = _draft(c).preview!.calculation!.kcal;
    await run.tap('Change the numbers');
    await run.tap('Lightly active');
    await run.tap('Done');
    expect(find.text("Here's your plan"), findsOneWidget);
    expect(_draft(c).activity, ActivityLevel.light);
    expect(_draft(c).preview!.calculation!.kcal, lessThan(before));
    await unmountApp(tester, c);
  });

  testWidgets("UX-052 closing with an answer asks first; closing empty doesn't "
      'ask', (tester) async {
    var c = await openSetup(tester);
    await tester.tap(find.byTooltip('Close setup'));
    await tester.pumpAndSettle();
    expect(find.text('Leave setup?'), findsNothing);
    expect(find.byType(SetupScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    await unmountApp(tester, c);

    c = await openSetup(tester);
    await SetupRun(tester).tap('Gain weight or muscle');
    await tester.tap(find.byTooltip('Close setup'));
    await tester.pumpAndSettle();
    expect(find.text('Leave setup?'), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Close setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsNothing);
    expect((await _targets(tester, c)).profile, isNull);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 offline: setup completes with the API client throwing '
      'on every call', (tester) async {
    final phone = TestPhone();
    final c = await openSetup(tester, phone: phone);
    final before = phone.adapter.requests.length;
    final run = SetupRun(tester);
    await run.toPlan();
    await run.next('Looks good');
    await settleWrites(tester);
    expect(find.text('Targets set'), findsOneWidget);
    expect((await _targets(tester, c)).settings, hasLength(1));
    expect(phone.adapter.requests.length, before);
    await unmountApp(tester, c);
  });

  testWidgets('UX-070 every page at text scale 2.0 keeps its buttons on '
      'screen', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    void onScreen(String label) {
      final rect = tester.getRect(find.text(label));
      expect(rect.bottom, lessThanOrEqualTo(screen.height), reason: label);
      expect(rect.top, greaterThanOrEqualTo(0), reason: label);
    }

    onScreen('Continue');
    onScreen('Skip');
    await run.tap('Lose weight');
    await run.next();
    await run.you();
    onScreen('Continue');
    await run.next();
    await run.tap('Moderately active');
    onScreen('Continue');
    await run.next();
    await run.tap('Not right now');
    onScreen('Continue');
    await run.next();
    onScreen('Looks good');
    onScreen('Change the numbers');
    await unmountApp(tester, c);
  });

  testWidgets('D-088 first run: after "Looks good" the account step; '
      '"Not now" goes to Today; Back on the first question returns to the '
      'welcome', (tester) async {
    final c = await openSetup(tester, route: const FirstRunSetupRoute());
    final run = SetupRun(tester);
    expect(_draft(c, SetupMode.firstRun).pages.last, SetupPage.account);
    // Back on the first question: the welcome screen, nothing asked.
    await run.back();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await run.tap('Get started');
    expect(find.text('What brings you here?'), findsOneWidget);

    await run.toPlan();
    await run.next('Looks good');
    await settleWrites(tester);
    expect(find.text('Keep your data safe?'), findsOneWidget);
    expect(find.text('Targets set'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
    expect((await _targets(tester, c)).settings, hasLength(1));
    // No way back to a saved plan.
    expect(find.byTooltip('Back'), findsNothing);
    await run.tap('Not now');
    await settleWrites(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('kcal left today'), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('AC-001 the account step opens sign-in by email', (tester) async {
    final c = await openSetup(tester, route: const FirstRunSetupRoute());
    final run = SetupRun(tester);
    await run.tap('Just see what I eat');
    await run.next();
    await run.tap('Skip');
    expect(find.text('Keep your data safe?'), findsOneWidget);
    // Google is hidden on a build without it (A33 D7).
    expect(find.text('Continue with Google'), findsNothing);
    await run.tap('Continue with email');
    expect(find.text('Sign in or create an account'), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets("A13a security #3 a profile this version can't read shows "
      '"Update the app" instead of setup', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = await pumpApp(
      tester,
      overrides: [
        setupStatusProvider.overrideWith(
          (ref) async => SetupStatus.profileUnreadable,
        ),
      ],
    );
    showRoute(c, const SetupRoute());
    await settleWrites(tester);
    expect(find.text('Update the app'), findsOneWidget);
    expect(find.text('What brings you here?'), findsNothing);
    await unmountApp(tester, c);
  });
}
