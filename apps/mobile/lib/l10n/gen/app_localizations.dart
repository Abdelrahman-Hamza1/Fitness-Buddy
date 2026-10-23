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
  /// **'Nothing yet'**
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

  /// Title of the add-food search screen (FD-020).
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get foodSearchTitle;

  /// Hint of the search box on the add-food screen.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get foodSearchHint;

  /// Section title above the foods logged before, shown while the search box is empty (FD-023).
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get foodSearchRecent;

  /// Add-food screen: title shown while the search box is empty and nothing has been logged before.
  ///
  /// In en, this message translates to:
  /// **'Find a food'**
  String get foodSearchEmptyTitle;

  /// Add-food screen: hint under the title while the search box is empty and nothing has been logged before. Arabizi is Arabic written in Latin letters.
  ///
  /// In en, this message translates to:
  /// **'Search in English, Arabic or Arabizi'**
  String get foodSearchEmptyMessage;

  /// Add-food screen: title when the typed text finds no food. The text is quoted.
  ///
  /// In en, this message translates to:
  /// **'No match for \"{query}\"'**
  String foodSearchNoMatchTitle(String query);

  /// Add-food screen: help under the no-match title.
  ///
  /// In en, this message translates to:
  /// **'Try another name or spelling.'**
  String get foodSearchNoMatchMessage;

  /// Add-food screen: banner shown while the offline food database is not available; only foods logged before can be found.
  ///
  /// In en, this message translates to:
  /// **'The food database isn\'t ready yet. Showing foods you\'ve logged before.'**
  String get foodSearchPackNotReady;

  /// Add-food screen: banner when a search failed unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search just now. Try again.'**
  String get foodSearchFailed;

  /// Add-food result row: calories of the default serving, at the end of the row.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String foodResultKcal(int kcal);

  /// Unit label: gram. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitG;

  /// Unit label: kilogram. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// Unit label: ounce. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'oz'**
  String get unitOz;

  /// Unit label: pound. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitLb;

  /// Unit label: millilitre. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// Unit label: litre. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'l'**
  String get unitL;

  /// Unit label: US fluid ounce. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'fl oz'**
  String get unitFlOz;

  /// Unit label: tablespoon. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'tbsp'**
  String get unitTbsp;

  /// Unit label: teaspoon. Same for every count.
  ///
  /// In en, this message translates to:
  /// **'tsp'**
  String get unitTsp;

  /// Unit label (cup), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{cup} other{cups}}'**
  String unitCup(num count);

  /// Unit label (piece), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{piece} other{pieces}}'**
  String unitPiece(num count);

  /// Unit label (loaf of flat bread), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{loaf} other{loaves}}'**
  String unitLoaf(num count);

  /// Unit label (plate), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{plate} other{plates}}'**
  String unitPlate(num count);

  /// Unit label (small plate), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{small plate} other{small plates}}'**
  String unitSmallPlate(num count);

  /// Unit label (large plate), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{large plate} other{large plates}}'**
  String unitLargePlate(num count);

  /// Unit label (glass), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{glass} other{glasses}}'**
  String unitGlass(num count);

  /// Unit label (sandwich), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{sandwich} other{sandwiches}}'**
  String unitSandwich(num count);

  /// Unit label (disc), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{disc} other{discs}}'**
  String unitDisc(num count);

  /// Unit label (serving), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{serving} other{servings}}'**
  String unitServing(num count);

  /// Unit label (can or tin), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{can} other{cans}}'**
  String unitCan(num count);

  /// Unit label (bowl), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{bowl} other{bowls}}'**
  String unitBowl(num count);

  /// Unit label (slice), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{slice} other{slices}}'**
  String unitSlice(num count);

  /// Unit label (wedge), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{wedge} other{wedges}}'**
  String unitWedge(num count);

  /// Unit label (container or tub), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{container} other{containers}}'**
  String unitContainer(num count);

  /// Unit label (ladle), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ladle} other{ladles}}'**
  String unitLadle(num count);

  /// Unit label (portion; shown for a food-specific unit the app has no word for), singular for 1 and plural otherwise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{portion} other{portions}}'**
  String unitPortion(num count);

  /// Unit label of a food-specific unit the app has no word for, with how much it holds, e.g. "portion (60 g)".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{portion} other{portions}} ({size} {unit})'**
  String unitPortionSized(num count, double size, String unit);

  /// The state a food's values refer to, in lower case (raw, cooked, dry, drained, fried, as sold).
  ///
  /// In en, this message translates to:
  /// **'{state, select, raw{raw} cooked{cooked} dry{dry} drained{drained} fried{fried} as_sold{as sold} other{}}'**
  String foodStateWord(String state);

  /// Add-food result row: the serving the calories are for, e.g. "1 loaf" or "100 g".
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String foodResultServing(double amount, String unit);

  /// Add-food result row: second line with the Arabic name and the serving the calories are for, e.g. "خبز عربي · 1 loaf".
  ///
  /// In en, this message translates to:
  /// **'{name} · {serving}'**
  String foodResultSubtitle(String name, String serving);

  /// Food sheet title: the English name and the Arabic name of a food that has both.
  ///
  /// In en, this message translates to:
  /// **'{en} · {ar}'**
  String foodSheetNames(String en, String ar);

  /// Food sheet: the state of the food, e.g. "State: cooked".
  ///
  /// In en, this message translates to:
  /// **'State: {state}'**
  String foodSheetState(String state);

  /// Food sheet: gentle note on a food whose calories do not match its protein, carbs and fat (FD-012).
  ///
  /// In en, this message translates to:
  /// **'This food\'s calories don\'t quite match its protein, carbs and fat.'**
  String get foodSheetSanityWarn;

  /// Food sheet: what a screen reader says for the amount box.
  ///
  /// In en, this message translates to:
  /// **'Amount, {amount} {unit}'**
  String foodSheetAmountLabel(String amount, String unit);

  /// Food sheet: calories of the chosen amount.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String foodSheetKcal(int kcal);

  /// Food sheet: calories shown while there is no valid amount.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get foodSheetNoKcal;

  /// Food sheet: the four macros of the chosen amount, in grams.
  ///
  /// In en, this message translates to:
  /// **'Protein {protein} g · Carbs {carbs} g · Fat {fat} g · Fiber {fiber} g'**
  String foodSheetMacros(
    double protein,
    double carbs,
    double fat,
    double fiber,
  );

  /// Food sheet: chip that switches to the same food in another state (raw, cooked, dry); {name} is that food.
  ///
  /// In en, this message translates to:
  /// **'Log as {name}'**
  String foodSheetLogAs(String name);

  /// Food sheet: how much a weighed amount of a food becomes in another state, e.g. "100 g dry ≈ 280 g cooked". Display only.
  ///
  /// In en, this message translates to:
  /// **'{from} g {fromState} ≈ {to} g {toState}'**
  String foodSheetYieldNote(int from, String fromState, int to, String toState);

  /// Food sheet: chip with the meal the food is added to; tap to change.
  ///
  /// In en, this message translates to:
  /// **'Meal: {slot}'**
  String foodSheetSlot(String slot);

  /// Food sheet: the meal chip when no meal is chosen.
  ///
  /// In en, this message translates to:
  /// **'No meal'**
  String get foodSheetSlotNone;

  /// Food sheet: title of the list of meals.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get foodSheetSlotTitle;

  /// Food sheet: the button that adds the food to the diary.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get foodSheetAdd;

  /// Food sheet: shown when adding the food did not work.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add this food. Try again.'**
  String get foodSheetAddFailed;

  /// Food sheet: shown when the food could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this food. Try again.'**
  String get foodSheetLoadFailed;

  /// Food sheet: heading of the values per 100 grams.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g'**
  String get foodSheetPer100g;

  /// Food sheet: heading of the values per 100 millilitres.
  ///
  /// In en, this message translates to:
  /// **'Per 100 ml'**
  String get foodSheetPer100ml;

  /// Food sheet: button that shows the optional nutrients (sugar, sodium, ...).
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get foodSheetMore;

  /// Food sheet: button that hides the optional nutrients.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get foodSheetLess;

  /// Nutrient name: energy.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get foodNutrientEnergy;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get foodNutrientProtein;

  /// Nutrient name: total carbohydrate.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get foodNutrientCarbs;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get foodNutrientFat;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get foodNutrientFiber;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get foodNutrientSugar;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Saturated fat'**
  String get foodNutrientSaturatedFat;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Trans fat'**
  String get foodNutrientTransFat;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get foodNutrientSodium;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Cholesterol'**
  String get foodNutrientCholesterol;

  /// Nutrient name.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get foodNutrientAlcohol;

  /// A nutrient amount in grams.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String foodNutrientGrams(double value);

  /// A nutrient amount in milligrams.
  ///
  /// In en, this message translates to:
  /// **'{value} mg'**
  String foodNutrientMilligrams(double value);

  /// Undo snackbar after a food was added to the diary.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to {meal}'**
  String foodLoggedMessage(String name, String meal);

  /// No description provided for @foodSearchNotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to search yet'**
  String get foodSearchNotReadyTitle;

  /// No description provided for @foodSearchNotReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'The food database isn\'t ready yet. Foods you log will show up here.'**
  String get foodSearchNotReadyMessage;

  /// No description provided for @foodTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get foodTryAgain;

  /// No description provided for @foodSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get foodSheetClose;

  /// Day header: the label of the current day (HM-009).
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get diaryDateToday;

  /// Day header: the label of the day before today (HM-009).
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get diaryDateYesterday;

  /// Today: caption under the big number while there is no target yet (HM-001).
  ///
  /// In en, this message translates to:
  /// **'kcal eaten'**
  String get diaryKcalEaten;

  /// Today: the big number, the day's calories eaten.
  ///
  /// In en, this message translates to:
  /// **'{kcal}'**
  String diaryBigKcal(int kcal);

  /// Today: one macro of the day's total, e.g. Protein 110 g.
  ///
  /// In en, this message translates to:
  /// **'{label} {value} g'**
  String diaryMacroItem(String label, double value);

  /// Diary: calories of a slot, a dish or an item.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String diaryKcal(int kcal);

  /// Today: hint card above the meals while the day has no entries (UX-050).
  ///
  /// In en, this message translates to:
  /// **'A fresh day. Tap + on a meal to add your first food.'**
  String get diaryEmptyTodayHint;

  /// A past day without entries (UX-050).
  ///
  /// In en, this message translates to:
  /// **'Nothing logged on this day. Forgot something? Tap + on a meal.'**
  String get diaryEmptyPastHint;

  /// Button of the empty-day hint: opens the food search.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get diaryEmptySearch;

  /// Diary: heading for entries whose meal no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get diarySlotOther;

  /// Tooltip and screen-reader label of the + button of a meal.
  ///
  /// In en, this message translates to:
  /// **'Add food to {meal}'**
  String diarySlotAddTooltip(String meal);

  /// Full nutrient names spoken for an expanded meal.
  ///
  /// In en, this message translates to:
  /// **'Protein {protein} g, carbs {carbs} g, fat {fat} g, fiber {fiber} g'**
  String diarySlotMacrosSemantics(
    double protein,
    double carbs,
    double fat,
    double fiber,
  );

  /// Diary: compact macro line of an opened meal (grams).
  ///
  /// In en, this message translates to:
  /// **'P {protein} · C {carbs} · F {fat} · Fiber {fiber}'**
  String diarySlotMacros(
    double protein,
    double carbs,
    double fat,
    double fiber,
  );

  /// Diary: how many items a dish holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String diaryGroupItems(int count);

  /// Swipe action and screen-reader action: removes a diary item (undoable).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get diaryDelete;

  /// Swipe action and screen-reader action: opens the list of meals.
  ///
  /// In en, this message translates to:
  /// **'Move to another meal'**
  String get diaryMoveToAnotherMeal;

  /// Title of the sheet that lists the meals to move an item to.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get diaryMoveTitle;

  /// Screen-reader text of the meal the item is already in.
  ///
  /// In en, this message translates to:
  /// **'Current meal'**
  String get diaryMoveCurrent;

  /// Undo snackbar after an item was deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String diaryEntryDeleted(String name);

  /// Undo snackbar after an item was moved to another meal.
  ///
  /// In en, this message translates to:
  /// **'Moved {name} to {meal}'**
  String diaryEntryMoved(String name, String meal);

  /// Snackbar when the item was edited elsewhere since it was shown (UX-052).
  ///
  /// In en, this message translates to:
  /// **'That item was changed, so nothing was saved.'**
  String get diaryItemChanged;

  /// Snackbar when a diary change could not be made.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Try again.'**
  String get diaryActionFailed;

  /// Banner when a day's diary cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this day.'**
  String get diaryLoadFailed;

  /// Item details: row label of the logged amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get diaryDetailsAmount;

  /// Item details: the logged amount and its size in grams or ml.
  ///
  /// In en, this message translates to:
  /// **'{input} ({amount})'**
  String diaryDetailsAmountResolved(String input, String amount);

  /// Item details: row label of the time the item was logged for.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get diaryDetailsTime;

  /// Item details: row label of where the numbers come from.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get diaryDetailsSource;

  /// Item details: row label of the calorie range of an estimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate range'**
  String get diaryDetailsEstimateRange;

  /// Item details: the calorie range of an estimate.
  ///
  /// In en, this message translates to:
  /// **'{low}–{high} kcal'**
  String diaryDetailsEstimateRangeValue(int low, int high);

  /// Item details: heading of the assumptions behind an estimate.
  ///
  /// In en, this message translates to:
  /// **'Assumptions'**
  String get diaryDetailsAssumptions;

  /// Item details: heading of the nutrient list.
  ///
  /// In en, this message translates to:
  /// **'Nutrition for this amount'**
  String get diaryDetailsNutrition;

  /// Item details: the numbers were entered by the user.
  ///
  /// In en, this message translates to:
  /// **'Your own values'**
  String get diarySourceYours;

  /// Item details: the numbers come from the food database.
  ///
  /// In en, this message translates to:
  /// **'Food database'**
  String get diarySourceDatabase;

  /// Item details: the numbers are typical for a dish.
  ///
  /// In en, this message translates to:
  /// **'Reference dish'**
  String get diarySourceReference;

  /// Item details: the numbers are a rough guess.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get diarySourceEstimate;

  /// Item details: the numbers were changed by the user.
  ///
  /// In en, this message translates to:
  /// **'{source}, edited by you'**
  String diarySourceEdited(String source);

  /// Snackbar when Undo is refused because the data changed afterwards.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t undo, it was changed since.'**
  String get diaryUndoConflict;

  /// Snackbar when the undo window has passed.
  ///
  /// In en, this message translates to:
  /// **'Too late to undo.'**
  String get diaryUndoExpired;

  /// Hint of the bar at the bottom of Today until Buddy takes it over: it opens the food search (HM-008).
  ///
  /// In en, this message translates to:
  /// **'Search for a food…'**
  String get todayInputHintSearch;

  /// Dev builds only: the camera and barcode buttons do nothing yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get devComingSoon;
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
