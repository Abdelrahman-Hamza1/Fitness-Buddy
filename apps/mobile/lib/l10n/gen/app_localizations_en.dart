// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fitness Buddy';

  @override
  String get tabToday => 'Today';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabWorkouts => 'Workouts';

  @override
  String get tabMe => 'Me';

  @override
  String get todayPlaceholder =>
      'Tell Buddy what you ate and it shows up here.';

  @override
  String get progressPlaceholder =>
      'Charts appear after a few days of logging.';

  @override
  String get workoutsPlaceholder => 'Your workouts will show up here.';

  @override
  String get mePlaceholder => 'Your profile and settings will live here.';

  @override
  String get updateRequiredTitle => 'Update needed';

  @override
  String get updateRequiredBody =>
      'This version can\'t connect any more. Install the latest one to continue. Your data stays on your phone.';

  @override
  String get updateRequiredCheckAgain => 'Check again';

  @override
  String get updateRequiredChecking => 'Checking…';

  @override
  String get updateRequiredStillOld =>
      'Still on an older version. Install the new build, then check again.';

  @override
  String get updateRequiredCheckFailed => 'Couldn\'t check. Are you online?';

  @override
  String get todayEmptyTitle => 'Nothing logged yet';

  @override
  String get progressEmptyTitle => 'No data yet';

  @override
  String get workoutsEmptyTitle => 'No workouts yet';

  @override
  String get meEmptyTitle => 'Nothing to set up yet';

  @override
  String get meDesignPreview => 'Design preview';

  @override
  String get previewTitle => 'Design preview';

  @override
  String get previewTabMockups => 'Mockups';

  @override
  String get previewTabComponents => 'Components';

  @override
  String get previewTabTokens => 'Tokens';

  @override
  String get previewVariantLabel => 'Palette';

  @override
  String get previewVariantA => 'A';

  @override
  String get previewVariantB => 'B';

  @override
  String get previewModeLabel => 'Theme';

  @override
  String get previewModeLight => 'Light';

  @override
  String get previewModeDark => 'Dark';

  @override
  String get previewModeSystem => 'System';

  @override
  String get previewMockupToday => 'Today';

  @override
  String get previewMockupFoodProposal => 'Food proposal';

  @override
  String get previewMockupEditProposal => 'Edit proposal';

  @override
  String get previewMockupWeightCard => 'Weight card';

  @override
  String get previewMockupProgress => 'Progress';

  @override
  String get previewOpenSheet => 'Open sheet';

  @override
  String get previewOpenSourceLegend => 'Open source legend';

  @override
  String get previewOpenEstimateRange => 'Open estimate range';

  @override
  String get previewShowUndoSnackBar => 'Show undo snackbar';

  @override
  String get previewShowSnackBar => 'Show snackbar';

  @override
  String get previewTokensColors => 'Colours';

  @override
  String get previewTokensType => 'Type';

  @override
  String get previewTokensContrast => 'Contrast';

  @override
  String get previewTypeSample => 'Eat well, feel good';

  @override
  String get previewContrastPasses => 'Passes';

  @override
  String get previewContrastFails => 'Below the minimum';

  @override
  String get todayKcalLeft => 'kcal left today';

  @override
  String get todayKcalOver => 'kcal over today';

  @override
  String todayEatenOfBudget(String eaten, String budget) {
    return '$eaten / $budget kcal';
  }

  @override
  String todayWeekUnder(String amount) {
    return 'This week: $amount kcal under';
  }

  @override
  String todayWeekOver(String amount) {
    return 'This week: $amount kcal over';
  }

  @override
  String get todayMacroProtein => 'Protein';

  @override
  String get todayMacroCarbs => 'Carbs';

  @override
  String get todayMacroFat => 'Fat';

  @override
  String get todayMacroFiber => 'Fiber';

  @override
  String todayToConfirm(String count) {
    return '$count to confirm';
  }

  @override
  String todayToConfirmKcal(String kcal) {
    return '+$kcal kcal';
  }

  @override
  String get todayWeight => 'Weight';

  @override
  String todayWeightTrendRate(String trend, String rate) {
    return '$trend trend · $rate/wk';
  }

  @override
  String todayWorkoutHint(String name) {
    return '$name today';
  }

  @override
  String get todaySlotBreakfast => 'Breakfast';

  @override
  String get todaySlotLunch => 'Lunch';

  @override
  String get todaySlotSnacks => 'Snacks';

  @override
  String get todaySlotDinner => 'Dinner';

  @override
  String get todaySlotEmpty => 'Nothing logged yet';

  @override
  String get todaySlotNoKcal => '—';

  @override
  String get todayConfirmAll => 'Confirm all';

  @override
  String get todaySlotNoKcalSemantics => 'Nothing logged';

  @override
  String get todayQuickAddMore => 'Add food';

  @override
  String get todayInputHint => 'Tell Buddy what you ate…';

  @override
  String proposalSlotAtTime(String slot, String time) {
    return '$slot · $time';
  }

  @override
  String proposalItemKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String proposalTotalKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String proposalMacrosShort(
    String protein,
    String carbs,
    String fat,
    String fiber,
  ) {
    return 'Protein $protein g · Carbs $carbs g · Fat $fat g · Fiber $fiber g';
  }

  @override
  String proposalTodayAfter(String left) {
    return 'Today after this: $left left';
  }

  @override
  String get proposalDiscard => 'Discard';

  @override
  String get proposalLogIt => 'Log it';

  @override
  String get proposalApplyChange => 'Apply change';

  @override
  String get proposalAssumptionTitle => 'Change the assumption';

  @override
  String get proposalEditLabel => 'Change to your diary';

  @override
  String get proposalFieldAmount => 'Amount';

  @override
  String get proposalFieldCalories => 'Calories';

  @override
  String get proposalFieldProtein => 'Protein';

  @override
  String get proposalFieldLeftToday => 'Left today';

  @override
  String proposalChangeSemantics(String label, String before, String after) {
    return '$label: $before, now $after';
  }

  @override
  String get weightTitle => 'Weight';

  @override
  String get weightTrendCaption => 'kg trend';

  @override
  String weightRatePerWeek(String rate) {
    return '$rate kg per week';
  }

  @override
  String weightLastWeighIn(String value, String date) {
    return 'Last weigh-in: $value kg · $date';
  }

  @override
  String weightToGoal(String amount) {
    return '$amount kg to your goal';
  }

  @override
  String get weightRange => 'Last 3 months';

  @override
  String get weightLog => 'Log weigh-in';

  @override
  String get progressWeekTitle => 'This week';

  @override
  String get progressReviewTitle => 'Buddy\'s review';

  @override
  String get progressAvgCalories => 'Average calories';

  @override
  String progressAvgCaloriesValue(String avg, String budget) {
    return '$avg of $budget kcal';
  }

  @override
  String get progressDaysWithin => 'Days within target';

  @override
  String progressOutOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String get progressProteinDays => 'Protein target days';

  @override
  String get progressFiberAvg => 'Fiber average';

  @override
  String progressGrams(String amount) {
    return '$amount g';
  }

  @override
  String get progressWeightChange => 'Trend weight change';

  @override
  String progressKg(String amount) {
    return '$amount kg';
  }

  @override
  String get progressWorkouts => 'Workouts done';

  @override
  String get progressChartCalories => 'Calories';

  @override
  String get progressChartMacros => 'Macros';

  @override
  String get progressChartWeight => 'Weight';

  @override
  String get progressGoalTitle => 'Goal';

  @override
  String progressGoalPhase(String phase) {
    return 'Phase: $phase';
  }

  @override
  String progressGoalNowTarget(String now, String target) {
    return '$now now · $target target';
  }

  @override
  String progressGoalMonth(String done, String target) {
    return 'This month: $done of $target kg';
  }
}
