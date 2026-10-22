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

  @override
  String get todayAddFood => 'Add food';

  @override
  String get foodSearchTitle => 'Add food';

  @override
  String get foodSearchHint => 'Search foods';

  @override
  String get foodSearchRecent => 'Recent';

  @override
  String get foodSearchEmptyTitle => 'Find a food';

  @override
  String get foodSearchEmptyMessage => 'Search in English, Arabic or Arabizi';

  @override
  String foodSearchNoMatchTitle(String query) {
    return 'No match for \"$query\"';
  }

  @override
  String get foodSearchNoMatchMessage => 'Try another name or spelling.';

  @override
  String get foodSearchPackNotReady =>
      'The food database isn\'t ready yet. Showing foods you\'ve logged before.';

  @override
  String get foodSearchFailed => 'Couldn\'t search just now. Try again.';

  @override
  String foodResultKcal(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return '$kcalString kcal';
  }

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitOz => 'oz';

  @override
  String get unitLb => 'lb';

  @override
  String get unitMl => 'ml';

  @override
  String get unitL => 'l';

  @override
  String get unitFlOz => 'fl oz';

  @override
  String get unitTbsp => 'tbsp';

  @override
  String get unitTsp => 'tsp';

  @override
  String unitCup(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cups',
      one: 'cup',
    );
    return '$_temp0';
  }

  @override
  String unitPiece(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pieces',
      one: 'piece',
    );
    return '$_temp0';
  }

  @override
  String unitLoaf(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'loaves',
      one: 'loaf',
    );
    return '$_temp0';
  }

  @override
  String unitPlate(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'plates',
      one: 'plate',
    );
    return '$_temp0';
  }

  @override
  String unitSmallPlate(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'small plates',
      one: 'small plate',
    );
    return '$_temp0';
  }

  @override
  String unitLargePlate(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'large plates',
      one: 'large plate',
    );
    return '$_temp0';
  }

  @override
  String unitGlass(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'glasses',
      one: 'glass',
    );
    return '$_temp0';
  }

  @override
  String unitSandwich(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sandwiches',
      one: 'sandwich',
    );
    return '$_temp0';
  }

  @override
  String unitDisc(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'discs',
      one: 'disc',
    );
    return '$_temp0';
  }

  @override
  String unitServing(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'servings',
      one: 'serving',
    );
    return '$_temp0';
  }

  @override
  String unitCan(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cans',
      one: 'can',
    );
    return '$_temp0';
  }

  @override
  String unitBowl(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bowls',
      one: 'bowl',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'slices',
      one: 'slice',
    );
    return '$_temp0';
  }

  @override
  String unitWedge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wedges',
      one: 'wedge',
    );
    return '$_temp0';
  }

  @override
  String unitContainer(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'containers',
      one: 'container',
    );
    return '$_temp0';
  }

  @override
  String unitLadle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ladles',
      one: 'ladle',
    );
    return '$_temp0';
  }

  @override
  String unitPortion(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portions',
      one: 'portion',
    );
    return '$_temp0';
  }

  @override
  String unitPortionSized(num count, double size, String unit) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String sizeString = sizeNumberFormat.format(size);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portions',
      one: 'portion',
    );
    return '$_temp0 ($sizeString $unit)';
  }

  @override
  String foodStateWord(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'raw': 'raw',
      'cooked': 'cooked',
      'dry': 'dry',
      'drained': 'drained',
      'fried': 'fried',
      'as_sold': 'as sold',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String foodResultServing(double amount, String unit) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString $unit';
  }

  @override
  String foodResultSubtitle(String name, String serving) {
    return '$name · $serving';
  }

  @override
  String foodSheetNames(String en, String ar) {
    return '$en · $ar';
  }

  @override
  String foodSheetState(String state) {
    return 'State: $state';
  }

  @override
  String get foodSheetSanityWarn =>
      'This food\'s calories don\'t quite match its protein, carbs and fat.';

  @override
  String foodSheetAmountLabel(String amount, String unit) {
    return 'Amount, $amount $unit';
  }

  @override
  String foodSheetKcal(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return '$kcalString kcal';
  }

  @override
  String get foodSheetNoKcal => '—';

  @override
  String foodSheetMacros(
    double protein,
    double carbs,
    double fat,
    double fiber,
  ) {
    final intl.NumberFormat proteinNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String proteinString = proteinNumberFormat.format(protein);
    final intl.NumberFormat carbsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String carbsString = carbsNumberFormat.format(carbs);
    final intl.NumberFormat fatNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fatString = fatNumberFormat.format(fat);
    final intl.NumberFormat fiberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String fiberString = fiberNumberFormat.format(fiber);

    return 'Protein $proteinString g · Carbs $carbsString g · Fat $fatString g · Fiber $fiberString g';
  }

  @override
  String foodSheetLogAs(String name) {
    return 'Log as $name';
  }

  @override
  String foodSheetYieldNote(
    int from,
    String fromState,
    int to,
    String toState,
  ) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String toString = toNumberFormat.format(to);

    return '$fromString g $fromState ≈ $toString g $toState';
  }

  @override
  String foodSheetSlot(String slot) {
    return 'Meal: $slot';
  }

  @override
  String get foodSheetSlotNone => 'No meal';

  @override
  String get foodSheetSlotTitle => 'Meal';

  @override
  String get foodSheetAdd => 'Add';

  @override
  String get foodSheetAddFailed => 'Couldn\'t add this food. Try again.';

  @override
  String get foodSheetLoadFailed => 'Couldn\'t open this food. Try again.';

  @override
  String get foodSheetPer100g => 'Per 100 g';

  @override
  String get foodSheetPer100ml => 'Per 100 ml';

  @override
  String get foodSheetMore => 'More';

  @override
  String get foodSheetLess => 'Less';

  @override
  String get foodNutrientEnergy => 'Calories';

  @override
  String get foodNutrientProtein => 'Protein';

  @override
  String get foodNutrientCarbs => 'Carbs';

  @override
  String get foodNutrientFat => 'Fat';

  @override
  String get foodNutrientFiber => 'Fiber';

  @override
  String get foodNutrientSugar => 'Sugar';

  @override
  String get foodNutrientSaturatedFat => 'Saturated fat';

  @override
  String get foodNutrientTransFat => 'Trans fat';

  @override
  String get foodNutrientSodium => 'Sodium';

  @override
  String get foodNutrientCholesterol => 'Cholesterol';

  @override
  String get foodNutrientAlcohol => 'Alcohol';

  @override
  String foodNutrientGrams(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString g';
  }

  @override
  String foodNutrientMilligrams(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString mg';
  }

  @override
  String foodLoggedMessage(String name, String meal) {
    return 'Added $name to $meal';
  }

  @override
  String get foodSearchNotReadyTitle => 'Nothing to search yet';

  @override
  String get foodSearchNotReadyMessage =>
      'The food database isn\'t ready yet. Foods you log will show up here.';

  @override
  String get foodTryAgain => 'Try again';

  @override
  String get foodSheetClose => 'Close';
}
