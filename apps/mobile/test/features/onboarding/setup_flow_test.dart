import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';
import '../settings/presentation/settings_support.dart' show sampleCities;
import '../targets/application/targets_app_harness.dart' show setupInput;
import 'setup_support.dart';

SetupDraft _draft(ProviderContainer c) => c.read(setupFlowProvider).value!;

/// Setup's rows written outside this screen (as if from another device).
/// Started like a tap, in the test's zone; the writes finish in
/// [settleWrites].
Future<void> _setUpElsewhere(WidgetTester tester, ProviderContainer c) async {
  final outcome = c.read(targetsActionsProvider).completeSetup(setupInput());
  await settleWrites(tester);
  expect(await outcome, isA<TargetsDone>());
}

Future<T> _db<T>(WidgetTester tester, Future<T> Function() read) async =>
    (await tester.runAsync(read)) as T;

void main() {
  testWidgets("UX-060 UX-052 Next stays on the page until the page's "
      "required fields are valid, then says what's missing and scrolls to "
      'it; Back keeps everything typed', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    expect(find.text('Step 1 of 5'), findsOneWidget);
    // Next is always on (UX-052); empty, it names what's missing.
    expect(button(tester, 'Next').onPressed, isNotNull);
    expect(find.text('Choose one to continue.'), findsNothing);
    await run.next();
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Choose one to continue.'), findsOneWidget);
    expect(_draft(c).firstProblem, SetupField.sex);
    await run.tap('Male');
    expect(find.text('Choose one to continue.'), findsNothing);
    await run.enter('Birth year', '1990');
    await run.enter('Height', '180');
    await run.enter('Current weight', '600');
    await run.next();
    expect(find.text('Step 1 of 5'), findsOneWidget, reason: 'out of range');
    expect(find.textContaining('Enter a weight between'), findsOneWidget);
    await run.enter('Current weight', '80');
    await run.next();

    expect(find.text('Step 2 of 5'), findsOneWidget);
    // A new page starts without messages.
    expect(find.text('Choose one to continue.'), findsNothing);
    await run.next();
    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('Choose one to continue.'), findsOneWidget);
    await run.tap('Moderately active');
    await run.next();

    expect(find.text('Step 3 of 5'), findsOneWidget);
    await run.next();
    expect(find.text('Step 3 of 5'), findsOneWidget, reason: 'no goal type');
    expect(find.text('Choose one to continue.'), findsOneWidget);
    await run.tap('Lose weight');
    expect(_draft(c).canContinue, isTrue);
    // A target on the wrong side: the goal message, Next stays (PA3).
    await run.tap('Target weight at a pace');
    await run.enter('Target weight', '85');
    await run.enter('Pace each week', '0.5');
    expect(
      find.textContaining("isn't below your current weight"),
      findsOneWidget,
    );
    await run.next();
    expect(find.text('Step 3 of 5'), findsOneWidget);
    await run.tap('Per week');
    expect(_draft(c).canContinue, isTrue);

    // Back twice: page 1 still holds what was typed.
    await run.tap('Back');
    await run.tap('Back');
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('1990'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    final draft = _draft(c);
    expect(draft.activity, ActivityLevel.moderate);
    expect(draft.goal.type, GoalType.lose);
    expect(draft.goal.targetWeight, '85');
    await unmountApp(tester, c);
  });

  testWidgets('UX-052 a refused Next scrolls to the first problem', (
    tester,
  ) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.tap('Male');
    await run.enter('Birth year', '1990');
    await run.enter('Height', '180');
    // Scroll the weight out of sight, leave it empty and tap Next.
    final scroll = find.byType(Scrollable).first;
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    tester.view.physicalSize = const Size(360, 420);
    await tester.pumpAndSettle();
    final weight = find.widgetWithText(TextField, 'Current weight');
    await run.next();
    expect(_draft(c).firstProblem, SetupField.weight);
    expect(weight.hitTestable(), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 TG-002 imperial chosen on page 1 switches the height '
      'and weight inputs', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    expect(find.widgetWithText(TextField, 'Height'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    await run.tap('Imperial');
    expect(find.widgetWithText(TextField, 'Height'), findsNothing);
    expect(find.widgetWithText(TextField, 'Feet'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Inches'), findsOneWidget);
    expect(find.text('lb'), findsOneWidget);
    await run.tap('Male');
    await run.enter('Birth year', '1990');
    await run.enter('Feet', '5');
    await run.enter('Inches', '11');
    await run.enter('Current weight', '176');
    expect(_draft(c).canContinue, isTrue);
    final draft = _draft(c);
    expect(draft.units, UnitSystem.imperial);
    expect(draft.height.unit, HeightInputUnit.feetInches);
    expect(draft.weight.unit, MassUnit.pound);
    expect(draft.goal.unit, MassUnit.pound);
    expect(draft.height.read().value!.centimeters, closeTo(180.34, 1e-9));
    expect(draft.weightKg, 79.83);
    // The goal prefill follows the unit: 0.5 kg is 1.1 lb.
    await run.next();
    await run.tap('Moderately active');
    await run.next();
    await run.tap('Lose weight');
    expect(find.text('1.1'), findsOneWidget);
    expect(find.textContaining('lb a week'), findsWidgets);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 week start, halal and city are prefilled and Save works '
      'with city unset', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.you();
    await run.next();
    await run.tap('Moderately active');
    await run.next();
    await run.tap('Maintain weight');
    await run.next();
    expect(find.text('Step 4 of 5'), findsOneWidget);
    expect(find.text('Saturday'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    final halal = tester.widget<Switch>(find.byType(Switch));
    expect(halal.value, isTrue);
    await run.next();
    expect(find.text('Step 5 of 5'), findsOneWidget);
    await run.next('Save');
    await settleWrites(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    final db = c.read(appDatabaseProvider);
    final data = await _db(tester, () => TargetsRepository(db).read());
    expect(data.profile, isNotNull);
    expect(data.settings, hasLength(1));
    final store = c.read(settingsStoreProvider);
    expect(await _db(tester, () => store.read(AppSettings.cityId)), isNull);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 Save writes once, returns to Today with "Targets set" '
      'and Undo; Undo brings back the setup row and removes the first '
      'weigh-in', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.toTargets();
    expect(find.textContaining('kcal a day'), findsWidgets);
    expect(find.text("How it's calculated"), findsOneWidget);
    await run.next('Save');
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
    var data = await _db(tester, () => TargetsRepository(db).read());
    expect(
      (data.profile != null, data.phases.length, data.settings.length),
      (true, 1, 1),
    );

    await tester.tap(find.text('Undo'));
    await settleWrites(tester);
    expect(find.text('Set up your targets'), findsOneWidget);
    expect(find.text('kcal eaten'), findsOneWidget);
    data = await _db(tester, () => TargetsRepository(db).read());
    expect(data.profile, isNull);
    expect(data.phases, isEmpty);
    expect(data.settings, isEmpty);
    expect(
      await _db(tester, () => WeighInRepository(db).watchLive().first),
      isEmpty,
    );
    await unmountApp(tester, c);
  });

  testWidgets("UX-052 closing with input asks first; closing empty doesn't "
      'ask', (tester) async {
    var c = await openSetup(tester);
    await tester.tap(find.byTooltip('Close setup'));
    await tester.pumpAndSettle();
    expect(find.text('Leave setup?'), findsNothing);
    expect(find.byType(SetupScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    await unmountApp(tester, c);

    c = await openSetup(tester);
    await SetupRun(tester).enter('Birth year', '1990');
    await tester.tap(find.byTooltip('Close setup'));
    await tester.pumpAndSettle();
    expect(find.text('Leave setup?'), findsOneWidget);
    expect(find.text("What you entered won't be saved."), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('1990'), findsOneWidget);
    await tester.tap(find.byTooltip('Close setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsNothing);
    final db = c.read(appDatabaseProvider);
    final data = await _db(tester, () => TargetsRepository(db).read());
    expect(data.profile, isNull);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 offline: setup completes with the API client throwing '
      'on every call', (tester) async {
    // The test phone's network throws a connection error for every request.
    final phone = TestPhone();
    final c = await openSetup(tester, phone: phone);
    final before = phone.adapter.requests.length;
    final run = SetupRun(tester);
    await run.toTargets();
    await run.next('Save');
    await settleWrites(tester);
    expect(find.text('Targets set'), findsOneWidget);
    final db = c.read(appDatabaseProvider);
    final data = await _db(tester, () => TargetsRepository(db).read());
    expect(data.settings, hasLength(1));
    // Setup itself asked the network for nothing.
    expect(phone.adapter.requests.length, before);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 a minimal run takes at most 12 taps and 4 number '
      "entries, from Today's setup row", (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = await pumpApp(tester);
    final run = SetupRun(tester);
    // Every tap counts: the Today row, each choice, Next/Save, and focusing
    // each number field.
    await run.tap('Set up your targets');
    expect(find.byType(SetupScreen), findsOneWidget);
    await run.toTargets();
    await run.next('Save');
    await settleWrites(tester);
    expect(find.text('Targets set'), findsOneWidget);
    expect(run.taps, lessThanOrEqualTo(12));
    expect(run.entries, lessThanOrEqualTo(4));
    // The run's size, for the step's evidence (exit 1).
    // ignore: avoid_print
    print('A13 minimal setup run: ${run.taps} taps, ${run.entries} entries');
    await unmountApp(tester, c);
  });

  testWidgets('UX-070 every page at text scale 2.0 keeps Next/Save on '
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

    onScreen('Next');
    await run.you();
    onScreen('Next');
    await run.next();
    onScreen('Next');
    await run.tap('Moderately active');
    await run.next();
    await run.tap('Lose weight');
    onScreen('Next');
    await run.next();
    onScreen('Next');
    await run.next();
    onScreen('Save');
    onScreen('Back');
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
    expect(find.text('Step 1 of 5'), findsNothing);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 LC-033 a city picked in the sheet lands in the draft '
      'and Save writes it', (tester) async {
    final c = await openSetup(
      tester,
      overrides: [
        citySearchProvider.overrideWith(
          (ref) async => CitySearch(sampleCities),
        ),
      ],
    );
    final run = SetupRun(tester);
    await run.you();
    await run.next();
    await run.tap('Moderately active');
    await run.next();
    await run.tap('Maintain weight');
    await run.next();
    expect(find.text('Step 4 of 5'), findsOneWidget);
    await run.tap('City');
    expect(find.byType(FbSheet), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(FbSheet),
        matching: find.byType(TextField),
      ),
      'nab',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nablus · نابلس'));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsNothing);
    expect(_draft(c).cityId, 'city:282615');
    expect(find.text('Nablus · نابلس'), findsOneWidget);
    await run.next();
    await run.next('Save');
    await settleWrites(tester);
    final store = c.read(settingsStoreProvider);
    expect(
      await _db(tester, () => store.read(AppSettings.cityId)),
      'city:282615',
    );
    await unmountApp(tester, c);
  });

  testWidgets("D10 a stored city the offline pack can't resolve stays "
      'stored: Save writes a city only when one is picked', (tester) async {
    const stored = 'city:999999';
    final c = await openSetup(
      tester,
      before: (c) async {
        await c
            .read(settingsStoreProvider)
            .put(AppSettings.cityId, stored, origin: Origin.direct);
      },
    );
    final draft = _draft(c);
    expect((draft.cityId, draft.city), (stored, null));
    final run = SetupRun(tester);
    await run.toTargets();
    await run.next('Save');
    await settleWrites(tester);
    expect(find.text('Targets set'), findsOneWidget);
    final store = c.read(settingsStoreProvider);
    expect(await _db(tester, () => store.read(AppSettings.cityId)), stored);
    await unmountApp(tester, c);
  });

  testWidgets('UX-052 the system back goes one page back; on page 1 it asks '
      'before closing', (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.you();
    await run.next();
    expect(find.text('Step 2 of 5'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('1990'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave setup?'), findsOneWidget);
    expect(find.byType(SetupScreen), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 5'), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('D10 setup opened when it already ran says so and goes to '
      'Today', (tester) async {
    final c = await pumpApp(tester);
    await _setUpElsewhere(tester, c);
    // As the app opens it (an old entry, another device's setup).
    c.read(appNavigatorProvider).push(const SetupRoute());
    await settleWrites(tester);
    expect(find.byType(SetupScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Your targets are already set up.'), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('UX-060 Save after setup ran elsewhere goes to Today and says '
      "it's already set up", (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    await run.toTargets();
    // Another device's setup arrives while this one is open.
    await _setUpElsewhere(tester, c);
    expect(find.byType(SetupScreen), findsOneWidget);
    await run.next('Save');
    await settleWrites(tester);
    expect(find.byType(SetupScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Your targets are already set up.'), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('UX-051 the first frame of setup already has its bar', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    showRoute(c, const SetupRoute());
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Close setup'), findsOneWidget);
    expect(find.text('Set up your targets'), findsWidgets);
    await settleWrites(tester);
    await unmountApp(tester, c);
  });

  testWidgets("UX-040 Setup's first page shows the brand lockup; the other "
      "pages don't", (tester) async {
    final c = await openSetup(tester);
    final run = SetupRun(tester);
    expect(find.text('Step 1 of 5'), findsOneWidget);
    final lockup = find.byType(FbBrandLockup);
    expect(lockup, findsOneWidget);
    expect(tester.widget<FbBrandLockup>(lockup).name, 'Fitness Buddy');

    await run.tap('Male');
    await run.enter('Birth year', '1990');
    await run.enter('Height', '180');
    await run.enter('Current weight', '80');
    await run.next();
    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.byType(FbBrandLockup), findsNothing);
    await unmountApp(tester, c);
  });
}
