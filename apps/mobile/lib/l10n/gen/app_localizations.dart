import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The app's name, shown by the OS task switcher.
  ///
  /// In en, this message translates to:
  /// **'Fitness Buddy'**
  String get appTitle;

  /// Bottom navigation tab: the home screen with today's diary (UX-010).
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// Bottom navigation tab: weight trend, charts and weekly summaries (UX-010).
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// Bottom navigation tab: workout plan, sessions and history (UX-010).
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get tabWorkouts;

  /// Bottom navigation tab: profile, goals, targets, memory and settings (UX-010).
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// Placeholder body of the Today tab until the diary is built.
  ///
  /// In en, this message translates to:
  /// **'Tell Buddy what you ate and it shows up here.'**
  String get todayPlaceholder;

  /// Placeholder body of the Progress tab until charts are built.
  ///
  /// In en, this message translates to:
  /// **'Charts appear after a few days of logging.'**
  String get progressPlaceholder;

  /// Placeholder body of the Workouts tab until workouts are built.
  ///
  /// In en, this message translates to:
  /// **'Your workouts will show up here.'**
  String get workoutsPlaceholder;

  /// Placeholder body of the Me tab until profile and settings are built.
  ///
  /// In en, this message translates to:
  /// **'Your profile and settings will live here.'**
  String get mePlaceholder;

  /// Title of the screen shown when this app version is too old to talk to the server.
  ///
  /// In en, this message translates to:
  /// **'Update needed'**
  String get updateRequiredTitle;

  /// Body of the update-required screen. Plain language, reassures that local data is kept.
  ///
  /// In en, this message translates to:
  /// **'This version can\'t connect any more. Install the latest one to continue. Your data stays on your phone.'**
  String get updateRequiredBody;

  /// Button on the update-required screen: asks the server again whether this version is allowed.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get updateRequiredCheckAgain;

  /// Shown under the Check again button while the app asks the server whether this version is allowed.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get updateRequiredChecking;

  /// Shown after Check again when the server still says this version is too old.
  ///
  /// In en, this message translates to:
  /// **'Still on an older version. Install the new build, then check again.'**
  String get updateRequiredStillOld;

  /// Shown after Check again when the server could not be reached (offline, timeout or error).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check. Are you online?'**
  String get updateRequiredCheckFailed;

  /// Title of the Today tab's empty state until the diary is built.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get todayEmptyTitle;

  /// Title of the Progress tab's empty state until charts are built.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get progressEmptyTitle;

  /// Title of the Workouts tab's empty state until workouts are built.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get workoutsEmptyTitle;

  /// Title of the Me tab's empty state until profile and settings are built.
  ///
  /// In en, this message translates to:
  /// **'Nothing to set up yet'**
  String get meEmptyTitle;

  /// Row on the Me tab that opens the design preview. Only in the dev flavor.
  ///
  /// In en, this message translates to:
  /// **'Design preview'**
  String get meDesignPreview;

  /// Title of the design preview screen (dev flavor only).
  ///
  /// In en, this message translates to:
  /// **'Design preview'**
  String get previewTitle;

  /// Design preview tab: mockups of the main screens.
  ///
  /// In en, this message translates to:
  /// **'Mockups'**
  String get previewTabMockups;

  /// Design preview tab: the gallery of design-system components.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get previewTabComponents;

  /// Design preview tab: colours, type and contrast ratios.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get previewTabTokens;

  /// Design preview: label (screen readers) of the A/B palette switch.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get previewVariantLabel;

  /// Design preview: palette variant A, the first option of the A/B switch.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get previewVariantA;

  /// Design preview: palette variant B, the second option of the A/B switch.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get previewVariantB;

  /// Design preview: label (screen readers) of the light/dark/system switch.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get previewModeLabel;

  /// Design preview: light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get previewModeLight;

  /// Design preview: dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get previewModeDark;

  /// Design preview: follow-the-system theme option.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get previewModeSystem;

  /// Design preview: name of the Today screen mockup.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get previewMockupToday;

  /// Design preview: name of the food proposal mockup.
  ///
  /// In en, this message translates to:
  /// **'Food proposal'**
  String get previewMockupFoodProposal;

  /// Design preview: name of the edit proposal mockup.
  ///
  /// In en, this message translates to:
  /// **'Edit proposal'**
  String get previewMockupEditProposal;

  /// Design preview: name of the weight card mockup.
  ///
  /// In en, this message translates to:
  /// **'Weight card'**
  String get previewMockupWeightCard;

  /// Design preview: name of the Progress overview mockup.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get previewMockupProgress;

  /// Design preview gallery: button that opens a bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Open sheet'**
  String get previewOpenSheet;

  /// Design preview gallery: button that opens the source legend sheet.
  ///
  /// In en, this message translates to:
  /// **'Open source legend'**
  String get previewOpenSourceLegend;

  /// Design preview gallery: button that opens the estimate range sheet.
  ///
  /// In en, this message translates to:
  /// **'Open estimate range'**
  String get previewOpenEstimateRange;

  /// Design preview gallery: button that shows a snackbar with Undo.
  ///
  /// In en, this message translates to:
  /// **'Show undo snackbar'**
  String get previewShowUndoSnackBar;

  /// Design preview gallery: button that shows a plain snackbar.
  ///
  /// In en, this message translates to:
  /// **'Show snackbar'**
  String get previewShowSnackBar;

  /// Design preview, Tokens tab: heading of the colour swatches.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get previewTokensColors;

  /// Design preview, Tokens tab: heading of the type scale.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get previewTokensType;

  /// Design preview, Tokens tab: heading of the contrast ratios.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get previewTokensContrast;

  /// Design preview, Tokens tab: sample text shown in each type style.
  ///
  /// In en, this message translates to:
  /// **'Eat well, feel good'**
  String get previewTypeSample;

  /// Design preview, Tokens tab: screen-reader label of a contrast pair that reaches its minimum.
  ///
  /// In en, this message translates to:
  /// **'Passes'**
  String get previewContrastPasses;

  /// Design preview, Tokens tab: screen-reader label of a contrast pair that misses its minimum.
  ///
  /// In en, this message translates to:
  /// **'Below the minimum'**
  String get previewContrastFails;

  /// Today: caption under the big remaining-calories number (HM-001).
  ///
  /// In en, this message translates to:
  /// **'kcal left today'**
  String get todayKcalLeft;

  /// Today: caption of the big number when the day is over the budget. Neutral wording (SF-021).
  ///
  /// In en, this message translates to:
  /// **'kcal over today'**
  String get todayKcalOver;

  /// Today: eaten calories out of the day budget, next to the progress bar.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {budget} kcal'**
  String todayEatenOfBudget(String eaten, String budget);

  /// Today: weekly line when under the weekly budget (HM-002).
  ///
  /// In en, this message translates to:
  /// **'This week: {amount} kcal under'**
  String todayWeekUnder(String amount);

  /// Today: weekly line when over the weekly budget (HM-002). Neutral wording.
  ///
  /// In en, this message translates to:
  /// **'This week: {amount} kcal over'**
  String todayWeekOver(String amount);

  /// Today: protein macro bar label (HM-003).
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get todayMacroProtein;

  /// Today: carbs macro bar label (HM-003).
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get todayMacroCarbs;

  /// Today: fat macro bar label (HM-003).
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get todayMacroFat;

  /// Today: fiber macro bar label (HM-003).
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get todayMacroFiber;

  /// Today: title of the strip shown while proposals wait for confirmation (HM-004).
  ///
  /// In en, this message translates to:
  /// **'{count} to confirm'**
  String todayToConfirm(String count);

  /// Today: calories the pending proposals would add, in the to-confirm strip.
  ///
  /// In en, this message translates to:
  /// **'+{kcal} kcal'**
  String todayToConfirmKcal(String kcal);

  /// Today: title of the weight row (HM-005).
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get todayWeight;

  /// Today: weight row summary, trend weight and weekly rate.
  ///
  /// In en, this message translates to:
  /// **'{trend} trend · {rate}/wk'**
  String todayWeightTrendRate(String trend, String rate);

  /// Today: workout hint row, shown when a weekly plan exists (HM-006).
  ///
  /// In en, this message translates to:
  /// **'{name} today'**
  String todayWorkoutHint(String name);

  /// Diary meal slot: breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get todaySlotBreakfast;

  /// Diary meal slot: lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get todaySlotLunch;

  /// Diary meal slot: snacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get todaySlotSnacks;

  /// Diary meal slot: dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get todaySlotDinner;

  /// Today: subtitle of a diary slot without entries.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get todaySlotEmpty;

  /// Today: calories column of a diary slot without entries.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get todaySlotNoKcal;

  /// Today: button in the to-confirm strip that confirms every waiting proposal (HM-004).
  ///
  /// In en, this message translates to:
  /// **'Confirm all'**
  String get todayConfirmAll;

  /// Today: screen-reader text for the dash shown as calories of an empty diary slot.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged'**
  String get todaySlotNoKcalSemantics;

  /// Today: quick-add chip that opens the add-food flow (HM-008).
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get todayQuickAddMore;

  /// Hint of the input bar at the bottom of Today (HM-008).
  ///
  /// In en, this message translates to:
  /// **'Tell Buddy what you ate…'**
  String get todayInputHint;

  /// Proposal card heading: meal slot and time (AI-031).
  ///
  /// In en, this message translates to:
  /// **'{slot} · {time}'**
  String proposalSlotAtTime(String slot, String time);

  /// Proposal card: calories of one item.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String proposalItemKcal(String kcal);

  /// Proposal card: total calories of the card.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String proposalTotalKcal(String kcal);

  /// Proposal card: total protein, carbs, fat and fiber in grams, short form.
  ///
  /// In en, this message translates to:
  /// **'Protein {protein} g · Carbs {carbs} g · Fat {fat} g · Fiber {fiber} g'**
  String proposalMacrosShort(
    String protein,
    String carbs,
    String fat,
    String fiber,
  );

  /// Proposal card: remaining calories today once the card is logged (AI-031).
  ///
  /// In en, this message translates to:
  /// **'Today after this: {left} left'**
  String proposalTodayAfter(String left);

  /// Proposal card: removes the proposal, nothing is logged (AI-037).
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get proposalDiscard;

  /// Proposal card: confirms the proposal in one tap (AI-035).
  ///
  /// In en, this message translates to:
  /// **'Log it'**
  String get proposalLogIt;

  /// Edit proposal card: confirms the change to the diary entry.
  ///
  /// In en, this message translates to:
  /// **'Apply change'**
  String get proposalApplyChange;

  /// Title of the sheet with alternatives for an assumption chip (AI-033).
  ///
  /// In en, this message translates to:
  /// **'Change the assumption'**
  String get proposalAssumptionTitle;

  /// Edit proposal card: small heading above the entry being changed (AI-050).
  ///
  /// In en, this message translates to:
  /// **'Change to your diary'**
  String get proposalEditLabel;

  /// Edit proposal card: row label for the amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get proposalFieldAmount;

  /// Edit proposal card: row label for the calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get proposalFieldCalories;

  /// Edit proposal card: row label for the protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proposalFieldProtein;

  /// Edit proposal card: row label for the calories left today, before and after the change.
  ///
  /// In en, this message translates to:
  /// **'Left today'**
  String get proposalFieldLeftToday;

  /// Edit proposal card: screen-reader text of one before and after row.
  ///
  /// In en, this message translates to:
  /// **'{label}: {before}, now {after}'**
  String proposalChangeSemantics(String label, String before, String after);

  /// Weight card: title (HM-005).
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTitle;

  /// Weight card: caption under the big trend number.
  ///
  /// In en, this message translates to:
  /// **'kg trend'**
  String get weightTrendCaption;

  /// Weight card: weekly rate of change of the trend.
  ///
  /// In en, this message translates to:
  /// **'{rate} kg per week'**
  String weightRatePerWeek(String rate);

  /// Weight card: the most recent weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Last weigh-in: {value} kg · {date}'**
  String weightLastWeighIn(String value, String date);

  /// Weight card: distance to the goal weight, neutral wording.
  ///
  /// In en, this message translates to:
  /// **'{amount} kg to your goal'**
  String weightToGoal(String amount);

  /// Weight card: time range of the chart.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get weightRange;

  /// Weight card: opens the number pad to log a weigh-in (WB-001).
  ///
  /// In en, this message translates to:
  /// **'Log weigh-in'**
  String get weightLog;

  /// Progress: heading of the weekly summary (IN-001).
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get progressWeekTitle;

  /// Progress: heading of the weekly review written by Buddy (AI-130).
  ///
  /// In en, this message translates to:
  /// **'Buddy\'s review'**
  String get progressReviewTitle;

  /// Progress: weekly summary row label.
  ///
  /// In en, this message translates to:
  /// **'Average calories'**
  String get progressAvgCalories;

  /// Progress: average daily calories against the budget.
  ///
  /// In en, this message translates to:
  /// **'{avg} of {budget} kcal'**
  String progressAvgCaloriesValue(String avg, String budget);

  /// Progress: weekly summary row label.
  ///
  /// In en, this message translates to:
  /// **'Days within target'**
  String get progressDaysWithin;

  /// Progress: a count out of a total, e.g. days or workouts.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String progressOutOf(String done, String total);

  /// Progress: weekly summary row label.
  ///
  /// In en, this message translates to:
  /// **'Protein target days'**
  String get progressProteinDays;

  /// Progress: weekly summary row label.
  ///
  /// In en, this message translates to:
  /// **'Fiber average'**
  String get progressFiberAvg;

  /// Progress: an amount in grams.
  ///
  /// In en, this message translates to:
  /// **'{amount} g'**
  String progressGrams(String amount);

  /// Progress: weekly summary row label.
  ///
  /// In en, this message translates to:
  /// **'Trend weight change'**
  String get progressWeightChange;

  /// Progress: an amount in kilograms.
  ///
  /// In en, this message translates to:
  /// **'{amount} kg'**
  String progressKg(String amount);

  /// Progress: weekly summary row label.
  ///
  /// In en, this message translates to:
  /// **'Workouts done'**
  String get progressWorkouts;

  /// Progress: heading of the calories chart (IN-002).
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get progressChartCalories;

  /// Progress: heading of the macros chart (IN-003).
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get progressChartMacros;

  /// Progress: heading of the weight chart (IN-004).
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get progressChartWeight;

  /// Progress: heading of the goal progress card (IN-007).
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get progressGoalTitle;

  /// Progress: the current goal phase.
  ///
  /// In en, this message translates to:
  /// **'Phase: {phase}'**
  String progressGoalPhase(String phase);

  /// Progress: current and target weight.
  ///
  /// In en, this message translates to:
  /// **'{now} now · {target} target'**
  String progressGoalNowTarget(String now, String target);

  /// Progress: this month against the monthly target.
  ///
  /// In en, this message translates to:
  /// **'This month: {done} of {target} kg'**
  String progressGoalMonth(String done, String target);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
