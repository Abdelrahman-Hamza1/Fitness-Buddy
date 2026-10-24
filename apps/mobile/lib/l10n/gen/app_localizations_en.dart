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
  String get progressPlaceholder =>
      'Charts appear after a few days of logging.';

  @override
  String get workoutsPlaceholder => 'Your workouts will show up here.';

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
  String get progressEmptyTitle => 'No data yet';

  @override
  String get workoutsEmptyTitle => 'No workouts yet';

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
  String get todaySlotEmpty => 'Nothing yet';

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

  @override
  String get diaryDateToday => 'Today';

  @override
  String get diaryDateYesterday => 'Yesterday';

  @override
  String get diaryKcalEaten => 'kcal eaten';

  @override
  String diaryBigKcal(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return '$kcalString';
  }

  @override
  String diaryMacroItem(String label, double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$label $valueString g';
  }

  @override
  String diaryKcal(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return '$kcalString kcal';
  }

  @override
  String get diaryEmptyTodayHint =>
      'A fresh day. Tap + on a meal to add your first food.';

  @override
  String get diaryEmptyPastHint =>
      'Nothing logged on this day. Forgot something? Tap + on a meal.';

  @override
  String get diaryEmptySearch => 'Search foods';

  @override
  String get diarySlotOther => 'Other';

  @override
  String diarySlotAddTooltip(String meal) {
    return 'Add food to $meal';
  }

  @override
  String diarySlotMacrosSemantics(
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

    return 'Protein $proteinString g, carbs $carbsString g, fat $fatString g, fiber $fiberString g';
  }

  @override
  String diarySlotMacros(
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

    return 'P $proteinString · C $carbsString · F $fatString · Fiber $fiberString';
  }

  @override
  String diaryGroupItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get diaryDelete => 'Delete';

  @override
  String get diaryMoveToAnotherMeal => 'Move to another meal';

  @override
  String get diaryMoveTitle => 'Move to';

  @override
  String get diaryMoveCurrent => 'Current meal';

  @override
  String diaryEntryDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String diaryEntryMoved(String name, String meal) {
    return 'Moved $name to $meal';
  }

  @override
  String get diaryItemChanged => 'That item was changed, so nothing was saved.';

  @override
  String get diaryActionFailed => 'Couldn\'t save that. Try again.';

  @override
  String get diaryLoadFailed => 'Couldn\'t load this day.';

  @override
  String get diaryDetailsAmount => 'Amount';

  @override
  String diaryDetailsAmountResolved(String input, String amount) {
    return '$input ($amount)';
  }

  @override
  String get diaryDetailsTime => 'Time';

  @override
  String get diaryDetailsSource => 'Source';

  @override
  String get diaryDetailsEstimateRange => 'Estimate range';

  @override
  String diaryDetailsEstimateRangeValue(int low, int high) {
    final intl.NumberFormat lowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lowString = lowNumberFormat.format(low);
    final intl.NumberFormat highNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String highString = highNumberFormat.format(high);

    return '$lowString–$highString kcal';
  }

  @override
  String get diaryDetailsAssumptions => 'Assumptions';

  @override
  String get diaryDetailsNutrition => 'Nutrition for this amount';

  @override
  String get diarySourceYours => 'Your own values';

  @override
  String get diarySourceDatabase => 'Food database';

  @override
  String get diarySourceReference => 'Reference dish';

  @override
  String get diarySourceEstimate => 'Estimate';

  @override
  String diarySourceEdited(String source) {
    return 'Your edit of $source values';
  }

  @override
  String get diaryUndoConflict => 'Couldn\'t undo, it was changed since.';

  @override
  String get diaryUndoExpired => 'Too late to undo.';

  @override
  String get todayInputHintSearch => 'Search for a food…';

  @override
  String get devComingSoon => 'Coming soon';

  @override
  String get diaryChipMeal => 'Meal';

  @override
  String get diaryChangeFood => 'Change food';

  @override
  String get diaryNutrientEditHint => 'Tap to change this value';

  @override
  String get diarySave => 'Save';

  @override
  String get diaryReload => 'Reload';

  @override
  String get diaryEntryRemoved => 'This item was removed.';

  @override
  String get diaryEntryChangedStale => 'This item changed.';

  @override
  String get diaryActionRemoved =>
      'That item was removed, so nothing was saved.';

  @override
  String diaryAmountChanged(String name, String amount) {
    return 'Changed $name to $amount';
  }

  @override
  String diaryTimeChanged(String name, String time) {
    return 'Changed the time of $name to $time';
  }

  @override
  String diaryNutrientEdited(String nutrient, String name) {
    return 'Edited $nutrient of $name';
  }

  @override
  String diaryOverrideTitle(String nutrient) {
    return 'Edit $nutrient';
  }

  @override
  String get diaryOverrideNote =>
      'Enter the value for this amount. The item is then marked as edited by you.';

  @override
  String diaryOverrideOutOfRange(String max, String unit) {
    return 'Enter $max $unit or less.';
  }

  @override
  String get diaryOverrideInvalid =>
      'Couldn\'t save that value. Check it and try again.';

  @override
  String diaryOverrideAmountLabel(String nutrient, String value, String unit) {
    return '$nutrient, $value $unit';
  }

  @override
  String get diaryUnitKcal => 'kcal';

  @override
  String get diaryUnitMg => 'mg';

  @override
  String diaryMealMenuTooltip(String meal) {
    return 'More for $meal';
  }

  @override
  String get diaryMealCopyAction => 'Copy to…';

  @override
  String get diaryMealSaveAction => 'Save as meal…';

  @override
  String diaryCopyTitle(String meal) {
    return 'Copy $meal';
  }

  @override
  String get diaryCopyDay => 'Day';

  @override
  String get diaryCopySlotTitle => 'Copy to meal';

  @override
  String get diaryCopyButton => 'Copy';

  @override
  String get diaryCopyChoose => 'Choose where to copy this meal.';

  @override
  String get diaryMealChanged => 'This meal changed.';

  @override
  String get diaryMealEmpty => 'This meal is empty now.';

  @override
  String get diaryMealChangedCopy => 'That meal changed. Nothing was copied.';

  @override
  String get diaryMealChangedSave => 'That meal changed. Nothing was saved.';

  @override
  String diaryMealCopied(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count items to $day',
      one: 'Copied 1 item to $day',
    );
    return '$_temp0';
  }

  @override
  String get diarySaveTitle => 'Save as meal';

  @override
  String get diarySaveName => 'Name';

  @override
  String get diarySaveNameEmpty => 'Give the meal a name.';

  @override
  String diaryMealSaved(String name) {
    return 'Saved \"$name\"';
  }

  @override
  String get foodSearchChangeTitle => 'Change food';

  @override
  String get foodSheetUseThis => 'Use this food';

  @override
  String foodChangedMessage(String name) {
    return 'Changed to $name';
  }

  @override
  String get diarySourceNounDatabase => 'food database';

  @override
  String get diarySourceNounReference => 'reference dish';

  @override
  String get diarySourceNounEstimate => 'estimate';

  @override
  String get diarySourceYoursEdited => 'Your own values, edited';

  @override
  String get diaryOverrideTitleEnergy => 'Edit calories';

  @override
  String get diaryAmountNeeded => 'Enter an amount above 0.';

  @override
  String get diaryValueNeeded => 'Enter a value.';

  @override
  String diaryMealSummary(int count, int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items · $kcalString kcal',
      one: '1 item · $kcalString kcal',
    );
    return '$_temp0';
  }

  @override
  String foodSearchReplacing(String name) {
    return 'Replacing $name';
  }

  @override
  String get meSectionFood => 'Food';

  @override
  String get meYourFoods => 'Your foods';

  @override
  String get yourFoodsTitle => 'Your foods';

  @override
  String get yourFoodsNew => 'New food';

  @override
  String get yourFoodsEmptyTitle => 'No foods of your own yet';

  @override
  String get yourFoodsEmptyMessage =>
      'Add a food you eat often with the numbers from its label. It shows up first in search.';

  @override
  String get yourFoodsLoadFailed => 'Couldn\'t load your foods. Try again.';

  @override
  String yourFoodsKcalPer(int kcal, String basis) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return '$kcalString kcal per $basis';
  }

  @override
  String get personalFoodBasis100g => '100 g';

  @override
  String get personalFoodBasis100ml => '100 ml';

  @override
  String get personalFoodBasisServing => 'One serving';

  @override
  String get personalFoodNewTitle => 'New food';

  @override
  String get personalFoodEditTitle => 'Edit food';

  @override
  String get personalFoodMenuTooltip => 'More options';

  @override
  String get personalFoodLoadFailed => 'Couldn\'t open this food. Try again.';

  @override
  String get personalFoodDeletedBanner => 'This food was deleted.';

  @override
  String get personalFoodChangedBanner => 'This food changed.';

  @override
  String get personalFoodReload => 'Reload';

  @override
  String get personalFoodSave => 'Save';

  @override
  String get personalFoodSaveChanged =>
      'This food changed elsewhere. Reload to see the latest. What you typed stays.';

  @override
  String get personalFoodSaveRemoved =>
      'This food was deleted, so nothing was saved.';

  @override
  String get personalFoodSaveFailed =>
      'Couldn\'t save that. Check the numbers and try again.';

  @override
  String get personalFoodFixFields =>
      'Some fields need a look. They\'re marked below.';

  @override
  String personalFoodSavedMessage(String name) {
    return 'Saved $name';
  }

  @override
  String personalFoodDeletedMessage(String name) {
    return 'Deleted $name';
  }

  @override
  String personalFoodsMergedMessage(String merged, String survivor) {
    return 'Merged $merged into $survivor';
  }

  @override
  String personalFoodsMergedSameName(String survivor) {
    return 'Merged into $survivor';
  }

  @override
  String get personalFoodMenuMerge => 'Merge a duplicate into this food…';

  @override
  String get personalFoodMenuDelete => 'Delete food';

  @override
  String get personalFoodNameLabel => 'Name';

  @override
  String get personalFoodNameArLabel => 'Arabic name (optional)';

  @override
  String get personalFoodAliasesLabel => 'Other names (optional)';

  @override
  String get personalFoodAliasesHint =>
      'Separate with commas, like labne, lab6a';

  @override
  String get personalFoodBrandLabel => 'Brand (optional)';

  @override
  String get personalFoodBarcodesLabel => 'Barcodes (optional)';

  @override
  String get personalFoodBarcodesHint => 'Digits, separated by commas';

  @override
  String personalFoodDuplicate(String name) {
    return 'You already have $name';
  }

  @override
  String get personalFoodSectionServings => 'Servings';

  @override
  String get personalFoodValuesPer => 'The label\'s numbers are for';

  @override
  String get personalFoodNumbersStay => 'Numbers stay as typed.';

  @override
  String personalFoodServingShownAs(String serving, double size, String unit) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Shown in your diary as 1 $serving ($sizeString $unit)';
  }

  @override
  String get personalFoodServingSizeSemantics =>
      'Size of the serving on the label';

  @override
  String personalFoodServingRowSemantics(String serving) {
    return 'Size of one $serving';
  }

  @override
  String get personalFoodServingInGrams => 'Serving size in grams';

  @override
  String get personalFoodServingInMl => 'Serving size in millilitres';

  @override
  String get personalFoodMoreDetails => 'More details';

  @override
  String get personalFoodServingSize => 'Serving size';

  @override
  String get personalFoodServingCalled => 'Serving called';

  @override
  String get personalFoodServingUnitTitle => 'Serving name';

  @override
  String get personalFoodUnitKcal => 'kcal';

  @override
  String get personalFoodUnitMg => 'mg';

  @override
  String get personalFoodFiberHint => 'Blank counts as 0';

  @override
  String get personalFoodExtraHint => 'Leave blank if you don\'t know';

  @override
  String get personalFoodMoreNutrients => 'More nutrients';

  @override
  String get personalFoodStateLabel => 'State';

  @override
  String personalFoodStateChoice(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'raw': 'Raw',
      'cooked': 'Cooked',
      'dry': 'Dry',
      'drained': 'Drained',
      'fried': 'Fried',
      'as_sold': 'As sold',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get personalFoodServingsHint =>
      'Add the portions you use, like a piece or a cup, with their size.';

  @override
  String get personalFoodAddServing => 'Add serving';

  @override
  String get personalFoodRemoveServing => 'Remove serving';

  @override
  String get personalFoodErrorRequired => 'Fill this in.';

  @override
  String get personalFoodErrorNumber => 'Use a number like 12.5.';

  @override
  String get personalFoodErrorBounds => 'That\'s more than a food can hold.';

  @override
  String get personalFoodErrorTooSmall =>
      'That\'s too small to save. Use 0 or a bigger number.';

  @override
  String get personalFoodErrorText => 'That\'s too long. Shorten it.';

  @override
  String get personalFoodErrorBarcode =>
      'Check this barcode. It should have 8, 12, 13 or 14 digits.';

  @override
  String get personalFoodErrorServing =>
      'Give each serving a different name and a size from 0.1 to 5,000.';

  @override
  String get personalFoodErrorImpossible =>
      'Those numbers are higher than any food can have. Check them against the label.';

  @override
  String personalFoodSanityWarn(int expected) {
    final intl.NumberFormat expectedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String expectedString = expectedNumberFormat.format(expected);

    return 'These numbers don\'t quite add up: protein, carbs and fat give about $expectedString kcal. Check the label, or save anyway.';
  }

  @override
  String get personalFoodDiscardTitle => 'Discard changes?';

  @override
  String get personalFoodDiscardMessage =>
      'You\'ve changed this food but haven\'t saved it.';

  @override
  String get personalFoodDiscardKeep => 'Keep editing';

  @override
  String get personalFoodDiscardConfirm => 'Discard';

  @override
  String get personalFoodMergeTitle => 'Merge a duplicate';

  @override
  String personalFoodMergePickMessage(String name) {
    return 'Choose the duplicate. It goes into $name.';
  }

  @override
  String personalFoodMergeNone(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'ml': 'You have no other food in millilitres to merge.',
      'other': 'You have no other food in grams to merge.',
    });
    return '$_temp0';
  }

  @override
  String get personalFoodMergeConfirmTitle => 'Merge these foods?';

  @override
  String personalFoodMergeConfirmMessage(String keep, String other) {
    return '$keep stays, with its numbers. $other is removed. Its names are added to $keep, and anything you logged with it now uses $keep. Numbers already logged don\'t change.';
  }

  @override
  String get personalFoodMergeStays => 'Stays';

  @override
  String get personalFoodMergeGoes => 'Merged in and removed';

  @override
  String personalFoodMergeRowSubtitle(String role, String kcal) {
    return '$role · $kcal';
  }

  @override
  String get personalFoodMergeSwap => 'Keep the other one instead';

  @override
  String get personalFoodMergeConfirm => 'Merge';

  @override
  String get personalFoodMergeChanged =>
      'One of these foods changed, so nothing was merged. Reload to see the latest.';

  @override
  String get personalFoodMergeRemoved =>
      'One of these foods was deleted, so nothing was merged.';

  @override
  String get personalFoodMergeTooMany =>
      'Together they\'d have too many names, barcodes or servings. Remove some first.';

  @override
  String get personalFoodMergeBasis =>
      'These foods are measured differently (grams and millilitres).';

  @override
  String get personalFoodMergeFailed =>
      'Couldn\'t merge these foods. Try again.';

  @override
  String foodSearchCreate(String query) {
    return 'Create \"$query\" as your own food';
  }

  @override
  String get foodSheetAddChanged =>
      'This food changed, so nothing was logged. Pick it again.';

  @override
  String get foodSheetReplaceChanged =>
      'This food changed, so nothing was changed. Pick it again.';
}
