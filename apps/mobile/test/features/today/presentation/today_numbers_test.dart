import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';
import 'support/today_targets_support.dart';

/// One scripted day (exit 2): what is stored, and what the A12 engine says
/// on its own ([TargetPlan.day] on the same inputs, built by hand here).
final class _Scenario {
  const new(
    this.name, {
    required this.date,
    required this.settings,
    required this.intake,
    required this.eaten,
    required this.plan,
    required this.earlier,
    this.weekShown = true,
  });

  final String name;
  final LocalDate date;
  final List<TargetSettingsRecord> settings;
  final List<DayIntake> intake;
  final double eaten;

  /// The engine's plan for the version in effect.
  final TargetPlan plan;

  /// The engine's view of the earlier days (unknown days left out).
  final List<WeekIntake> earlier;

  /// Whether the weekly line shows (weekly mode).
  final bool weekShown;
}

const _floor = 1750.0;

TargetPlan _plan({
  double base = 2000,
  TargetMode mode = TargetMode.weekly,
  bool manual = false,
  bool acknowledged = false,
  Map<DayOfWeek, double> weights = const {},
  MacroSettings? macros,
}) => TargetPlan(
  baseKcal: base,
  floorKcal: _floor,
  mode: mode,
  manual: manual,
  acknowledged: acknowledged,
  weights: weights,
  macros: macros,
);

WeekIntake _known(int day, double kcal) =>
    WeekIntake(date: weekDay(day), kcal: kcal);

List<_Scenario> _scenarios() {
  final friday = {DayOfWeek.friday: 1.3};
  final fridayPlan = _plan(weights: friday).day(date: weekSat, weightKg: 80);
  final planned = fridayPlan.week!.planned;
  final revised = sampleVersion(id: 2, from: weekDay(4), base: 2400);
  final proteinOnly = MacroSettings(caloriesProteinOnly: true);
  return [
    _Scenario(
      'under',
      date: weekDay(4),
      settings: [sampleVersion()],
      intake: [for (var d = 0; d < 4; d++) ate(weekDay(d), 1900)],
      eaten: 1240.4,
      plan: _plan(),
      earlier: [for (var d = 0; d < 4; d++) _known(d, 1900)],
    ),
    _Scenario(
      'over',
      date: weekDay(4),
      settings: [sampleVersion()],
      intake: [for (var d = 0; d < 4; d++) ate(weekDay(d), 2000)],
      eaten: 2350.6,
      plan: _plan(),
      earlier: [for (var d = 0; d < 4; d++) _known(d, 2000)],
    ),
    _Scenario(
      'first day of the week',
      date: weekSat,
      settings: [sampleVersion()],
      intake: const [],
      eaten: 600,
      plan: _plan(),
      earlier: const [],
    ),
    _Scenario(
      'unknown day',
      date: weekDay(4),
      settings: [sampleVersion()],
      // Monday has no entries: unknown, never zero (TG-032).
      intake: [
        ate(weekDay(0), 2000),
        ate(weekDay(1), 2300),
        DayIntake(date: weekDay(2), kcal: 0, entryCount: 0),
        ate(weekDay(3), 1700),
      ],
      eaten: 900,
      plan: _plan(),
      earlier: [_known(0, 2000), _known(1, 2300), _known(3, 1700)],
    ),
    _Scenario(
      'incomplete day',
      date: weekDay(4),
      settings: [sampleVersion()],
      intake: [
        ate(weekDay(0), 2000),
        ate(weekDay(1), 2000),
        ate(weekDay(2), 2000),
        DayIntake(date: weekDay(3), kcal: 800, entryCount: 2, incomplete: true),
      ],
      eaten: 1000,
      plan: _plan(),
      earlier: [
        _known(0, 2000),
        _known(1, 2000),
        _known(2, 2000),
        WeekIntake(date: weekDay(3), kcal: 800, complete: false),
      ],
    ),
    _Scenario(
      'fixed',
      date: weekDay(4),
      settings: [sampleVersion(mode: TargetMode.fixed)],
      intake: [ate(weekDay(0), 3000), ate(weekDay(1), 1200)],
      eaten: 1500,
      plan: _plan(mode: TargetMode.fixed),
      earlier: [_known(0, 3000), _known(1, 1200)],
      weekShown: false,
    ),
    _Scenario(
      'calories and protein only',
      date: weekDay(2),
      settings: [sampleVersion(macros: proteinOnly)],
      intake: [ate(weekDay(0), 2100), ate(weekDay(1), 1950)],
      eaten: 1100,
      plan: _plan(macros: proteinOnly),
      earlier: [_known(0, 2100), _known(1, 1950)],
    ),
    _Scenario(
      'acknowledged manual below floor',
      date: weekDay(3),
      settings: [
        sampleVersion(
          base: 1300,
          mode: TargetMode.fixed,
          manual: true,
          acknowledged: true,
        ),
      ],
      intake: [ate(weekDay(0), 1300)],
      eaten: 450,
      plan: _plan(
        base: 1300,
        mode: TargetMode.fixed,
        manual: true,
        acknowledged: true,
      ),
      earlier: [_known(0, 1300)],
      weekShown: false,
    ),
    _Scenario(
      'midweek revision',
      date: weekDay(5),
      // Thursday uses Wednesday's version over the whole week (A12 PA5).
      settings: [sampleVersion(), revised],
      intake: [for (var d = 0; d < 5; d++) ate(weekDay(d), 2200)],
      eaten: 700,
      plan: _plan(base: 2400),
      earlier: [for (var d = 0; d < 5; d++) _known(d, 2200)],
    ),
    _Scenario(
      'higher-calorie Friday',
      date: weekDay(6),
      settings: [sampleVersion(shifts: friday)],
      // Every earlier day ate its planned share exactly: Friday keeps its
      // higher one.
      intake: [
        for (var d = 0; d < 6; d++) ate(weekDay(d), planned[weekDay(d)]!),
      ],
      eaten: 1800,
      plan: _plan(weights: friday),
      earlier: [for (var d = 0; d < 6; d++) _known(d, planned[weekDay(d)]!)],
    ),
  ];
}

