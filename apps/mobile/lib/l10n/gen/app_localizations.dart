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

  /// Food sheet: how much a weighed amount of a food becomes in another state, e.g. "100 g dry ≈ 280 g cooked" (or "3.5 oz dry ≈ 9.9 oz cooked" with imperial units). The amounts arrive already formatted with their unit. Display only.
  ///
  /// In en, this message translates to:
  /// **'{from} {fromState} ≈ {to} {toState}'**
  String foodSheetYieldNote(
    String from,
    String fromState,
    String to,
    String toState,
  );

  /// Food sheet: the meal chip when no meal is chosen.
  ///
  /// In en, this message translates to:
  /// **'No meal'**
  String get foodSheetSlotNone;

  /// Food sheet: title of the list of meals; also the name on the chip that shows the chosen meal (the chip reads "Meal", then the meal).
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

  /// The current day inside a sentence, lower case (for example 'Logged Oats, 100 g for today').
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get diaryDateTodayInline;

  /// The day before today inside a sentence, lower case (for example 'Logged Oats, 100 g for yesterday').
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get diaryDateYesterdayInline;

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

  /// A logged amount followed by its stored size in the food's own unit, where that adds information, e.g. "1 loaf (60 g)" or "250 ml (258 g)". Both parts arrive formatted with their unit.
  ///
  /// In en, this message translates to:
  /// **'{amount} ({canonical})'**
  String foodAmountWithCanonical(String amount, String canonical);

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
  /// **'Your edit of {source} values'**
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

  /// Item details and copy sheet: name of the chip that shows the meal (the chip reads "Meal", then the meal).
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get diaryChipMeal;

  /// Item details: the chip that opens the food search to replace the food of a logged item (DY-021).
  ///
  /// In en, this message translates to:
  /// **'Change food'**
  String get diaryChangeFood;

  /// Item details: screen-reader hint of a nutrient row that opens the value editor (AI-072).
  ///
  /// In en, this message translates to:
  /// **'Tap to change this value'**
  String get diaryNutrientEditHint;

  /// Edit sheets: the button that saves the change.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get diarySave;

  /// Edit sheets: the action that loads the item as it is now and keeps what was typed (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get diaryReload;

  /// Edit sheets: the item was deleted while the sheet was open; Save is disabled (D12).
  ///
  /// In en, this message translates to:
  /// **'This item was removed.'**
  String get diaryEntryRemoved;

  /// Edit sheets: the item was edited while the sheet was open; Reload shows the current values.
  ///
  /// In en, this message translates to:
  /// **'This item changed.'**
  String get diaryEntryChangedStale;

  /// Snackbar when the item was deleted elsewhere before the change was saved.
  ///
  /// In en, this message translates to:
  /// **'That item was removed, so nothing was saved.'**
  String get diaryActionRemoved;

  /// Undo snackbar after the amount of an item was changed.
  ///
  /// In en, this message translates to:
  /// **'Changed {name} to {amount}'**
  String diaryAmountChanged(String name, String amount);

  /// Undo snackbar after the time of an item was changed.
  ///
  /// In en, this message translates to:
  /// **'Changed the time of {name} to {time}'**
  String diaryTimeChanged(String name, String time);

  /// Undo snackbar after a nutrient value of an item was edited (AI-072).
  ///
  /// In en, this message translates to:
  /// **'Edited {nutrient} of {name}'**
  String diaryNutrientEdited(String nutrient, String name);

  /// Title of the sheet that edits one nutrient value of an item.
  ///
  /// In en, this message translates to:
  /// **'Edit {nutrient}'**
  String diaryOverrideTitle(String nutrient);

  /// Nutrient value sheet: what the number means and what saving does (AI-072).
  ///
  /// In en, this message translates to:
  /// **'Enter the value for this amount. The item is then marked as edited by you.'**
  String get diaryOverrideNote;

  /// Nutrient value sheet: the typed value is above the largest accepted value.
  ///
  /// In en, this message translates to:
  /// **'Enter {max} {unit} or less.'**
  String diaryOverrideOutOfRange(String max, String unit);

  /// Nutrient value sheet: the value was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that value. Check it and try again.'**
  String get diaryOverrideInvalid;

  /// Nutrient value sheet: screen-reader text of the typed value.
  ///
  /// In en, this message translates to:
  /// **'{nutrient}, {value} {unit}'**
  String diaryOverrideAmountLabel(String nutrient, String value, String unit);

  /// Unit of energy next to a nutrient value.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get diaryUnitKcal;

  /// Unit of milligrams next to a nutrient value.
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get diaryUnitMg;

  /// Tooltip and screen-reader label of the menu button on a meal row.
  ///
  /// In en, this message translates to:
  /// **'More for {meal}'**
  String diaryMealMenuTooltip(String meal);

  /// Meal menu: copies the meal to another day or meal (DY-023).
  ///
  /// In en, this message translates to:
  /// **'Copy to…'**
  String get diaryMealCopyAction;

  /// Meal menu: saves the meal's items as a saved meal (DY-023).
  ///
  /// In en, this message translates to:
  /// **'Save as meal…'**
  String get diaryMealSaveAction;

  /// Title of the sheet that copies a meal.
  ///
  /// In en, this message translates to:
  /// **'Copy {meal}'**
  String diaryCopyTitle(String meal);

  /// Copy sheet: name of the chip that shows the day to copy to.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get diaryCopyDay;

  /// Copy sheet: title of the list of meals to copy to.
  ///
  /// In en, this message translates to:
  /// **'Copy to meal'**
  String get diaryCopySlotTitle;

  /// Copy sheet: the button that copies the meal.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get diaryCopyButton;

  /// Copy sheet: the target is the meal itself (same day and meal), so Copy is disabled until another is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose where to copy this meal.'**
  String get diaryCopyChoose;

  /// Copy and save sheets: the meal was edited while the sheet was open; Reload shows it as it is now.
  ///
  /// In en, this message translates to:
  /// **'This meal changed.'**
  String get diaryMealChanged;

  /// Copy and save sheets: every item of the meal is gone.
  ///
  /// In en, this message translates to:
  /// **'This meal is empty now.'**
  String get diaryMealEmpty;

  /// Copy sheet: the meal changed between opening the sheet and copying.
  ///
  /// In en, this message translates to:
  /// **'That meal changed. Nothing was copied.'**
  String get diaryMealChangedCopy;

  /// Save sheet: the meal changed between opening the sheet and saving.
  ///
  /// In en, this message translates to:
  /// **'That meal changed. Nothing was saved.'**
  String get diaryMealChangedSave;

  /// Undo snackbar after a meal was copied to another day or meal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 item to {day}} other{Copied {count} items to {day}}}'**
  String diaryMealCopied(int count, String day);

  /// Title of the sheet that saves a meal's items as a saved meal.
  ///
  /// In en, this message translates to:
  /// **'Save as meal'**
  String get diarySaveTitle;

  /// Save sheet: label of the name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get diarySaveName;

  /// Save sheet: the name is empty.
  ///
  /// In en, this message translates to:
  /// **'Give the meal a name.'**
  String get diarySaveNameEmpty;

  /// Undo snackbar after a meal was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved \"{name}\"'**
  String diaryMealSaved(String name);

  /// Title of the food search when it replaces the food of a logged item (DY-021).
  ///
  /// In en, this message translates to:
  /// **'Change food'**
  String get foodSearchChangeTitle;

  /// Food sheet in change-food mode: the button that replaces the food.
  ///
  /// In en, this message translates to:
  /// **'Use this food'**
  String get foodSheetUseThis;

  /// Undo snackbar after the food of an item was replaced.
  ///
  /// In en, this message translates to:
  /// **'Changed to {name}'**
  String foodChangedMessage(String name);

  /// Item details: the food database as a noun inside "Your edit of … values".
  ///
  /// In en, this message translates to:
  /// **'food database'**
  String get diarySourceNounDatabase;

  /// Item details: a reference dish as a noun inside "Your edit of … values".
  ///
  /// In en, this message translates to:
  /// **'reference dish'**
  String get diarySourceNounReference;

  /// Item details: an estimate as a noun inside "Your edit of … values".
  ///
  /// In en, this message translates to:
  /// **'estimate'**
  String get diarySourceNounEstimate;

  /// Item details: the user's own values, changed again by the user.
  ///
  /// In en, this message translates to:
  /// **'Your own values, edited'**
  String get diarySourceYoursEdited;

  /// Title of the sheet that edits the calories of an item.
  ///
  /// In en, this message translates to:
  /// **'Edit calories'**
  String get diaryOverrideTitleEnergy;

  /// Amount sheet: why Save is off while the amount is empty or 0.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above 0.'**
  String get diaryAmountNeeded;

  /// Nutrient value sheet: why Save is off while the value is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a value.'**
  String get diaryValueNeeded;

  /// Copy and save sheets: how much the meal holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item · {kcal} kcal} other{{count} items · {kcal} kcal}}'**
  String diaryMealSummary(int count, int kcal);

  /// Change-food search: caption under the title naming the item being replaced.
  ///
  /// In en, this message translates to:
  /// **'Replacing {name}'**
  String foodSearchReplacing(String name);

  /// Me tab: the heading of the section with the food lists (Your foods).
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get meSectionFood;

  /// Me tab: the row that opens the list of foods the user made.
  ///
  /// In en, this message translates to:
  /// **'Your foods'**
  String get meYourFoods;

  /// Title of the list of foods the user made.
  ///
  /// In en, this message translates to:
  /// **'Your foods'**
  String get yourFoodsTitle;

  /// Tooltip and button: starts a new food of your own.
  ///
  /// In en, this message translates to:
  /// **'New food'**
  String get yourFoodsNew;

  /// Your foods: title of the empty state.
  ///
  /// In en, this message translates to:
  /// **'No foods of your own yet'**
  String get yourFoodsEmptyTitle;

  /// Your foods: one line of help in the empty state.
  ///
  /// In en, this message translates to:
  /// **'Add a food you eat often with the numbers from its label. It shows up first in search.'**
  String get yourFoodsEmptyMessage;

  /// Your foods: shown when the list could not be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your foods. Try again.'**
  String get yourFoodsLoadFailed;

  /// Your foods and merge list: the calories of a food, for example 250 kcal per 100 g.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal per {basis}'**
  String yourFoodsKcalPer(int kcal, String basis);

  /// Personal food form: choice for values given per 100 grams. Also names the basis in lists.
  ///
  /// In en, this message translates to:
  /// **'100 g'**
  String get personalFoodBasis100g;

  /// Personal food form: choice for values given per 100 millilitres. Also names the basis in lists.
  ///
  /// In en, this message translates to:
  /// **'100 ml'**
  String get personalFoodBasis100ml;

  /// Personal food form: choice for values given for one serving, as printed on a label.
  ///
  /// In en, this message translates to:
  /// **'One serving'**
  String get personalFoodBasisServing;

  /// Title of the form that creates a food.
  ///
  /// In en, this message translates to:
  /// **'New food'**
  String get personalFoodNewTitle;

  /// Title of the form that edits a food.
  ///
  /// In en, this message translates to:
  /// **'Edit food'**
  String get personalFoodEditTitle;

  /// Tooltip of the form menu button (merge a duplicate, delete).
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get personalFoodMenuTooltip;

  /// Personal food form: shown when the food could not be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this food. Try again.'**
  String get personalFoodLoadFailed;

  /// Personal food form: shown when the food being edited no longer exists. Save is off.
  ///
  /// In en, this message translates to:
  /// **'This food was deleted.'**
  String get personalFoodDeletedBanner;

  /// Personal food form: shown when the food was changed elsewhere while it is open.
  ///
  /// In en, this message translates to:
  /// **'This food changed.'**
  String get personalFoodChangedBanner;

  /// Personal food form and merge sheet: takes over the changed food and keeps what was typed.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get personalFoodReload;

  /// Personal food form: the button that saves the food.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get personalFoodSave;

  /// Personal food form: shown under the form, with a Reload action, when saving was refused because the food changed.
  ///
  /// In en, this message translates to:
  /// **'This food changed elsewhere. Reload to see the latest. What you typed stays.'**
  String get personalFoodSaveChanged;

  /// Personal food form: shown when saving was refused because the food was deleted.
  ///
  /// In en, this message translates to:
  /// **'This food was deleted, so nothing was saved.'**
  String get personalFoodSaveRemoved;

  /// Personal food form: shown when saving did not work.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Check the numbers and try again.'**
  String get personalFoodSaveFailed;

  /// Personal food form: shown when Save was pressed with fields that are not valid yet.
  ///
  /// In en, this message translates to:
  /// **'Some fields need a look. They\'re marked below.'**
  String get personalFoodFixFields;

  /// Snackbar after a personal food was saved, with Undo.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String personalFoodSavedMessage(String name);

  /// Snackbar after a personal food was deleted, with Undo.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String personalFoodDeletedMessage(String name);

  /// Snackbar after two personal foods were merged, with Undo.
  ///
  /// In en, this message translates to:
  /// **'Merged {merged} into {survivor}'**
  String personalFoodsMergedMessage(String merged, String survivor);

  /// Snackbar after two personal foods with the same name were merged, with Undo.
  ///
  /// In en, this message translates to:
  /// **'Merged into {survivor}'**
  String personalFoodsMergedSameName(String survivor);

  /// Form menu: starts merging another food into this one.
  ///
  /// In en, this message translates to:
  /// **'Merge a duplicate into this food…'**
  String get personalFoodMenuMerge;

  /// Form menu: deletes this food. What was logged with it stays.
  ///
  /// In en, this message translates to:
  /// **'Delete food'**
  String get personalFoodMenuDelete;

  /// Personal food form: label of the food name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personalFoodNameLabel;

  /// Personal food form: label of the Arabic name.
  ///
  /// In en, this message translates to:
  /// **'Arabic name (optional)'**
  String get personalFoodNameArLabel;

  /// Personal food form: label of the other names the food is found by.
  ///
  /// In en, this message translates to:
  /// **'Other names (optional)'**
  String get personalFoodAliasesLabel;

  /// Personal food form: hint under the other names field.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas, like labne, lab6a'**
  String get personalFoodAliasesHint;

  /// Personal food form: label of the brand.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get personalFoodBrandLabel;

  /// Personal food form: label of the barcodes field.
  ///
  /// In en, this message translates to:
  /// **'Barcodes (optional)'**
  String get personalFoodBarcodesLabel;

  /// Personal food form: hint of the barcodes field.
  ///
  /// In en, this message translates to:
  /// **'Digits, separated by commas'**
  String get personalFoodBarcodesHint;

  /// Personal food form: a note under the name when another food of yours has the same name.
  ///
  /// In en, this message translates to:
  /// **'You already have {name}'**
  String personalFoodDuplicate(String name);

  /// Personal food form: heading of the food-specific servings.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get personalFoodSectionServings;

  /// Personal food form: caption above the choice of what the typed values are for.
  ///
  /// In en, this message translates to:
  /// **'The label\'s numbers are for'**
  String get personalFoodValuesPer;

  /// Personal food form: note under the choice of what the numbers are for, after it was changed: the typed numbers are not converted.
  ///
  /// In en, this message translates to:
  /// **'Numbers stay as typed.'**
  String get personalFoodNumbersStay;

  /// Personal food form: helper under the serving size of a label typed per serving, e.g. "Shown in your diary as 1 serving (30 g)". The size arrives formatted in the unit system, e.g. "1.1 oz".
  ///
  /// In en, this message translates to:
  /// **'Shown in your diary as 1 {serving} ({size})'**
  String personalFoodServingShownAs(String serving, String size);

  /// Personal food form, screen reader only: the serving size field of a label typed per serving.
  ///
  /// In en, this message translates to:
  /// **'Size of the serving on the label'**
  String get personalFoodServingSizeSemantics;

  /// Personal food form, screen reader only: the size field of one of the food's own servings, e.g. "Size of one piece".
  ///
  /// In en, this message translates to:
  /// **'Size of one {serving}'**
  String personalFoodServingRowSemantics(String serving);

  /// Personal food form, screen reader only: the g choice next to the serving size.
  ///
  /// In en, this message translates to:
  /// **'Serving size in grams'**
  String get personalFoodServingInGrams;

  /// Personal food form, screen reader only: the ml choice next to the serving size.
  ///
  /// In en, this message translates to:
  /// **'Serving size in millilitres'**
  String get personalFoodServingInMl;

  /// Personal food form: the row that shows the Arabic name, other names, brand, state, servings and barcodes.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get personalFoodMoreDetails;

  /// Personal food form: label of the size of a serving.
  ///
  /// In en, this message translates to:
  /// **'Serving size'**
  String get personalFoodServingSize;

  /// Personal food form: label of the chip that names a serving (cup, piece).
  ///
  /// In en, this message translates to:
  /// **'Serving called'**
  String get personalFoodServingCalled;

  /// Personal food form: title of the list of serving names.
  ///
  /// In en, this message translates to:
  /// **'Serving name'**
  String get personalFoodServingUnitTitle;

  /// Unit shown after the calories value.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get personalFoodUnitKcal;

  /// Unit shown after a milligram value.
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get personalFoodUnitMg;

  /// Personal food form: hint of the fibre field.
  ///
  /// In en, this message translates to:
  /// **'Blank counts as 0'**
  String get personalFoodFiberHint;

  /// Personal food form: one line above the optional nutrients under More nutrients.
  ///
  /// In en, this message translates to:
  /// **'Leave blank if you don\'t know'**
  String get personalFoodExtraHint;

  /// Personal food form: opens the optional nutrients (sugar, sodium, ...).
  ///
  /// In en, this message translates to:
  /// **'More nutrients'**
  String get personalFoodMoreNutrients;

  /// Personal food form: caption of the choice of how the food is prepared.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get personalFoodStateLabel;

  /// Personal food form: a choice of how the food is prepared.
  ///
  /// In en, this message translates to:
  /// **'{state, select, raw{Raw} cooked{Cooked} dry{Dry} drained{Drained} fried{Fried} as_sold{As sold} other{}}'**
  String personalFoodStateChoice(String state);

  /// Personal food form: help above the servings.
  ///
  /// In en, this message translates to:
  /// **'Add the portions you use, like a piece or a cup, with their size.'**
  String get personalFoodServingsHint;

  /// Personal food form: adds a serving row.
  ///
  /// In en, this message translates to:
  /// **'Add serving'**
  String get personalFoodAddServing;

  /// Tooltip of the button that removes a serving row.
  ///
  /// In en, this message translates to:
  /// **'Remove serving'**
  String get personalFoodRemoveServing;

  /// Personal food form: a required field is empty.
  ///
  /// In en, this message translates to:
  /// **'Fill this in.'**
  String get personalFoodErrorRequired;

  /// Personal food form: the typed text is not a number.
  ///
  /// In en, this message translates to:
  /// **'Use a number like 12.5.'**
  String get personalFoodErrorNumber;

  /// Personal food form: a number is higher than a food can hold.
  ///
  /// In en, this message translates to:
  /// **'That\'s more than a food can hold.'**
  String get personalFoodErrorBounds;

  /// Personal food form: a nonzero number too small to store (it would round to nothing).
  ///
  /// In en, this message translates to:
  /// **'That\'s too small to save. Use 0 or a bigger number.'**
  String get personalFoodErrorTooSmall;

  /// Personal food form: a text is too long or has too many items.
  ///
  /// In en, this message translates to:
  /// **'That\'s too long. Shorten it.'**
  String get personalFoodErrorText;

  /// Personal food form: a barcode is not valid.
  ///
  /// In en, this message translates to:
  /// **'Check this barcode. It should have 8, 12, 13 or 14 digits.'**
  String get personalFoodErrorBarcode;

  /// Personal food form: a serving is not valid.
  ///
  /// In en, this message translates to:
  /// **'Give each serving a different name and a size from 0.1 to 5,000.'**
  String get personalFoodErrorServing;

  /// Personal food form: the calories or the macros are impossible. Save is refused.
  ///
  /// In en, this message translates to:
  /// **'Those numbers are higher than any food can have. Check them against the label.'**
  String get personalFoodErrorImpossible;

  /// Personal food form: a calm warning when the calories do not match the macros. Saving stays possible.
  ///
  /// In en, this message translates to:
  /// **'These numbers don\'t quite add up: protein, carbs and fat give about {expected} kcal. Check the label, or save anyway.'**
  String personalFoodSanityWarn(int expected);

  /// Title of the sheet asking before a form with unsaved changes is closed.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get personalFoodDiscardTitle;

  /// Discard sheet: what is at stake.
  ///
  /// In en, this message translates to:
  /// **'You\'ve changed this food but haven\'t saved it.'**
  String get personalFoodDiscardMessage;

  /// Discard sheet: goes back to the form.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get personalFoodDiscardKeep;

  /// Discard sheet: closes the form without saving.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get personalFoodDiscardConfirm;

  /// Title of the list of foods that can be merged into this one.
  ///
  /// In en, this message translates to:
  /// **'Merge a duplicate'**
  String get personalFoodMergeTitle;

  /// Merge list: help above the foods.
  ///
  /// In en, this message translates to:
  /// **'Choose the duplicate. It goes into {name}.'**
  String personalFoodMergePickMessage(String name);

  /// Merge list: shown when no other food measured the same way can be merged. unit is g or ml.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, ml{You have no other food in millilitres to merge.} other{You have no other food in grams to merge.}}'**
  String personalFoodMergeNone(String unit);

  /// Title of the merge confirmation.
  ///
  /// In en, this message translates to:
  /// **'Merge these foods?'**
  String get personalFoodMergeConfirmTitle;

  /// Merge confirmation: what happens.
  ///
  /// In en, this message translates to:
  /// **'{keep} stays, with its numbers. {other} is removed. Its names are added to {keep}, and anything you logged with it now uses {keep}. Numbers already logged don\'t change.'**
  String personalFoodMergeConfirmMessage(String keep, String other);

  /// Merge confirmation: caption of the food that is kept.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get personalFoodMergeStays;

  /// Merge confirmation: caption of the food that is merged into the other and removed.
  ///
  /// In en, this message translates to:
  /// **'Merged in and removed'**
  String get personalFoodMergeGoes;

  /// Merge confirmation: the second line of a food row, its role then its calories, e.g. "Stays · 180 kcal per 100 g".
  ///
  /// In en, this message translates to:
  /// **'{role} · {kcal}'**
  String personalFoodMergeRowSubtitle(String role, String kcal);

  /// Merge confirmation: swaps which of the two foods is kept.
  ///
  /// In en, this message translates to:
  /// **'Keep the other one instead'**
  String get personalFoodMergeSwap;

  /// Merge confirmation: the button that merges.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get personalFoodMergeConfirm;

  /// Merge confirmation: shown when a food changed after it was chosen.
  ///
  /// In en, this message translates to:
  /// **'One of these foods changed, so nothing was merged. Reload to see the latest.'**
  String get personalFoodMergeChanged;

  /// Merge confirmation: shown when a food was deleted after it was chosen.
  ///
  /// In en, this message translates to:
  /// **'One of these foods was deleted, so nothing was merged.'**
  String get personalFoodMergeRemoved;

  /// Merge confirmation: shown when the merged food would be over its limits.
  ///
  /// In en, this message translates to:
  /// **'Together they\'d have too many names, barcodes or servings. Remove some first.'**
  String get personalFoodMergeTooMany;

  /// Merge confirmation: shown when the two foods use different units.
  ///
  /// In en, this message translates to:
  /// **'These foods are measured differently (grams and millilitres).'**
  String get personalFoodMergeBasis;

  /// Merge confirmation: shown when merging did not work.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t merge these foods. Try again.'**
  String get personalFoodMergeFailed;

  /// Add-food search: the row and button that start a food of your own named like the search.
  ///
  /// In en, this message translates to:
  /// **'Create \"{query}\" as your own food'**
  String foodSearchCreate(String query);

  /// Food sheet: shown, with a Close action, when the food changed or was deleted before it could be added.
  ///
  /// In en, this message translates to:
  /// **'This food changed, so nothing was logged. Pick it again.'**
  String get foodSheetAddChanged;

  /// Change-food sheet: shown, with a Close action, when the new food changed or was deleted before it could be used.
  ///
  /// In en, this message translates to:
  /// **'This food changed, so nothing was changed. Pick it again.'**
  String get foodSheetReplaceChanged;

  /// Me tab: the row that opens the list of saved meals (DY-031).
  ///
  /// In en, this message translates to:
  /// **'Saved meals'**
  String get meSavedMeals;

  /// Title of the list of saved meals.
  ///
  /// In en, this message translates to:
  /// **'Saved meals'**
  String get savedMealsTitle;

  /// Saved meals: title of the empty state (UX-050).
  ///
  /// In en, this message translates to:
  /// **'No saved meals yet'**
  String get savedMealsEmptyTitle;

  /// Saved meals: one line of help in the empty state.
  ///
  /// In en, this message translates to:
  /// **'Open a meal\'s menu on Today and choose Save as meal.'**
  String get savedMealsEmptyMessage;

  /// Saved meals: banner when the list can't be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your saved meals. Try again.'**
  String get savedMealsLoadFailed;

  /// Saved meal screen: title while the meal's name is not loaded yet.
  ///
  /// In en, this message translates to:
  /// **'Saved meal'**
  String get savedMealDefaultTitle;

  /// Saved meal screen: heading above the meal's items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get savedMealItemsHeader;

  /// Saved meal screen: title of the sheet that picks which meal the saved meal is logged into.
  ///
  /// In en, this message translates to:
  /// **'Log to meal'**
  String get savedMealPickMealTitle;

  /// Saved meal detail at large text: an item's amount and calories on one wrapping line (for example '150 g · 120 kcal').
  ///
  /// In en, this message translates to:
  /// **'{amount} · {kcal}'**
  String savedMealItemSubtitle(String amount, String kcal);

  /// Saved meal screen: button that logs the saved meal into the chosen meal and day (DY-031).
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get savedMealLogButton;

  /// Saved meal screen: why Log is off for a meal without items.
  ///
  /// In en, this message translates to:
  /// **'This meal has no items.'**
  String get savedMealNoItems;

  /// Saved meal screen: tooltip and screen-reader label of the pencil button.
  ///
  /// In en, this message translates to:
  /// **'Rename meal'**
  String get savedMealRenameTooltip;

  /// Title of the sheet that renames a saved meal.
  ///
  /// In en, this message translates to:
  /// **'Rename meal'**
  String get savedMealRenameTitle;

  /// Saved meal screen: tooltip and screen-reader label of the overflow button.
  ///
  /// In en, this message translates to:
  /// **'More for this meal'**
  String get savedMealMenuTooltip;

  /// Saved meal screen: overflow action that deletes the saved meal (with Undo).
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get savedMealDeleteAction;

  /// Snackbar (with Undo) after a saved meal was renamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String savedMealRenamedMessage(String name);

  /// Snackbar (with Undo) after a saved meal was deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String savedMealDeletedMessage(String name);

  /// Saved meal screen: shown when the meal on screen was deleted elsewhere.
  ///
  /// In en, this message translates to:
  /// **'This saved meal was deleted.'**
  String get savedMealGone;

  /// Rename sheet: shown when the meal was deleted while the sheet was open.
  ///
  /// In en, this message translates to:
  /// **'This meal was deleted, so it can\'t be renamed.'**
  String get savedMealRenameGone;

  /// Rename sheet: shown, with Reload, when the meal was renamed while the sheet was open.
  ///
  /// In en, this message translates to:
  /// **'This meal was renamed. Reload to see its new name.'**
  String get savedMealRenameChanged;

  /// Snackbar or sheet note when a rename was refused because the meal changed.
  ///
  /// In en, this message translates to:
  /// **'That meal changed. Nothing was renamed.'**
  String get savedMealChangedRename;

  /// Snackbar when a delete was refused because the meal changed.
  ///
  /// In en, this message translates to:
  /// **'That meal changed. Nothing was deleted.'**
  String get savedMealChangedDelete;

  /// Snackbar (with Undo) after a quick-add chip logged a food: its name and the amount that was logged (the last-used amount).
  ///
  /// In en, this message translates to:
  /// **'Logged {name}, {amount}'**
  String quickAddLoggedAmount(String name, String amount);

  /// Snackbar (with Undo) after a saved meal logged: its name and how many items it added.
  ///
  /// In en, this message translates to:
  /// **'Logged {name}, {count, plural, =1{1 item} other{{count} items}}'**
  String quickAddLoggedItems(String name, int count);

  /// Snackbar (with Undo) when a quick-add chip or a saved meal logged on another day: the message above, then the day. The day is 'yesterday' (lower case) or a date such as 'Fri, Oct 17'.
  ///
  /// In en, this message translates to:
  /// **'{message} for {day}'**
  String quickAddLoggedOn(String message, String day);

  /// Snackbar when a chip or saved meal was refused because what it shows changed meanwhile (PA1).
  ///
  /// In en, this message translates to:
  /// **'That changed. Nothing was logged.'**
  String get quickAddChanged;

  /// Screen-reader label of a quick-add chip.
  ///
  /// In en, this message translates to:
  /// **'Log {name}'**
  String quickAddChipSemantics(String name);

  /// Screen-reader label of a quick-add chip that logs a saved meal.
  ///
  /// In en, this message translates to:
  /// **'Log saved meal {name}'**
  String quickAddSavedMealChipSemantics(String name);

  /// Screen-reader label of the row of quick-add chips above the input bar on Today.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAddRowSemantics;

  /// Me tab: heading of the settings rows (units, week start, halal, theme, city).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get meSectionSettings;

  /// Me tab: heading of the section for the user's own data (export).
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get meSectionYourData;

  /// Me tab: row that opens the export sheet (AC-030). Also the sheet's title.
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get meExportData;

  /// Me tab: heading of the About section.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get meSectionAbout;

  /// Me tab: heading of the developer-only rows (dev flavor).
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get meSectionDeveloper;

  /// Me tab: row that opens the About screen.
  ///
  /// In en, this message translates to:
  /// **'About Fitness Buddy'**
  String get meAbout;

  /// Settings row and sheet title: metric or imperial display units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// Units choice: metric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get settingsUnitsMetric;

  /// Units choice: what metric shows, under "Metric".
  ///
  /// In en, this message translates to:
  /// **'Grams, millilitres, kilograms'**
  String get settingsUnitsMetricHint;

  /// Units choice: imperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get settingsUnitsImperial;

  /// Units choice: what imperial shows, under "Imperial".
  ///
  /// In en, this message translates to:
  /// **'Ounces, fluid ounces, pounds'**
  String get settingsUnitsImperialHint;

  /// Settings row and sheet title: the first day of the week.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get settingsWeekStart;

  /// Settings row: switch for showing halal food only.
  ///
  /// In en, this message translates to:
  /// **'Halal food'**
  String get settingsHalal;

  /// Settings row and sheet title: light, dark or the phone's setting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme choice: follow the phone's light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Theme choice: always light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme choice: always dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Settings row: the city used for prayer times and local suggestions.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get settingsCity;

  /// Settings row: shown when no city is chosen.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsCityNotSet;

  /// Settings info row: what energy is shown in.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get settingsEnergy;

  /// Undo snackbar after the units were changed to metric.
  ///
  /// In en, this message translates to:
  /// **'Units set to metric'**
  String get settingsUnitsSetMetric;

  /// Undo snackbar after the units were changed to imperial.
  ///
  /// In en, this message translates to:
  /// **'Units set to imperial'**
  String get settingsUnitsSetImperial;

  /// Undo snackbar after the first day of the week was changed. day is a weekday name.
  ///
  /// In en, this message translates to:
  /// **'Week now starts on {day}'**
  String settingsWeekStartSet(String day);

  /// Undo snackbar after the halal switch was turned on.
  ///
  /// In en, this message translates to:
  /// **'Halal food turned on'**
  String get settingsHalalSetOn;

  /// Undo snackbar after the halal switch was turned off.
  ///
  /// In en, this message translates to:
  /// **'Halal food turned off'**
  String get settingsHalalSetOff;

  /// Undo snackbar after the theme was changed. theme is the name of the choice (System, Light, Dark).
  ///
  /// In en, this message translates to:
  /// **'Theme set to {theme}'**
  String settingsThemeSet(String theme);

  /// Undo snackbar after a city was chosen. city is the English city name.
  ///
  /// In en, this message translates to:
  /// **'City set to {city}'**
  String settingsCitySet(String city);

  /// Snackbar when a setting could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that setting. Try again.'**
  String get settingsSaveFailed;

  /// Title of the city picker screen.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityPickerTitle;

  /// City picker: hint of the search field.
  ///
  /// In en, this message translates to:
  /// **'Search for a city'**
  String get cityPickerSearchHint;

  /// City picker: heading above the suggested cities shown before anything is typed.
  ///
  /// In en, this message translates to:
  /// **'Suggested cities'**
  String get cityPickerSuggested;

  /// City picker: shown when the list of cities could not be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the city list.'**
  String get cityPickerLoadFailed;

  /// City picker: button that reads the list of cities again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get cityPickerTryAgain;

  /// City picker: shown when the app has no city list.
  ///
  /// In en, this message translates to:
  /// **'The city list isn\'t available right now.'**
  String get cityPickerUnavailable;

  /// City picker: shown when the typed text matches no city.
  ///
  /// In en, this message translates to:
  /// **'No city found. Try the English or Arabic name.'**
  String get cityPickerNoMatch;

  /// City picker (dev flavor only): row for choosing the city from the phone's location.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get cityPickerUseLocation;

  /// City picker (dev flavor only): says the location row does nothing yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get cityPickerComingSoon;

  /// City picker row: the English and the Arabic name of a city, e.g. "Nablus · نابلس".
  ///
  /// In en, this message translates to:
  /// **'{english} · {arabic}'**
  String cityName(String english, String arabic);

  /// City picker: the country name for ISO code PS, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Palestine'**
  String get countryPS;

  /// City picker: the country name for ISO code JO, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get countryJO;

  /// City picker: the country name for ISO code EG, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get countryEG;

  /// City picker: the country name for ISO code TR, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Türkiye'**
  String get countryTR;

  /// City picker: the country name for ISO code IQ, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Iraq'**
  String get countryIQ;

  /// City picker: the country name for ISO code SA, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get countrySA;

  /// City picker: the country name for ISO code SY, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Syria'**
  String get countrySY;

  /// City picker: the country name for ISO code AE, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get countryAE;

  /// City picker: the country name for ISO code OM, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Oman'**
  String get countryOM;

  /// City picker: the country name for ISO code QA, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get countryQA;

  /// City picker: the country name for ISO code YE, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Yemen'**
  String get countryYE;

  /// City picker: the country name for ISO code LB, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Lebanon'**
  String get countryLB;

  /// City picker: the country name for ISO code KW, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get countryKW;

  /// City picker: the country name for ISO code BH, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Bahrain'**
  String get countryBH;

  /// City picker: the country name for ISO code MA, under a city's name.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get countryMA;

  /// Title of the About screen.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// About: the app version and build number.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String aboutVersion(String version, String build);

  /// About: the app version and build number of a non-production build, with the build's name (dev or staging).
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build}) · {flavor}'**
  String aboutVersionFlavor(String version, String build, String flavor);

  /// About: the version of the food data on the phone.
  ///
  /// In en, this message translates to:
  /// **'Food data version {version}'**
  String aboutFoodDataVersion(int version);

  /// About: heading of the sources the food and city data come from.
  ///
  /// In en, this message translates to:
  /// **'Data credits'**
  String get aboutCreditsTitle;

  /// About: shown when the food data can't be read, so its credits can't be shown.
  ///
  /// In en, this message translates to:
  /// **'Data credits aren\'t available right now.'**
  String get aboutCreditsUnavailable;

  /// About: shown in place of the app and food data versions when they can't be read.
  ///
  /// In en, this message translates to:
  /// **'Version isn\'t available right now.'**
  String get aboutInfoUnavailable;

  /// About: one data source and the credit line it requires, e.g. "USDA FoodData Central: ...".
  ///
  /// In en, this message translates to:
  /// **'{name}: {credit}'**
  String aboutCredit(String name, String credit);

  /// About: row that opens the list of open-source licences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutLicenses;

  /// About: the line saying the app is not medical advice (SF-040).
  ///
  /// In en, this message translates to:
  /// **'Fitness Buddy gives estimates for tracking, not medical advice.'**
  String get aboutNotMedical;

  /// Export sheet: what the export contains and where it is made (AC-030).
  ///
  /// In en, this message translates to:
  /// **'Your diary, foods, saved meals and settings as CSV spreadsheet files and one JSON file.'**
  String get exportWhat;

  /// Export sheet: the export holds live rows only, not deleted ones.
  ///
  /// In en, this message translates to:
  /// **'Deleted items and Buddy chats are left out.'**
  String get exportLiveOnly;

  /// Export sheet: privacy line. The files leave the app through the system share sheet; no install identity is in them.
  ///
  /// In en, this message translates to:
  /// **'Fitness Buddy uploads nothing. Files are not encrypted; whichever app you share them with can read them. Nothing that identifies this phone is included.'**
  String get exportPrivacy;

  /// Export sheet: button that builds the files and opens the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// Export sheet: shown while the files are being made.
  ///
  /// In en, this message translates to:
  /// **'Preparing your files…'**
  String get exportWorking;

  /// Export sheet: shown after the share sheet was opened with the files. entries is the number of rows across all files; files the number of files.
  ///
  /// In en, this message translates to:
  /// **'Handed to the share sheet: {entries, plural, =1{1 entry} other{{entries} entries}} in {files, plural, =1{1 file} other{{files} files}}.'**
  String exportDone(int entries, int files);

  /// Export sheet: shown when the user closed the share sheet without choosing a target.
  ///
  /// In en, this message translates to:
  /// **'Sharing was cancelled. Nothing was sent.'**
  String get exportDismissed;

  /// Export sheet: error banner when the files could not be made or shared (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the export. Try again.'**
  String get exportFailed;

  /// Export sheet: banner action that repeats a failed export.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get exportTryAgain;

  /// Export sheet: button that repeats a finished export.
  ///
  /// In en, this message translates to:
  /// **'Export again'**
  String get exportExportAgain;

  /// Export sheet: button that closes the sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get exportClose;

  /// Export sheet: button that closes the sheet after a finished export.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get exportDoneButton;

  /// About: title of the confirm sheet shown after a long press on the version line (A11 D17).
  ///
  /// In en, this message translates to:
  /// **'Send a test error report?'**
  String get aboutTestReportTitle;

  /// About: what the test error report does.
  ///
  /// In en, this message translates to:
  /// **'This queues two made-up test errors for the crash-report service, with app and device information. Your diary and other personal content are not included.'**
  String get aboutTestReportBody;

  /// About: confirm button of the test error report sheet.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aboutTestReportSend;

  /// About: cancel button of the test error report sheet.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get aboutTestReportCancel;

  /// About: snackbar after the test error report was sent.
  ///
  /// In en, this message translates to:
  /// **'Test report queued'**
  String get aboutTestReportSent;

  /// About: snackbar when the test report can't be sent because this is a dev build.
  ///
  /// In en, this message translates to:
  /// **'Crash reports are off in dev builds, so nothing was sent.'**
  String get aboutTestReportOffDev;

  /// About: snackbar when the test report can't be sent because this staging or prod build has no crash-report address.
  ///
  /// In en, this message translates to:
  /// **'Crash reports aren\'t set up in this build, so nothing was sent.'**
  String get aboutTestReportOffNoDsn;

  /// Me > Settings: row that opens the screen where meals are renamed, added, removed, reordered and given time windows (DY-010).
  ///
  /// In en, this message translates to:
  /// **'Meal times'**
  String get settingsMealTimes;

  /// Title of the Meal times screen.
  ///
  /// In en, this message translates to:
  /// **'Meal times'**
  String get mealTimesTitle;

  /// Meal times: note under the list.
  ///
  /// In en, this message translates to:
  /// **'Times decide which meal new food goes into. Food you\'ve already logged stays where it is.'**
  String get mealTimesFootnote;

  /// Meal times: button that opens the sheet to add a meal.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get mealTimesAdd;

  /// Meal times: shown instead of the add hint when the limit is reached.
  ///
  /// In en, this message translates to:
  /// **'You can have up to {max} meals.'**
  String mealTimesAddLimit(int max);

  /// Meal times: a meal without a time window catches any time.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get mealTimesAnyTime;

  /// Meal times: a time window, from one clock time to another.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String mealTimesWindow(String start, String end);

  /// Meal times: a time window that runs past midnight.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}, overnight'**
  String mealTimesWindowOvernight(String start, String end);

  /// Meal times: second line of a meal row, its time window and how many items it holds.
  ///
  /// In en, this message translates to:
  /// **'{window} · {items}'**
  String mealTimesRowSubtitle(String window, String items);

  /// Meal times: banner when the meals can't be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your meals.'**
  String get mealTimesLoadFailed;

  /// Meal times: action of the load-failed banner.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get mealTimesTryAgain;

  /// Meal times: snackbar when a reorder was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the order. It was left as it was.'**
  String get mealTimesReorderFailed;

  /// Meal times: Undo snackbar after the order changed.
  ///
  /// In en, this message translates to:
  /// **'Meals reordered'**
  String get mealTimesReordered;

  /// How many logged items a meal holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no items} =1{1 item} other{{count} items}}'**
  String slotItemsCount(int count);

  /// On how many days a meal has items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String slotDaysCount(int count);

  /// Title of the sheet that edits a meal.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get slotEditTitle;

  /// Title of the sheet that adds a meal.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get slotAddTitle;

  /// Meal sheet: label of the name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get slotNameLabel;

  /// Meal sheet: hint under the name of a built-in meal.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use {name}'**
  String slotNameHintDefault(String name);

  /// Meal sheet: the typed name is another meal's name.
  ///
  /// In en, this message translates to:
  /// **'Another meal already has this name.'**
  String get slotNameTaken;

  /// Meal sheet: the name was refused.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 30 characters for the name.'**
  String get slotNameInvalid;

  /// Meal sheet: switch that gives the meal a time window.
  ///
  /// In en, this message translates to:
  /// **'Set times'**
  String get slotSetTimes;

  /// Meal sheet: explains what the time window does.
  ///
  /// In en, this message translates to:
  /// **'New food logged in this window goes into this meal.'**
  String get slotSetTimesHint;

  /// Meal sheet: chip for the start of the window.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get slotFrom;

  /// Meal sheet: chip for the end of the window.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get slotTo;

  /// Meal sheet: the window is empty.
  ///
  /// In en, this message translates to:
  /// **'From and To can\'t be the same time.'**
  String get slotTimesSame;

  /// Meal sheet: saves the changes.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get slotSave;

  /// Meal sheet: adds the new meal.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get slotAddButton;

  /// Meal sheet: opens the remove sheet.
  ///
  /// In en, this message translates to:
  /// **'Remove meal'**
  String get slotRemoveAction;

  /// Meal sheet: shown instead of Remove when this is the only meal.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one meal.'**
  String get slotKeepOne;

  /// Meal sheet: the meal was removed while the sheet was open.
  ///
  /// In en, this message translates to:
  /// **'This meal was removed.'**
  String get slotStaleRemoved;

  /// Meal sheet: the meal was changed while the sheet was open.
  ///
  /// In en, this message translates to:
  /// **'This meal changed.'**
  String get slotStaleChanged;

  /// Meal sheet: the save was refused because the meal changed.
  ///
  /// In en, this message translates to:
  /// **'That meal changed. Nothing was saved.'**
  String get slotSaveChanged;

  /// Undo snackbar after a meal was added.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String slotAddedMessage(String name);

  /// Undo snackbar after a meal was changed.
  ///
  /// In en, this message translates to:
  /// **'{name} updated'**
  String slotUpdatedMessage(String name);

  /// Title of the remove sheet.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String slotRemoveTitle(String name);

  /// Remove sheet: a meal without items.
  ///
  /// In en, this message translates to:
  /// **'{name} has nothing logged. It will leave your day.'**
  String slotRemoveEmpty(String name);

  /// Remove sheet: a meal with items, followed by the choice of where to move them.
  ///
  /// In en, this message translates to:
  /// **'{name} has {items} on {days}. Move them to:'**
  String slotRemoveHasItems(String name, String items, String days);

  /// Remove sheet: removes an empty meal.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get slotRemoveButton;

  /// Remove sheet: removes the meal and moves its items.
  ///
  /// In en, this message translates to:
  /// **'Remove and move'**
  String get slotRemoveMoveButton;

  /// Remove sheet: refused because the meal, its items or the destination changed.
  ///
  /// In en, this message translates to:
  /// **'That meal changed. Nothing was removed.'**
  String get slotRemoveChanged;

  /// Undo snackbar after an empty meal was removed.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String slotRemovedMessage(String name);

  /// Undo snackbar after a meal was removed and its items moved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}, moved {items} to {target}'**
  String slotRemovedMovedMessage(String name, String items, String target);

  /// Shown when a meal was removed before an action could use it.
  ///
  /// In en, this message translates to:
  /// **'That meal was removed. Choose another.'**
  String get diarySlotRemoved;

  /// Food sheet: meal chip when the chosen meal was removed.
  ///
  /// In en, this message translates to:
  /// **'Choose a meal'**
  String get foodSheetSlotChoose;
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
