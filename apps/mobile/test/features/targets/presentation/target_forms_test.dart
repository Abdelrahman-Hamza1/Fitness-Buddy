import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import 'target_forms_support.dart';

/// Profile fields over drafts the test can read back.
class _ProfileHarness extends StatefulWidget {
  const new({required this.height, required this.weight, super.key});

  final HeightDraft height;
  final BodyWeightDraft weight;

  @override
  State<_ProfileHarness> createState() => _ProfileHarnessState();
}

class _ProfileHarnessState extends State<_ProfileHarness> {
  late HeightDraft height = widget.height;
  late BodyWeightDraft weight = widget.weight;

  @override
  Widget build(BuildContext context) => formScreen(
    Column(
      children: [
        HeightField(
          draft: height,
          showUnitChoice: true,
          onChanged: (d) => setState(() => height = d),
        ),
        const SizedBox(height: 16),
        BodyWeightField(
          draft: weight,
          onChanged: (d) => setState(() => weight = d),
        ),
      ],
    ),
  );
}

_ProfileHarnessState _profile(WidgetTester tester) =>
    tester.state<_ProfileHarnessState>(find.byType(_ProfileHarness));

Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _leaveField(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(phoneApp(screen));
  await tester.pump();
}

void main() {
  testWidgets('TG-002 LC-011 height accepts cm or ft+in and weight kg or lb '
      'whatever the units; out-of-range input shows the range message and '
      'keeps the text', (tester) async {
    await _pump(
      tester,
      const _ProfileHarness(
        height: HeightDraft(unit: HeightInputUnit.feetInches),
        weight: BodyWeightDraft(unit: MassUnit.pound),
      ),
    );
    await tester.enterText(_field('Feet'), '5');
    await tester.enterText(_field('Inches'), '11');
    await tester.enterText(_field('Current weight'), '200');
    await _leaveField(tester);
    expect(
      _profile(tester).height.read().value!.centimeters,
      closeTo(180.34, 1e-9),
    );
    expect(_profile(tester).height.unit, HeightInputUnit.feetInches);
    expect(_profile(tester).weight.read().value, closeTo(90.72, .01));
    expect(find.text('lb'), findsOneWidget);
    expect(find.textContaining('Enter a'), findsNothing);

    // Switch the height to cm: its own field, typed out of range.
    await tester.tap(find.text('cm').first);
    await tester.pump();
    expect(_profile(tester).height.unit, HeightInputUnit.centimeter);
    await tester.enterText(_field('Height'), '300');
    await _leaveField(tester);
    expect(find.text('Enter a height between 100 and 250 cm.'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(_profile(tester).height.read().error, TypedFieldError.outOfRange);

    // The same weight field in kg (another draft, the same widget).
    await _pump(
      tester,
      const _ProfileHarness(
        key: ValueKey('kg'),
        height: HeightDraft(unit: HeightInputUnit.feetInches),
        weight: BodyWeightDraft(),
      ),
    );
    await tester.enterText(_field('Current weight'), '600');
    await _leaveField(tester);
    expect(find.text('Enter a weight between 20 and 500 kg.'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
    await tester.enterText(_field('Feet'), '9');
    await _leaveField(tester);
    expect(
      find.text(
        'Enter a height between 3 ft 4 in and 8 ft 2 in. Inches go up to 11.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('TG-001 D15 the birth year names its accepted years once the '
      'field is left, not while typing', (tester) async {
    var text = '';
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => formScreen(
          BirthYearField(
            text: text,
            today: formToday,
            onChanged: (t) => setState(() => text = t),
          ),
        ),
      ),
    );
    await tester.enterText(_field('Birth year'), '20');
    await tester.pump();
    expect(find.textContaining('Enter a year'), findsNothing);
    await tester.enterText(_field('Birth year'), '2015');
    await _leaveField(tester);
    expect(find.text('Enter a year between 1926 and 2008.'), findsOneWidget);
    expect(find.text('2015'), findsOneWidget);
  });

  testWidgets('TG-011 the goal form shows the weekly rate, the monthly figure '
      'and, with a target weight, the projected month', (tester) async {
    final weekly = loseDraft();
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: weekly,
          onChanged: (_) {},
          today: formToday,
          calculation: calculationFor(weekly),
        ),
      ),
    );
    expect(find.text('≈ −0.5 kg a week · −2.2 kg in October'), findsOneWidget);
    expect(find.text('Lose each week'), findsOneWidget);

    final paced = loseDraft()
        .withKind(GoalExpressionKind.targetRate)
        .copyWith(targetWeight: '85', pace: '0.5');
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: paced,
          onChanged: (_) {},
          today: formToday,
          calculation: calculationFor(paced),
        ),
      ),
    );
    expect(
      find.text(
        '≈ −0.5 kg a week · −2.2 kg in October · goal reached around '
        'January 2027',
      ),
      findsOneWidget,
    );

    // The same goal in lb.
    final inPounds = loseDraft().withUnit(MassUnit.pound);
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: inPounds,
          onChanged: (_) {},
          today: formToday,
          calculation: calculationFor(inPounds),
        ),
      ),
    );
    expect(find.text('≈ −1.1 lb a week · −4.9 lb in October'), findsOneWidget);
  });

  testWidgets('TG-010 TG-011 choosing a type and an expression edits the '
      'draft; a maintain goal shows its note', (tester) async {
    var draft = const GoalDraft();
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => formScreen(
          GoalForm(
            draft: draft,
            today: formToday,
            onChanged: (d) => setState(() => draft = d),
          ),
        ),
      ),
    );
    expect(find.text('How do you want to set it?'), findsNothing);
    await tester.tap(find.text('Gain weight'));
    await tester.pump();
    expect(draft.type, GoalType.gain);
    expect(draft.rate, '0.25');
    expect(find.text('Gain each week'), findsOneWidget);
    await tester.tap(find.text('This month'));
    await tester.pump();
    expect(draft.kind, GoalExpressionKind.monthly);
    expect(find.text('Gain this month'), findsOneWidget);
    await tester.tap(find.text('Target weight by a date'));
    await tester.pump();
    expect(find.text('Target weight'), findsOneWidget);
    expect(find.text('Pick a date'), findsOneWidget);
    await tester.tap(find.text('Maintain weight'));
    await tester.pump();
    expect(find.text('How do you want to set it?'), findsNothing);
    expect(find.text('Your target keeps your weight steady.'), findsOneWidget);
  });

  testWidgets('PA3 a passed deadline or a target on the wrong side shows the '
      'goal message instead of numbers', (tester) async {
    final byDate = loseDraft()
        .withKind(GoalExpressionKind.targetDate)
        .copyWith(targetWeight: '80', targetDate: formToday);
    final problem = GoalProblem.of(
      byDate.read(formToday).input!,
      currentKg: 90,
      today: formToday,
    );
    expect(problem, GoalProblem.deadline);
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: byDate,
          onChanged: (_) {},
          today: formToday,
          problem: problem,
          calculation: calculationFor(loseDraft()),
        ),
      ),
    );
    expect(find.text('Pick a date after today.'), findsOneWidget);
    expect(find.textContaining('≈'), findsNothing);

    final wrongSide = loseDraft()
        .withKind(GoalExpressionKind.targetRate)
        .copyWith(targetWeight: '95', pace: '0.5');
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: wrongSide,
          onChanged: (_) {},
          today: formToday,
          problem: GoalProblem.of(
            wrongSide.read(formToday).input!,
            currentKg: 90,
            today: formToday,
          ),
        ),
      ),
    );
    expect(
      find.text(
        "This target weight isn't below your current weight. Choose a lower "
        'target, or another goal.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('≈'), findsNothing);
  });

  testWidgets('TG-013 a loss above 1% a week shows the cap message with the '
      'planned rate', (tester) async {
    final fast = loseDraft().copyWith(rate: '1.2');
    final calculation = calculationFor(fast);
    expect(calculation.warnings, contains(TargetWarning.lossRateCapped));
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: fast,
          onChanged: (_) {},
          today: formToday,
          calculation: calculation,
        ),
      ),
    );
    expect(
      find.text(
        'You asked for 1.2 kg a week. Plans stay within 1% of your weight a '
        'week, so this plan uses 0.9 kg.',
      ),
      findsOneWidget,
    );
    expect(find.text('≈ −0.9 kg a week · −4 kg in October'), findsOneWidget);

    // Within the limit: no cap message.
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: loseDraft(),
          onChanged: (_) {},
          today: formToday,
          calculation: calculationFor(loseDraft()),
        ),
      ),
    );
    expect(find.textContaining('You asked for'), findsNothing);
  });

  testWidgets('UX-052 a refused Next shows the messages of the goal fields, '
      'keeping the text', (tester) async {
    final draft = loseDraft()
        .withKind(GoalExpressionKind.targetDate)
        .copyWith(targetWeight: '700');
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: draft,
          onChanged: (_) {},
          today: formToday,
          showErrors: true,
        ),
      ),
    );
    expect(find.text('Enter a weight between 20 and 500 kg.'), findsOneWidget);
    expect(find.text('700'), findsOneWidget);
    expect(find.text('Pick a target date.'), findsOneWidget);
  });

  testWidgets('TG-021 the explanation shows resting energy, activity, goal '
      'adjustment and daily/weekly target; floor and cap lines only when they '
      'apply', (tester) async {
    final calculation = calculationFor(loseDraft());
    await _pump(
      tester,
      formScreen(
        TargetExplanationView(
          calculation: calculation,
          activity: ActivityLevel.moderate,
          units: UnitSystem.metric,
          weeklyKcal: calculation.kcal * 7,
        ),
      ),
    );
    const resting =
        'Resting energy: about 1,850 kcal a day (from your weight, height, '
        'age and sex).';
    const goal =
        'Goal: lose 0.5 kg a week = 550 kcal less a day (about 7,700 kcal '
        'per kg).';
    for (final line in [
      resting,
      'Activity (moderately active): × 1.55 = about 2,868 kcal a day.',
      goal,
      'Your target: 2,318 kcal a day, 16,223 kcal a week.',
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    expect(find.textContaining('safety floor'), findsNothing);
    expect(find.textContaining('You asked for'), findsNothing);

    // Capped: the cap line, in lb for the imperial setting.
    final capped = calculationFor(loseDraft().copyWith(rate: '1.2'));
    await _pump(
      tester,
      formScreen(
        TargetExplanationView(
          calculation: capped,
          activity: ActivityLevel.moderate,
          units: UnitSystem.imperial,
        ),
      ),
    );
    expect(
      find.text(
        'You asked for 2.65 lb a week. Plans stay within 1% of your weight a '
        'week, so this plan uses 1.98 lb.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Goal: lose 1.98 lb a week = 990 kcal less a day (about 3,490 kcal '
        'per lb).',
      ),
      findsOneWidget,
    );
    expect(find.text('Your target: 1,878 kcal a day.'), findsOneWidget);
    expect(find.textContaining('safety floor'), findsNothing);

    // Below the floor: the floor line, no cap; no goal line when asked.
    final floored = floorCalculation();
    await _pump(
      tester,
      formScreen(
        TargetExplanationView(
          calculation: floored,
          activity: ActivityLevel.sedentary,
          units: UnitSystem.metric,
          showGoal: false,
        ),
      ),
    );
    expect(
      find.text('Raised to your safety floor of 1,200 kcal a day.'),
      findsOneWidget,
    );
    expect(find.textContaining('You asked for'), findsNothing);
    expect(find.textContaining('Goal:'), findsNothing);
    expect(find.text('Your target: 1,200 kcal a day.'), findsOneWidget);
  });

  testWidgets('TG-054 the macro summary shows every target and "No target" '
      'for carbs and fat in calories-and-protein-only', (tester) async {
    final plan = MacroPlan.calculate(baseKcal: 2000, weightKg: 80);
    await _pump(tester, formScreen(MacroSummary(macros: plan.forDay(2000))));
    expect(find.text('144 g'), findsOneWidget); // 1.8 g/kg
    expect(find.text('67 g'), findsOneWidget); // 30 % of 2,000 kcal
    expect(find.text('28 g'), findsOneWidget); // 14 g per 1,000 kcal
    final proteinOnly = MacroPlan.calculate(
      baseKcal: 2000,
      weightKg: 80,
      settings: MacroSettings(caloriesProteinOnly: true),
    );
    await _pump(
      tester,
      formScreen(MacroSummary(macros: proteinOnly.forDay(2000))),
    );
    expect(find.text('No target'), findsNWidgets(2));
  });

  testWidgets('TG-001 the activity options describe all four levels in '
      'plain words, none chosen until tapped', (tester) async {
    ActivityLevel? chosen;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => formScreen(
          ActivityOptions(
            selected: chosen,
            onSelected: (level) => setState(() => chosen = level),
          ),
        ),
      ),
    );
    for (final label in [
      'Mostly sitting',
      'Lightly active',
      'Moderately active',
      'Very active',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.text('An active job, or exercise 3 to 5 days a week'),
      findsOneWidget,
    );
    await tester.tap(find.text('Moderately active'));
    await tester.pump();
    expect(chosen, ActivityLevel.moderate);
  });

  test('A15 PA9 goalTypeLabel and goalPhaseLabel name goals; a named phase '
      'keeps its name', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(goalTypeLabel(l10n, GoalType.lose), 'Lose weight');
    expect(goalTypeLabel(l10n, GoalType.maintain), 'Maintain weight');
    expect(goalTypeLabel(l10n, GoalType.gain), 'Gain weight');
    final phase = GoalInput.maintain().toRecord(
      id: '0190a6f0-0000-7000-8000-000000000001',
      start: formToday,
    );
    expect(goalPhaseLabel(l10n, phase), 'Maintain weight');
    final named = GoalInput.maintain().toRecord(
      id: '0190a6f0-0000-7000-8000-000000000001',
      start: formToday,
      name: 'Summer',
    );
    expect(goalPhaseLabel(l10n, named), 'Summer');
    expect(goalFailureText(l10n, TargetsFailure.goalUnresolvable), isNotNull);
    expect(goalFailureText(l10n, TargetsFailure.goalNeedsUpdate), isNotNull);
    expect(goalFailureText(l10n, TargetsFailure.changed), isNull);
    expect(
      storedGoalProblemText(l10n, GoalProblem.deadline),
      'Your goal date has passed.',
    );
    expect(
      storedGoalProblemText(l10n, GoalProblem.targetNotAbove),
      "You've reached your target weight.",
    );
  });
}