FbBigNumber _big(WidgetTester tester) =>
    tester.widget<FbBigNumber>(find.byType(FbBigNumber));

List<FbMacroValue> _macros(WidgetTester tester) =>
    tester.widget<FbMacroBars>(find.byType(FbMacroBars)).macros;

TodayNumbers _block(LocalDate date, double kcal, {bool isToday = true}) =>
    TodayNumbers(date: date, isToday: isToday, totals: eatenTotals(kcal));

void main() {
  testWidgets('HM-001 HM-002 HM-003 TG-045 scripted scenarios match the '
      'engine: under, over, first day of the week, unknown day, incomplete '
      'day, fixed, calories+protein only, acknowledged manual below floor, '
      'midweek revision, higher-calorie Friday', (tester) async {
    for (final s in _scenarios()) {
      final engine = s.plan.day(
        date: s.date,
        weightKg: 80,
        earlierIntake: s.earlier,
      );
      final targets = targetsOn(s.date, settings: s.settings, intake: s.intake);
      await pumpBlock(
        tester,
        _block(s.date, s.eaten),
        numbersOverrides(s.date, targets),
      );

      final target = DisplayRounding.kcal(engine.kcal);
      final eaten = DisplayRounding.kcal(s.eaten);
      final remaining = target - eaten;
      final big = _big(tester);
      expect(big.value, kcalText(remaining.abs()), reason: s.name);
      expect(
        big.caption,
        remaining < 0 ? 'kcal over today' : 'kcal left today',
        reason: s.name,
      );
      expect(big.over, remaining < 0, reason: s.name);
      expect(
        find.text('${kcalText(eaten)} / ${kcalText(target)} kcal'),
        findsOneWidget,
        reason: s.name,
      );
      final bar = tester.widget<FbProgressBar>(find.byType(FbProgressBar));
      expect((bar.value, bar.target), (eaten, target), reason: s.name);

      // The weekly line: eaten minus planned over the known, complete
      // earlier days (D7), and the days not counted.
      final week = find.textContaining('This week');
      if (!s.weekShown) {
        expect(week, findsNothing, reason: s.name);
      } else {
        var position = 0.0;
        for (final day in s.earlier.where((d) => d.complete)) {
          position += day.kcal - engine.week!.planned[day.date]!;
        }
        final rounded = DisplayRounding.kcal(position);
        final line = switch (rounded) {
          0 => 'This week: on track',
          > 0 => 'This week: ${kcalText(rounded)} kcal over',
          _ => 'This week: ${kcalText(-rounded)} kcal under',
        };
        final uncounted = engine.week!.unknownDates.length;
        final text = switch (uncounted) {
          0 => line,
          1 => '$line · 1 day not counted',
          _ => '$line · $uncounted days not counted',
        };
        expect(find.text(text), findsOneWidget, reason: s.name);
      }

      final macros = _macros(tester);
      final m = engine.macros;
      expect(
        [for (final macro in macros) macro.target],
        [
          DisplayRounding.macroTargetGrams(m.proteinGrams).toDouble(),
          if (m.carbsGrams case final g?)
            DisplayRounding.macroTargetGrams(g) * 1.0
          else
            null,
          if (m.fatGrams case final g?)
            DisplayRounding.macroTargetGrams(g) * 1.0
          else
            null,
          DisplayRounding.macroTargetGrams(m.fiberGrams).toDouble(),
        ],
        reason: s.name,
      );
    }
    // A few figures worked out by hand, so the engine can't agree with
    // itself by accident.
    final byName = {for (final s in _scenarios()) s.name: s};
    Future<void> show(String name) async {
      final s = byName[name]!;
      await pumpBlock(
        tester,
        _block(s.date, s.eaten),
        numbersOverrides(
          s.date,
          targetsOn(s.date, settings: s.settings, intake: s.intake),
        ),
      );
    }

    await show('under');
    // 14,000 − 4 × 1,900 = 6,400 over 3 days = 2,133; 2,133 − 1,240 = 893.
    expect(_big(tester).value, '893');
    expect(find.text('This week: 400 kcal under'), findsOneWidget);
    await show('over');
    // 2,000 − 2,351 = −351.
    expect((_big(tester).value, _big(tester).over), ('351', true));
    await show('acknowledged manual below floor');
    // 1,300 − 450 = 850, the same every day.
    expect(_big(tester).value, '850');
    expect(find.text('450 / 1,300 kcal'), findsOneWidget);
  });

  testWidgets('SF-021 over target shows "kcal over today" in the over tone '
      'with no icon', (tester) async {
    final date = weekDay(1);
    await pumpBlock(
      tester,
      _block(date, 2600),
      numbersOverrides(date, targetsOn(date, intake: [ate(weekSat, 2000)])),
    );
    final big = _big(tester);
    expect(
      (big.value, big.caption, big.over),
      ('600', 'kcal over today', true),
    );
    final number = tester.widget<Text>(
      find.descendant(of: find.byType(FbBigNumber), matching: find.text('600')),
    );
    final context = tester.element(find.byType(FbBigNumber));
    expect(number.style!.color, context.fbColors.overTarget);
    expect(number.style!.color, isNot(Theme.of(context).colorScheme.error));
    expect(
      find.descendant(
        of: find.byType(TodayNumbers),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });

  testWidgets('TG-044 fixed mode hides the weekly line', (tester) async {
    final date = weekDay(3);
    await pumpBlock(
      tester,
      _block(date, 1000),
      numbersOverrides(
        date,
        targetsOn(
          date,
          settings: [sampleVersion(mode: TargetMode.fixed)],
          intake: [ate(weekSat, 2500)],
        ),
      ),
    );
    expect(find.textContaining('This week'), findsNothing);
    expect(find.text('1,000 / 2,000 kcal'), findsOneWidget);
    expect(_big(tester).value, '1,000');
  });

  testWidgets('TG-054 calories+protein only shows carbs and fat without '
      'targets', (tester) async {
    await pumpBlock(
      tester,
      _block(weekSat, 1000),
      numbersOverrides(
        weekSat,
        targetsOn(
          weekSat,
          settings: [
            sampleVersion(macros: MacroSettings(caloriesProteinOnly: true)),
          ],
        ),
      ),
    );
    final macros = _macros(tester);
    expect(
      [for (final m in macros) m.label],
      ['Protein', 'Carbs', 'Fat', 'Fiber'],
    );
    expect(macros[1].target, isNull);
    expect(macros[2].target, isNull);
    // Grams from 10 g are whole (DisplayRounding.nutrientGrams).
    expect(macros[1].valueText, '152 g');
    expect(macros[2].valueText, '40 g');
    expect(macros[0].target, isNotNull);
    expect(macros[0].valueText, '82 / ${macros[0].target!.round()} g');
    // A macro without a target draws no track.
    expect(
      find.descendant(
        of: find.byType(FbMacroBars),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'FbBarTrack',
        ),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('UX-050 without targets today shows kcal eaten and the setup '
      'row; past days show kcal eaten only', (tester) async {
    final navigator = RecordingNavigator();
    final overrides = [
      ...numbersOverrides(weekSat, null, setup: SetupStatus.notSetUp),
      appNavigatorProvider.overrideWithValue(navigator),
    ];
    await pumpBlock(tester, _block(weekSat, 1239.6), overrides);
    expect((_big(tester).value, _big(tester).caption), ('1,240', 'kcal eaten'));
    expect(find.text('Protein 82 g'), findsOneWidget);
    expect(find.text('Set up your targets'), findsOneWidget);
    expect(find.text('About 2 minutes'), findsOneWidget);
    expect(find.byType(FbProgressBar), findsNothing);
    expect(find.textContaining('This week'), findsNothing);
    await tester.tap(find.text('Set up your targets'));
    expect(navigator.pushed, [const SetupRoute()]);

    await pumpBlock(tester, _block(weekSat, 1239.6, isToday: false), overrides);
    expect(_big(tester).caption, 'kcal eaten');
    expect(find.text('Set up your targets'), findsNothing);

    // Once set up, today shows no row even on a day without a version.
    await pumpBlock(
      tester,
      _block(weekSat, 1239.6),
      numbersOverrides(weekSat, null),
    );
    expect(find.text('Set up your targets'), findsNothing);
  });

  testWidgets("A13a security #3 a profile this version can't read shows "
      '"Update the app" instead of the setup row', (tester) async {
    final navigator = RecordingNavigator();
    await pumpBlock(tester, _block(weekSat, 300), [
      ...numbersOverrides(weekSat, null, setup: SetupStatus.profileUnreadable),
      appNavigatorProvider.overrideWithValue(navigator),
    ]);
    expect(find.text('Set up your targets'), findsNothing);
    expect(find.text('Update the app'), findsOneWidget);
    expect(find.text('Your profile needs a newer version'), findsOneWidget);
    await tester.tap(find.text('Update the app'));
    expect(navigator.pushed, [const SetupRoute()]);
  });

  testWidgets('UX-051 the numbers skeleton shows until targets load; UX-052 '
      'a targets read error keeps kcal eaten and shows the banner with Try '
      'again', (tester) async {
    final pending = Completer<DayTargets?>();
    await pumpBlock(tester, _block(weekSat, 1240), [
      dayTargetsProvider.overrideWith((ref, date) => pending.future),
      setupStatusProvider.overrideWith((ref) => SetupStatus.setUp),
    ]);
    expect(find.byType(FbSkeleton), findsWidgets);
    expect(find.byType(FbBigNumber), findsNothing);

    pending.complete(targetsOn(weekSat));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FbSkeleton), findsNothing);
    expect(_big(tester).caption, 'kcal left today');

    // A first read that fails (a fresh scope).
    var fail = true;
    await pumpBlock(tester, _block(weekSat, 1240), [
      dayTargetsProvider.overrideWith((ref, date) {
        if (fail) throw StateError('targets unreadable (test)');
        return targetsOn(weekSat);
      }),
      setupStatusProvider.overrideWith((ref) => SetupStatus.setUp),
    ]);
    await tester.pump();
    expect((_big(tester).value, _big(tester).caption), ('1,240', 'kcal eaten'));
    expect(find.text("Couldn't load your targets."), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't load your targets."), findsNothing);
    expect(_big(tester).caption, 'kcal left today');
  });

  testWidgets('UX-070 at text scale 2.0 the numbers and the weekly line fit '
      'a 320 dp phone', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final date = weekDay(3);
    await tester.pumpWidget(
      ProviderScope(
        overrides: numbersOverrides(
          date,
          targetsOn(date, intake: [ate(weekSat, 1650), ate(weekDay(2), 2100)]),
        ),
        child: phoneApp(
          Scaffold(body: SingleChildScrollView(child: _block(date, 1240))),
          textScale: 2,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final week = find.textContaining('1 day not counted');
    expect(week, findsOneWidget);
    // The line keeps the block's width; "eaten / target" goes under it.
    expect(tester.getSize(week).width, greaterThan(250));
    expect(
      tester.getTopLeft(find.textContaining('1,240 / ')).dy,
      greaterThan(tester.getBottomLeft(week).dy),
    );
  });
}
