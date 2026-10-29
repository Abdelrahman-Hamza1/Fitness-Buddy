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
  String get todayWeekOnTrack => 'This week: on track';

  @override
  String todayWeekUncounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days not counted',
      one: '1 day not counted',
    );
    return '$_temp0';
  }

  @override
  String todayWeekWithUncounted(String line, String uncounted) {
    return '$line · $uncounted';
  }

  @override
  String todayEatenOfBudgetSemantics(String eaten, String budget) {
    return '$eaten of $budget kcal eaten';
  }

  @override
  String todayMacroOfTarget(double eaten, int target) {
    final intl.NumberFormat eatenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eatenString = eatenNumberFormat.format(eaten);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$eatenString / $targetString g';
  }

  @override
  String todayMacroEaten(double eaten) {
    final intl.NumberFormat eatenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eatenString = eatenNumberFormat.format(eaten);

    return '$eatenString g';
  }

  @override
  String get todaySetupTitle => 'Set up your targets';

  @override
  String get todaySetupTime => 'About 2 minutes';

  @override
  String get todayUpdateSubtitle => 'Your profile needs a newer version';

  @override
  String get todayTargetsLoadFailed => 'Couldn\'t load your targets.';

  @override
  String get todayTargetsTryAgain => 'Try again';

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
  String weightValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get weightUnitKg => 'kg';

  @override
  String get weightUnitLb => 'lb';

  @override
  String weightCardRate(String rate, String unit) {
    return '$rate $unit/week';
  }

  @override
  String weightCardTrend(String weight) {
    return 'Trend $weight';
  }

  @override
  String get weightCardRateLater => 'Weekly rate after 2 weeks of weigh-ins';

  @override
  String weightCardTrendFrom(String weight, String date) {
    return 'Trend $weight · from $date';
  }

  @override
  String weightCardLast(String weight, String when) {
    return 'Last weigh-in $weight · $when';
  }

  @override
  String weightCardLastValue(String weight) {
    return 'Last weigh-in $weight';
  }

  @override
  String get weightCardEmpty => 'Log your first weigh-in';

  @override
  String get weightCardEmptyPast => 'No weigh-ins by this day. Tap to add one.';

  @override
  String weightCardSparse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weigh-ins in 4 weeks · trend updates slowly',
      one: '1 weigh-in in 4 weeks · trend updates slowly',
    );
    return '$_temp0';
  }

  @override
  String get weightCardTip =>
      'Weighing in 2–3 times a week makes the trend steadier.';

  @override
  String get weightCardTipDismiss => 'Got it';

  @override
  String get weightCardLoadFailed => 'Couldn\'t load your weigh-ins.';

  @override
  String get weightCardTryAgain => 'Try again';

  @override
  String weightSpokenKg(String value) {
    return '$value kilograms';
  }

  @override
  String weightSpokenLb(String value) {
    return '$value pounds';
  }

  @override
  String weightCardTrendSemantics(String weight) {
    return 'Weight trend $weight';
  }

  @override
  String weightCardTrendRateSemantics(String weight, String change) {
    return 'Weight trend $weight, $change per week';
  }

  @override
  String weightCardTrendFromSemantics(String weight, String date) {
    return 'Weight trend $weight, from $date';
  }

  @override
  String weightCardLastSemantics(String weight, String when) {
    return 'Last weigh-in $weight, $when';
  }

  @override
  String weightCardLastValueSemantics(String weight) {
    return 'Last weigh-in $weight';
  }

  @override
  String weightCardEmptySemantics(String message) {
    return 'Weight. $message';
  }

  @override
  String weightCardLogSemantics(String summary) {
    return '$summary. Log a weigh-in';
  }

  @override
  String weightCardLogNoteSemantics(String summary, String note) {
    return '$summary. $note. Log a weigh-in';
  }

  @override
  String weightCardEditSemantics(String summary) {
    return '$summary. Edit';
  }

  @override
  String get weighInSheetTitle => 'Log weigh-in';

  @override
  String get weighInEditTitle => 'Edit weigh-in';

  @override
  String get weighInSave => 'Save';

  @override
  String get weighInDelete => 'Delete weigh-in';

  @override
  String weighInValueSemantics(String weight) {
    return 'Weight, $weight';
  }

  @override
  String get weighInWhenLabel => 'When';

  @override
  String weighInDayTime(String day, String time) {
    return '$day, $time';
  }

  @override
  String get weighInAddNote => 'Add a note';

  @override
  String get weighInNoteLabel => 'Note';

  @override
  String get weighInNoteHint => 'e.g. after Eid';

  @override
  String weighInNoteTooLong(int max) {
    return 'Keep the note to $max characters';
  }

  @override
  String get weighInNoteInvalid =>
      'The note has a character that can\'t be saved';

  @override
  String weighInOutOfRange(String min, String max) {
    return 'Enter a weight between $min and $max';
  }

  @override
  String get weighInFuture =>
      'This time is in the future. Choose an earlier time.';

  @override
  String get weighInTooEarly => 'Choose a date from 1970 on.';

  @override
  String weighInConfirmChange(String diff, String when, String weight) {
    return 'That\'s $diff from your weigh-in $when ($weight). Save it?';
  }

  @override
  String weighInConfirmSaveValue(String weight) {
    return 'Save $weight';
  }

  @override
  String get weighInConfirmEdit => 'Edit';

  @override
  String weighInConfirmUnit(String weight, String converted) {
    return 'Did you mean $weight ($converted)?';
  }

  @override
  String weighInSaveAsUnit(String weight) {
    return 'Save as $weight';
  }

  @override
  String weighInKeepUnit(String unit) {
    return 'Keep $unit';
  }

  @override
  String weighInSameDay(String weight, String time) {
    return 'Also on this day: $weight at $time';
  }

  @override
  String weighInSameDayUsed(String weight, String time) {
    return 'Also on this day: $weight at $time · used for the trend';
  }

  @override
  String get weighInUseForTrend => 'Use this weigh-in for the trend';

  @override
  String weighInSaved(String weight) {
    return 'Weigh-in saved: $weight';
  }

  @override
  String weighInUpdated(String weight) {
    return 'Weigh-in updated: $weight';
  }

  @override
  String get weighInDeleted => 'Weigh-in deleted';

  @override
  String get weighInTrendChosen => 'Trend weigh-in for the day changed';

  @override
  String get weighInChanged =>
      'This weigh-in changed since you opened it. Reload to see the latest. What you typed stays.';

  @override
  String get weighInReload => 'Reload';

  @override
  String get weighInDayChanged =>
      'Other weigh-ins on this day changed. Check the trend choice and save again.';

  @override
  String get weighInRemoved => 'This weigh-in was deleted.';

  @override
  String get weighInSaveFailed => 'Couldn\'t save the weigh-in. Try again.';

  @override
  String get weighInLoadFailed => 'Couldn\'t load your weigh-ins.';

  @override
  String get weighInTryAgain => 'Try again';

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
  String get setupTitle => 'Set up your targets';

  @override
  String setupStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get setupClose => 'Close setup';

  @override
  String get setupBack => 'Back';

  @override
  String get setupNext => 'Next';

  @override
  String get setupSave => 'Save';

  @override
  String get setupPageYou => 'About you';

  @override
  String get setupPageActivity => 'How active are you?';

  @override
  String get setupPageGoal => 'Your goal';

  @override
  String get setupPagePreferences => 'Preferences';

  @override
  String get setupPageTargets => 'Your targets';

  @override
  String get setupWeightHint => 'Saved as your first weigh-in.';

  @override
  String get setupActivityHint => 'Pick the one closest to a usual week.';

  @override
  String get setupPreferencesHint =>
      'These are filled in from your settings. You can change them here or later in Me.';

  @override
  String setupTargetsDaily(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return '$kcalString kcal a day';
  }

  @override
  String setupTargetsWeekly(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return '$kcalString kcal a week';
  }

  @override
  String get setupTargetsHow => 'How it\'s calculated';

  @override
  String get setupTargetsMacros => 'Macros';

  @override
  String get setupTargetsMode =>
      'Your weekly budget adjusts the rest of the week when a day is over or under. You can change this later in Me.';

  @override
  String get setupLeaveTitle => 'Leave setup?';

  @override
  String get setupLeaveMessage => 'What you entered won\'t be saved.';

  @override
  String get setupLeaveStay => 'Keep going';

  @override
  String get setupLeaveConfirm => 'Leave';

  @override
  String get setupSaved => 'Targets set';

  @override
  String get setupAlreadySetUp => 'Your targets are already set up.';

  @override
  String get setupSaveFailed =>
      'Couldn\'t save your targets. Nothing you entered was lost. Try Save again.';

  @override
  String get setupUpdateTitle => 'Update the app';

  @override
  String get setupUpdateMessage =>
      'Your profile was saved by a newer version of Fitness Buddy. Update the app to see and change it.';

  @override
  String get profileSexLabel => 'Sex';

  @override
  String get profileSexHint => 'Used for the energy formula';

  @override
  String get profileSexMale => 'Male';

  @override
  String get profileSexFemale => 'Female';

  @override
  String get profileBirthYearLabel => 'Birth year';

  @override
  String profileBirthYearRange(int min, int max) {
    return 'Enter a year between $min and $max.';
  }

  @override
  String get profileHeightLabel => 'Height';

  @override
  String get profileHeightUnitCm => 'cm';

  @override
  String get profileHeightUnitFtIn => 'ft + in';

  @override
  String get profileHeightFeet => 'Feet';

  @override
  String get profileHeightInches => 'Inches';

  @override
  String get profileUnitCm => 'cm';

  @override
  String get profileUnitFt => 'ft';

  @override
  String get profileUnitIn => 'in';

  @override
  String profileHeightRangeCm(int min, int max) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Enter a height between $minString and $maxString cm.';
  }

  @override
  String profileHeightRangeFtIn(
    int minFeet,
    int minInches,
    int maxFeet,
    int maxInches,
  ) {
    return 'Enter a height between $minFeet ft $minInches in and $maxFeet ft $maxInches in. Inches go up to 11.';
  }

  @override
  String get profileWeightLabel => 'Current weight';

  @override
  String targetsWeightRange(double min, double max, String unit) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Enter a weight between $minString and $maxString $unit.';
  }

  @override
  String targetsMassValue(String amount, String unit) {
    return '$amount $unit';
  }

  @override
  String get targetsEnterNumber => 'Enter a number.';

  @override
  String get profileActivitySedentary => 'Mostly sitting';

  @override
  String get profileActivitySedentaryHint =>
      'Desk work, little walking and no regular exercise';

  @override
  String get profileActivityLight => 'Lightly active';

  @override
  String get profileActivityLightHint =>
      'On your feet part of the day, or light exercise 1 to 3 days a week';

  @override
  String get profileActivityModerate => 'Moderately active';

  @override
  String get profileActivityModerateHint =>
      'An active job, or exercise 3 to 5 days a week';

  @override
  String get profileActivityHigh => 'Very active';

  @override
  String get profileActivityHighHint =>
      'Hard exercise 6 or 7 days a week, or a physical job';

  @override
  String get profileActivityShortSedentary => 'mostly sitting';

  @override
  String get profileActivityShortLight => 'lightly active';

  @override
  String get profileActivityShortModerate => 'moderately active';

  @override
  String get profileActivityShortHigh => 'very active';

  @override
  String get targetsChooseOne => 'Choose one to continue.';

  @override
  String get goalTypeTitle => 'What do you want to do?';

  @override
  String get goalTypeLose => 'Lose weight';

  @override
  String get goalTypeMaintain => 'Maintain weight';

  @override
  String get goalTypeGain => 'Gain weight';

  @override
  String get goalHow => 'How do you want to set it?';

  @override
  String get goalKindWeekly => 'Per week';

  @override
  String get goalKindMonthly => 'This month';

  @override
  String get goalKindTargetDate => 'Target weight by a date';

  @override
  String get goalKindTargetRate => 'Target weight at a pace';

  @override
  String get goalRateLoseLabel => 'Lose each week';

  @override
  String get goalRateGainLabel => 'Gain each week';

  @override
  String get goalMonthLoseLabel => 'Lose this month';

  @override
  String get goalMonthGainLabel => 'Gain this month';

  @override
  String get goalTargetWeightLabel => 'Target weight';

  @override
  String get goalTargetDateLabel => 'By';

  @override
  String get goalTargetDatePick => 'Pick a date';

  @override
  String get goalTargetDateMissing => 'Pick a target date.';

  @override
  String get goalTargetDateTooFar => 'Pick a date within 5 years.';

  @override
  String get goalPaceLabel => 'Pace each week';

  @override
  String goalRateRange(double max, String unit) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Enter an amount up to $maxString $unit a week.';
  }

  @override
  String goalMonthRange(double max, String unit) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Enter an amount up to $maxString $unit this month.';
  }

  @override
  String goalProjection(String rate, String change, String month) {
    return '≈ $rate a week · $change in $month';
  }

  @override
  String goalProjectionWithDate(
    String rate,
    String change,
    String month,
    String date,
  ) {
    return '≈ $rate a week · $change in $month · goal reached around $date';
  }

  @override
  String get goalMaintainNote => 'Your target keeps your weight steady.';

  @override
  String goalCapMessage(String requested, String planned) {
    return 'You asked for $requested a week. Plans stay within 1% of your weight a week, so this plan uses $planned.';
  }

  @override
  String get goalProblemDeadline => 'Pick a date after today.';

  @override
  String get goalProblemTargetNotBelow =>
      'This target weight isn\'t below your current weight. Choose a lower target, or another goal.';

  @override
  String get goalProblemTargetNotAbove =>
      'This target weight isn\'t above your current weight. Choose a higher target, or another goal.';

  @override
  String get goalStoredDatePassed => 'Your goal date has passed.';

  @override
  String get goalStoredTargetReached => 'You\'ve reached your target weight.';

  @override
  String get goalFailedUnresolvable =>
      'This goal doesn\'t fit your current weight. Check the target weight and date.';

  @override
  String get goalFailedNeedsUpdate =>
      'Your current goal needs an update. Start a new goal to recalculate.';

  @override
  String targetsExplainResting(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return 'Resting energy: about $kcalString kcal a day (from your weight, height, age and sex).';
  }

  @override
  String targetsExplainActivity(String level, double factor, int kcal) {
    final intl.NumberFormat factorNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String factorString = factorNumberFormat.format(factor);
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return 'Activity ($level): × $factorString = about $kcalString kcal a day.';
  }

  @override
  String targetsExplainGoalLose(
    String rate,
    int kcal,
    int perUnit,
    String unit,
  ) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);
    final intl.NumberFormat perUnitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String perUnitString = perUnitNumberFormat.format(perUnit);

    return 'Goal: lose $rate a week = $kcalString kcal less a day (about $perUnitString kcal per $unit).';
  }

  @override
  String targetsExplainGoalGain(
    String rate,
    int kcal,
    int perUnit,
    String unit,
  ) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);
    final intl.NumberFormat perUnitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String perUnitString = perUnitNumberFormat.format(perUnit);

    return 'Goal: gain $rate a week = $kcalString kcal more a day (about $perUnitString kcal per $unit).';
  }

  @override
  String get targetsExplainGoalMaintain =>
      'Goal: keep your weight steady, so nothing is added or taken away.';

  @override
  String targetsExplainFloor(int kcal) {
    final intl.NumberFormat kcalNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kcalString = kcalNumberFormat.format(kcal);

    return 'Raised to your safety floor of $kcalString kcal a day.';
  }

  @override
  String targetsExplainTarget(int daily, int weekly) {
    final intl.NumberFormat dailyNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dailyString = dailyNumberFormat.format(daily);
    final intl.NumberFormat weeklyNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weeklyString = weeklyNumberFormat.format(weekly);

    return 'Your target: $dailyString kcal a day, $weeklyString kcal a week.';
  }

  @override
  String targetsExplainTargetDaily(int daily) {
    final intl.NumberFormat dailyNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dailyString = dailyNumberFormat.format(daily);

    return 'Your target: $dailyString kcal a day.';
  }

  @override
  String targetsMacroGrams(int grams) {
    final intl.NumberFormat gramsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String gramsString = gramsNumberFormat.format(grams);

    return '$gramsString g';
  }

  @override
  String get targetsMacroNoTarget => 'No target';

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
    String from,
    String fromState,
    String to,
    String toState,
  ) {
    return '$from $fromState ≈ $to $toState';
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
  String get diaryDateTodayInline => 'today';

  @override
  String get diaryDateYesterdayInline => 'yesterday';

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
  String foodAmountWithCanonical(String amount, String canonical) {
    return '$amount ($canonical)';
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
  String get meSectionYou => 'You';

  @override
  String get meSetUpTargets => 'Set up profile & targets';

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
  String personalFoodServingShownAs(String serving, String size) {
    return 'Shown in your diary as 1 $serving ($size)';
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

  @override
  String get meSavedMeals => 'Saved meals';

  @override
  String get savedMealsTitle => 'Saved meals';

  @override
  String get savedMealsEmptyTitle => 'No saved meals yet';

  @override
  String get savedMealsEmptyMessage =>
      'Open a meal\'s menu on Today and choose Save as meal.';

  @override
  String get savedMealsLoadFailed =>
      'Couldn\'t load your saved meals. Try again.';

  @override
  String get savedMealDefaultTitle => 'Saved meal';

  @override
  String get savedMealItemsHeader => 'Items';

  @override
  String get savedMealPickMealTitle => 'Log to meal';

  @override
  String savedMealItemSubtitle(String amount, String kcal) {
    return '$amount · $kcal';
  }

  @override
  String get savedMealLogButton => 'Log';

  @override
  String get savedMealNoItems => 'This meal has no items.';

  @override
  String get savedMealRenameTooltip => 'Rename meal';

  @override
  String get savedMealRenameTitle => 'Rename meal';

  @override
  String get savedMealMenuTooltip => 'More for this meal';

  @override
  String get savedMealDeleteAction => 'Delete meal';

  @override
  String savedMealRenamedMessage(String name) {
    return 'Renamed to \"$name\"';
  }

  @override
  String savedMealDeletedMessage(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get savedMealGone => 'This saved meal was deleted.';

  @override
  String get savedMealRenameGone =>
      'This meal was deleted, so it can\'t be renamed.';

  @override
  String get savedMealRenameChanged =>
      'This meal was renamed. Reload to see its new name.';

  @override
  String get savedMealChangedRename =>
      'That meal changed. Nothing was renamed.';

  @override
  String get savedMealChangedDelete =>
      'That meal changed. Nothing was deleted.';

  @override
  String quickAddLoggedAmount(String name, String amount) {
    return 'Logged $name, $amount';
  }

  @override
  String quickAddLoggedItems(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Logged $name, $_temp0';
  }

  @override
  String quickAddLoggedOn(String message, String day) {
    return '$message for $day';
  }

  @override
  String get quickAddChanged => 'That changed. Nothing was logged.';

  @override
  String quickAddChipSemantics(String name) {
    return 'Log $name';
  }

  @override
  String quickAddSavedMealChipSemantics(String name) {
    return 'Log saved meal $name';
  }

  @override
  String get quickAddRowSemantics => 'Quick add';

  @override
  String get meSectionSettings => 'Settings';

  @override
  String get meSectionYourData => 'Your data';

  @override
  String get meExportData => 'Export your data';

  @override
  String get meSectionAbout => 'About';

  @override
  String get meSectionDeveloper => 'Developer';

  @override
  String get meAbout => 'About Fitness Buddy';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsUnitsMetric => 'Metric';

  @override
  String get settingsUnitsMetricHint => 'Grams, millilitres, kilograms';

  @override
  String get settingsUnitsImperial => 'Imperial';

  @override
  String get settingsUnitsImperialHint => 'Ounces, fluid ounces, pounds';

  @override
  String get settingsWeekStart => 'Week starts on';

  @override
  String get settingsHalal => 'Halal food';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsCity => 'City';

  @override
  String get settingsCityNotSet => 'Not set';

  @override
  String get settingsEnergy => 'Energy';

  @override
  String get settingsUnitsSetMetric => 'Units set to metric';

  @override
  String get settingsUnitsSetImperial => 'Units set to imperial';

  @override
  String settingsWeekStartSet(String day) {
    return 'Week now starts on $day';
  }

  @override
  String get settingsHalalSetOn => 'Halal food turned on';

  @override
  String get settingsHalalSetOff => 'Halal food turned off';

  @override
  String settingsThemeSet(String theme) {
    return 'Theme set to $theme';
  }

  @override
  String settingsCitySet(String city) {
    return 'City set to $city';
  }

  @override
  String get settingsSaveFailed => 'Couldn\'t save that setting. Try again.';

  @override
  String get cityPickerTitle => 'City';

  @override
  String get cityPickerSearchHint => 'Search for a city';

  @override
  String get cityPickerSuggested => 'Suggested cities';

  @override
  String get cityPickerLoadFailed => 'Couldn\'t load the city list.';

  @override
  String get cityPickerTryAgain => 'Try again';

  @override
  String get cityPickerUnavailable =>
      'The city list isn\'t available right now.';

  @override
  String get cityPickerNoMatch =>
      'No city found. Try the English or Arabic name.';

  @override
  String get cityPickerUseLocation => 'Use my location';

  @override
  String get cityPickerComingSoon => 'Coming soon';

  @override
  String cityName(String english, String arabic) {
    return '$english · $arabic';
  }

  @override
  String get countryPS => 'Palestine';

  @override
  String get countryJO => 'Jordan';

  @override
  String get countryEG => 'Egypt';

  @override
  String get countryTR => 'Türkiye';

  @override
  String get countryIQ => 'Iraq';

  @override
  String get countrySA => 'Saudi Arabia';

  @override
  String get countrySY => 'Syria';

  @override
  String get countryAE => 'United Arab Emirates';

  @override
  String get countryOM => 'Oman';

  @override
  String get countryQA => 'Qatar';

  @override
  String get countryYE => 'Yemen';

  @override
  String get countryLB => 'Lebanon';

  @override
  String get countryKW => 'Kuwait';

  @override
  String get countryBH => 'Bahrain';

  @override
  String get countryMA => 'Morocco';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String aboutVersionFlavor(String version, String build, String flavor) {
    return 'Version $version ($build) · $flavor';
  }

  @override
  String aboutFoodDataVersion(int version) {
    return 'Food data version $version';
  }

  @override
  String get aboutCreditsTitle => 'Data credits';

  @override
  String get aboutCreditsUnavailable =>
      'Data credits aren\'t available right now.';

  @override
  String get aboutInfoUnavailable => 'Version isn\'t available right now.';

  @override
  String aboutCredit(String name, String credit) {
    return '$name: $credit';
  }

  @override
  String get aboutLicenses => 'Open-source licences';

  @override
  String get aboutNotMedical =>
      'Fitness Buddy gives estimates for tracking, not medical advice.';

  @override
  String get exportWhat =>
      'Your diary, foods, saved meals and settings as CSV spreadsheet files and one JSON file.';

  @override
  String get exportLiveOnly => 'Deleted items and Buddy chats are left out.';

  @override
  String get exportPrivacy =>
      'Fitness Buddy uploads nothing. Files are not encrypted; whichever app you share them with can read them. Nothing that identifies this phone is included.';

  @override
  String get exportAction => 'Export';

  @override
  String get exportWorking => 'Preparing your files…';

  @override
  String exportDone(int entries, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      entries,
      locale: localeName,
      other: '$entries entries',
      one: '1 entry',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    return 'Handed to the share sheet: $_temp0 in $_temp1.';
  }

  @override
  String get exportDismissed => 'Sharing was cancelled. Nothing was sent.';

  @override
  String get exportFailed => 'Couldn\'t create the export. Try again.';

  @override
  String get exportTryAgain => 'Try again';

  @override
  String get exportExportAgain => 'Export again';

  @override
  String get exportClose => 'Close';

  @override
  String get exportDoneButton => 'Done';

  @override
  String get aboutTestReportTitle => 'Send a test error report?';

  @override
  String get aboutTestReportBody =>
      'This queues two made-up test errors for the crash-report service, with app and device information. Your diary and other personal content are not included.';

  @override
  String get aboutTestReportSend => 'Send';

  @override
  String get aboutTestReportCancel => 'Cancel';

  @override
  String get aboutTestReportSent => 'Test report queued';

  @override
  String get aboutTestReportOffDev =>
      'Crash reports are off in dev builds, so nothing was sent.';

  @override
  String get aboutTestReportOffNoDsn =>
      'Crash reports aren\'t set up in this build, so nothing was sent.';

  @override
  String get settingsMealTimes => 'Meal times';

  @override
  String get mealTimesTitle => 'Meal times';

  @override
  String get mealTimesFootnote =>
      'Times decide which meal new food goes into. Food you\'ve already logged stays where it is.';

  @override
  String get mealTimesAdd => 'Add meal';

  @override
  String mealTimesAddLimit(int max) {
    return 'You can have up to $max meals.';
  }

  @override
  String get mealTimesAnyTime => 'Any time';

  @override
  String mealTimesWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String mealTimesWindowOvernight(String start, String end) {
    return '$start – $end, overnight';
  }

  @override
  String mealTimesRowSubtitle(String window, String items) {
    return '$window · $items';
  }

  @override
  String get mealTimesLoadFailed => 'Couldn\'t load your meals.';

  @override
  String get mealTimesTryAgain => 'Try again';

  @override
  String get mealTimesReorderFailed =>
      'Couldn\'t change the order. It was left as it was.';

  @override
  String get mealTimesReordered => 'Meals reordered';

  @override
  String slotItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'no items',
    );
    return '$_temp0';
  }

  @override
  String slotDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get slotEditTitle => 'Edit meal';

  @override
  String get slotAddTitle => 'Add meal';

  @override
  String get slotNameLabel => 'Name';

  @override
  String slotNameHintDefault(String name) {
    return 'Leave empty to use $name';
  }

  @override
  String get slotNameTaken => 'Another meal already has this name.';

  @override
  String get slotNameInvalid => 'Use 1 to 30 characters for the name.';

  @override
  String get slotSetTimes => 'Set times';

  @override
  String get slotSetTimesHint =>
      'New food logged in this window goes into this meal.';

  @override
  String get slotFrom => 'From';

  @override
  String get slotTo => 'To';

  @override
  String get slotTimesSame => 'From and To can\'t be the same time.';

  @override
  String get slotSave => 'Save';

  @override
  String get slotAddButton => 'Add';

  @override
  String get slotRemoveAction => 'Remove meal';

  @override
  String get slotKeepOne => 'Keep at least one meal.';

  @override
  String get slotStaleRemoved => 'This meal was removed.';

  @override
  String get slotStaleChanged => 'This meal changed.';

  @override
  String get slotSaveChanged => 'That meal changed. Nothing was saved.';

  @override
  String slotAddedMessage(String name) {
    return 'Added $name';
  }

  @override
  String slotUpdatedMessage(String name) {
    return '$name updated';
  }

  @override
  String slotRemoveTitle(String name) {
    return 'Remove $name';
  }

  @override
  String slotRemoveEmpty(String name) {
    return '$name has nothing logged. It will leave your day.';
  }

  @override
  String slotRemoveHasItems(String name, String items, String days) {
    return '$name has $items on $days. Move them to:';
  }

  @override
  String get slotRemoveButton => 'Remove';

  @override
  String get slotRemoveMoveButton => 'Remove and move';

  @override
  String get slotRemoveChanged => 'That meal changed. Nothing was removed.';

  @override
  String slotRemovedMessage(String name) {
    return 'Removed $name';
  }

  @override
  String slotRemovedMovedMessage(String name, String items, String target) {
    return 'Removed $name, moved $items to $target';
  }

  @override
  String get diarySlotRemoved => 'That meal was removed. Choose another.';

  @override
  String get foodSheetSlotChoose => 'Choose a meal';
}
