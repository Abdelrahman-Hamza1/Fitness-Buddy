import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';
import '../../diary/support/diary_harness.dart' show atDay, newEntry;
import '../../onboarding/setup_support.dart';
import 'support/today_targets_support.dart' show kcalText;

Future<T> _db<T>(WidgetTester tester, Future<T> Function() read) async =>
    (await tester.runAsync(read)) as T;

/// The big number of [date]'s page.
FbBigNumber _big(WidgetTester tester, LocalDate date) =>
    tester.widget<FbBigNumber>(
      find.descendant(
        of: find.byKey(ValueKey<LocalDate>(date)),
        matching: find.byType(FbBigNumber),
      ),
    );

/// What the engine says for [date] from the stored rows and the diary days
/// given here by hand (not through the app's providers), at the first
/// weigh-in's 80 kg.
Future<DayTargets> _engine(
  WidgetTester tester,
  ProviderContainer c,
  LocalDate date,
  List<DayIntake> intake,
) async {
  final data = await _db(
    tester,
    () => TargetsRepository(c.read(appDatabaseProvider)).read(),
  );
  return TargetsTimeline.day(
    date: date,
    settings: [for (final s in data.settings) s.value],
    profile: data.profile!.value,
    goals: [for (final g in data.phases) g.value],
    bodyWeightKg: 80,
    intake: intake,
  )!;
}

/// Today's numbers equal [engine] for [eatenKcal] eaten: remaining, target,
/// and the weekly line [week].
void _expectToday(
  WidgetTester tester,
  LocalDate date,
  DayTargets engine,
  double eatenKcal,
  String week,
) {
  final target = DisplayRounding.kcal(engine.day.kcal);
  final eaten = DisplayRounding.kcal(eatenKcal);
  final big = _big(tester, date);
  expect(big.caption, 'kcal left today');
  expect(big.value, kcalText(target - eaten));
  expect(
    find.text('${kcalText(eaten)} / ${kcalText(target)} kcal'),
    findsOneWidget,
  );
  expect(find.text(week), findsOneWidget);
}

void main() {
  testWidgets('HM-001 host journey (ManualClock, real DB): complete setup, '
      "log a food, Today's remaining and weekly line equal the engine; a log "
      "on yesterday changes today's target by rebalancing", (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Saturday 17 October 2026, noon UTC: the first day of the default week.
    final clock = ManualClock(DateTime.utc(2026, 10, 17, 12));
    final saturday = LocalDate(2026, 10, 17);
    final sunday = saturday.plusDays(1);
    final c = await pumpApp(
      tester,
      overrides: [clockProvider.overrideWithValue(clock)],
    );

    // Today offers setup; setup runs from its row.
    expect(_big(tester, saturday).caption, 'kcal eaten');
    await tester.tap(find.text('Set up your targets'));
    await tester.pumpAndSettle();
    final run = SetupRun(tester);
    await run.toTargets();
    await run.next('Save');
    await settleWrites(tester);
    expect(find.text('Set up your targets'), findsNothing);
    var engine = await _engine(tester, c, saturday, const []);
    // The first day of the week: the generated base, 2,162.5 kcal.
    expect(DisplayRounding.kcal(engine.day.kcal), 2163);
    _expectToday(tester, saturday, engine, 0, 'This week: on track');
    // The typed weight is the first weigh-in, on A14's card below.
    expect(
      find.descendant(
        of: find.byType(WeightCard),
        matching: find.textContaining('80.0 kg'),
      ),
      findsWidgets,
    );

    // A 300 kcal lunch today.
    Future<void> log(int n, LocalDate date, double per100) async {
      await _db(
        tester,
        () => c
            .read(changeSetApplierProvider)
            .apply(
              ChangeSet([
                LogEntries([newEntry(n, when: atDay(date), kcal: per100)]),
              ], origin: Origin.direct),
            ),
      );
      await settleWrites(tester);
    }

    await log(1, saturday, 200);
    _expectToday(tester, saturday, engine, 300, 'This week: on track');

    // The next day: Saturday is a known earlier day of the week.
    clock.advance(const Duration(days: 1));
    c.invalidate(todayProvider);
    await settleWrites(tester);
    engine = await _engine(tester, c, sunday, [
      DayIntake(date: saturday, kcal: 300, entryCount: 1),
    ]);
    _expectToday(
      tester,
      sunday,
      engine,
      0,
      'This week: ${kcalText(-engine.week!.kcal)} kcal under',
    );
    final before = DisplayRounding.kcal(engine.day.kcal);

    // 3,000 kcal more on yesterday: rebalancing lowers today's target.
    await log(2, saturday, 2000);
    engine = await _engine(tester, c, sunday, [
      DayIntake(date: saturday, kcal: 3300, entryCount: 2),
    ]);
    expect(DisplayRounding.kcal(engine.day.kcal), lessThan(before));
    _expectToday(
      tester,
      sunday,
      engine,
      0,
      'This week: ${kcalText(engine.week!.kcal)} kcal over',
    );
    await unmountApp(tester, c);
  });
}
