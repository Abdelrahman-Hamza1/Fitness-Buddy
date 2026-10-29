import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';
import 'support/today_test_support.dart';

/// [text] on [date]'s page.
Finder _onPage(LocalDate date, String text) =>
    find.descendant(of: dayPage(date), matching: find.text(text));

/// Taps the last widget showing [text] (a page's own copy, not a title).
Future<void> _tap(WidgetTester tester, String text) async {
  await tapExactly(tester, find.text(text).last, '"$text"');
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// Types [value] into the number field labelled [label], then closes the
/// keyboard so the pinned Back/Next stay where they were.
Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// Waits for setup to show page [n] of 5.
Future<void> _page(WidgetTester tester, int n) => waitUntil(
  tester,
  () => find.text('Step $n of 5').evaluate().isNotEmpty,
  'setup page $n',
);

/// UX-060 WB-001 HM-001 on the device (A13 WP8, exit 1): a fresh throw-away
/// profile with no API reachable, Today's setup row, the five pages with
/// the minimal answers, Save, then Today shows the calories left (equal to
/// the engine on the stored rows), the weekly line and A14's weight card
/// with the typed weight. Prints the elapsed time for the step's evidence;
/// the owner's timed run on the A55 is the exit's measure.
void main() {
  patrolTest('A13 onboarding journey setup to Today', ($) async {
    final container = await bootApp($, 'it-setup', rootName: 'fb_setup_it');
    final tester = $.tester;
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final db = container.read(appDatabaseProvider);
    final watch = Stopwatch()..start();

    // Today: no targets yet, so the calories eaten and the setup row.
    final row = _onPage(today, 'Set up your targets');
    await waitUntil(
      tester,
      () => row.evaluate().length == 1,
      "the setup row on today's page",
    );
    await tapExactly(tester, row, 'the setup row');
    await waitUntil(
      tester,
      () => find.byType(SetupScreen).evaluate().isNotEmpty,
      'the setup screen',
    );

    // 1 You (metric by default), 2 Activity, 3 Goal (lose 0.5 kg a week by
    // default), 4 Preferences (prefilled), 5 Your targets.
    await _page(tester, 1);
    await _tap(tester, 'Male');
    await _enter(tester, 'Birth year', '1990');
    await _enter(tester, 'Height', '180');
    await _enter(tester, 'Current weight', '80');
    await _tap(tester, 'Next');
    await _page(tester, 2);
    await _tap(tester, 'Moderately active');
    await _tap(tester, 'Next');
    await _page(tester, 3);
    await _tap(tester, 'Lose weight');
    await _tap(tester, 'Next');
    await _page(tester, 4);
    await _tap(tester, 'Next');
    await _page(tester, 5);
    await _tap(tester, 'Save');

    // Back on Today with the real numbers.
    await waitUntil(
      tester,
      () =>
          find.byType(SetupScreen).evaluate().isEmpty &&
          _onPage(today, 'kcal left today').evaluate().length == 1,
      'Today with kcal left',
    );
    watch.stop();
    // The device figure for the step's evidence (numbers only).
    // ignore: avoid_print
    print('A13 onboarding journey: ${watch.elapsedMilliseconds} ms');

    // The engine on the stored rows, at the first weigh-in's 80 kg, with
    // nothing eaten: the big number is the whole day's target.
    final data = await TargetsRepository(db).read();
    final engine = TargetsTimeline.day(
      date: today,
      settings: [for (final s in data.settings) s.value],
      profile: data.profile!.value,
      goals: [for (final g in data.phases) g.value],
      bodyWeightKg: 80,
    )!;
    final target = NumberFormat.decimalPattern().format(
      DisplayRounding.kcal(engine.day.kcal),
    );
    final big = find.descendant(
      of: dayPage(today),
      matching: find.byType(FbBigNumber),
    );
    await waitUntil(
      tester,
      () => tester.widget<FbBigNumber>(big).value == target,
      'the big number to equal the engine ($target)',
    );
    // Setup starts the week's plan today: no earlier day counts yet.
    expect(_onPage(today, 'This week: on track'), findsOneWidget);
    expect(_onPage(today, 'Set up your targets'), findsNothing);

    // The typed weight is the first weigh-in, on A14's weight card.
    final weighIns = await WeighInRepository(db).watchLive().first.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TestFailure('Timed out reading weigh-ins'),
    );
    expect(weighIns.single.input, const WeighInInput(80, MassUnit.kilogram));
    final card = find.descendant(
      of: dayPage(today),
      matching: find.byType(WeightCard),
    );
    await revealDayWidget(tester, card, today, interactive: false);
    expect(
      find.descendant(of: card, matching: find.textContaining('80.0 kg')),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}
