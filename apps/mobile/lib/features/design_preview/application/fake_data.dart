// The constants are sample data, documented by the class docs.
// ignore_for_file: public_member_api_docs

import 'package:fb_design_system/fb_design_system.dart';

/// Fake content of the mockups (A02 D15): food names and pre-formatted
/// numbers, as data and not UI strings. Numbers are formatted here the way
/// the app will format them (LC-004), so the design system never formats.
abstract final class FakeData {
  /// The range every placeholder chart is given (the chart draws nothing yet).
  static final FbChartRange chartRange = FbChartRange(
    start: DateTime(2026, 7, 10),
    end: DateTime(2026, 10, 10),
  );

  // Today (spec/16 §1).
  static const String dateLabel = 'Sat 10 Oct';
  static const String kcalLeft = '1,240';
  static const double eaten = 1560;
  static const double budget = 2800;
  static const String eatenText = '1,560';
  static const String budgetText = '2,800';
  static const String weekUnder = '350';
  static const String toConfirmCount = '1';
  static const String toConfirmKcal = '251';
  static const String weightTrend = '97.6';
  static const String weightRate = '−0.4';
  static const String workoutName = 'Push day';

  static const List<FakeMacro> macros = [
    FakeMacro(FbMacroKind.protein, 110, 180, '110 / 180 g'),
    FakeMacro(FbMacroKind.carbs, 140, 250, '140 / 250 g'),
    FakeMacro(FbMacroKind.fat, 45, 80, '45 / 80 g'),
    FakeMacro(FbMacroKind.fiber, 18, 30, '18 / 30 g'),
  ];

  static const List<FakeSlot> slots = [
    FakeSlot(
      FakeSlotKind.breakfast,
      '420',
      'Fried egg · Labaneh · لبنة · Taboon',
      hasEstimate: true,
    ),
    FakeSlot(FakeSlotKind.lunch, '780', 'Chicken shawarma · Salad'),
    FakeSlot(FakeSlotKind.snacks, '360', 'Banana · Almonds'),
    FakeSlot(FakeSlotKind.dinner, null, null),
  ];

  static const List<FbUnitOption> adjustUnits = [
    FbUnitOption(id: 'g', label: 'g'),
    FbUnitOption(id: 'tbsp', label: 'tbsp'),
    FbUnitOption(id: 'piece', label: 'piece'),
  ];

  static const List<String> quickAdds = [
    'The usual breakfast',
    'Coffee with milk',
  ];

  // Food proposal (spec/10 §4.1).
  static const String proposalTime = '08:40';
  static const String proposalDish = 'Fried egg';
  static const List<FakeItem> proposalItems = [
    FakeItem('Egg, large ×1', '50 g', '72', FbSource.database, 'g'),
    FakeItem('Olive oil', '1 tbsp', '119', FbSource.database, 'tbsp'),
    FakeItem('Labaneh · لبنة', '2 tbsp', '60', FbSource.estimate, 'tbsp'),
  ];
  static const String proposalQuestion = 'How much labaneh?';
  static const String proposalAssumption = 'Assumed all the oil was eaten';
  static const List<String> assumptionAlternatives = [
    'Assumed all the oil was eaten',
    'Half of the oil was left in the pan',
    'No oil, a non-stick pan',
  ];
  static const List<String> answerOptions = ['1 tbsp', '2 tbsp', '3 tbsp'];
  static const int defaultAnswer = 1;
  static const String estimateRange = '45 to 80 kcal';
  static const String estimateReason =
      'The amount of labaneh was not given, so a typical 2 tbsp serving is '
      'assumed.';
  static const String proposalKcal = '251';
  static const String proposalProtein = '9';
  static const String proposalCarbs = '3';
  static const String proposalFat = '22';
  static const String proposalFiber = '0';
  static const String todayAfterLeft = '989';

  // Edit proposal (UX-026, AI-050).
  static const String editSlotTime = '13:10';
  static const String editEntry = 'Chicken and rice';
  static const String editAmountBefore = '300 g';
  static const String editAmountAfter = '400 g';
  static const String editKcalBefore = '520';
  static const String editKcalAfter = '690';
  static const String editProteinBefore = '38 g';
  static const String editProteinAfter = '50 g';
  static const String editDayBefore = '1,240';
  static const String editDayAfter = '1,070';

  // Weight card (HM-005). The "now" weight everywhere is the trend, 97.6;
  // 97.6 - 85 = 12.6 to go, and 105 - 97.6 = 7.4 of 20 kg done.
  static const String weightLast = '97.4';
  static const String weightLastDate = 'Fri 9 Oct';
  static const String weightGoalToGo = '12.6';

  // Progress overview (IN-001).
  static const String weekRange = '5 to 11 Oct';
  static const String weekAvgKcal = '2,540';
  static const String weekBudgetKcal = '2,800';
  static const String weekDaysWithin = '5';
  static const String weekDaysLogged = '6';
  static const String weekProteinDays = '4';
  static const String weekFiberAvg = '21';
  static const String weekWeightChange = '−0.4';
  static const String weekWorkoutsDone = '3';
  static const String weekWorkoutsPlanned = '4';
  static const String weekReview =
      'Steady week. Protein was close on most days, and your trend is '
      'moving the way you planned.';
  static const String goalPhase = 'Cut';
  static const double goalStartKg = 105;
  static const double goalNowKg = 97.6;
  static const double goalTargetKg = 85;
  static const String goalNowText = '97.6 kg';
  static const String goalTargetText = '85 kg';
  static const String goalMonthDone = '1.5';
  static const String goalMonthTarget = '2';
}

class FakeMacro {
  const new(this.kind, this.value, this.target, this.text);
  final FbMacroKind kind;
  final double value;
  final double target;
  final String text;
}

enum FakeSlotKind { breakfast, lunch, snacks, dinner }

class FakeSlot {
  const new(this.kind, this.kcal, this.summary, {this.hasEstimate = false});
  final FakeSlotKind kind;

  /// Whether one of the items is an estimate (shows the `~` marker).
  final bool hasEstimate;

  /// Null for an empty slot.
  final String? kcal;
  final String? summary;
}

class FakeItem {
  const new(this.name, this.amount, this.kcal, this.source, this.unitId);
  final String name;
  final String amount;
  final String kcal;
  final FbSource source;

  /// The id of the unit in [FakeData.adjustUnits] the amount is in.
  final String unitId;
}
