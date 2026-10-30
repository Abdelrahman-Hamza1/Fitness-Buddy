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

  /// Today: weekly line when the earlier days of the week add up to their plan, rounded (HM-002).
  ///
  /// In en, this message translates to:
  /// **'This week: on track'**
  String get todayWeekOnTrack;

  /// Today: added to the weekly line for earlier days of the week with no food logged or marked incomplete; they are not counted (TG-032).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day not counted} other{{count} days not counted}}'**
  String todayWeekUncounted(int count);

  /// Today: the weekly line followed by how many days are not counted, e.g. "This week: 350 kcal under · 1 day not counted".
  ///
  /// In en, this message translates to:
  /// **'{line} · {uncounted}'**
  String todayWeekWithUncounted(String line, String uncounted);

  /// Screen readers: the progress bar under the big number, e.g. "1,560 of 2,800 kcal eaten".
  ///
  /// In en, this message translates to:
  /// **'{eaten} of {budget} kcal eaten'**
  String todayEatenOfBudgetSemantics(String eaten, String budget);

  /// Today: a macro eaten out of its target, next to its bar, e.g. "82 / 140 g" (HM-003).
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {target} g'**
  String todayMacroOfTarget(double eaten, int target);

  /// Today: a macro with no target (carbs and fat in 'calories and protein only', TG-054), e.g. "96 g".
  ///
  /// In en, this message translates to:
  /// **'{eaten} g'**
  String todayMacroEaten(double eaten);

  /// Today: the row under the big number that opens setup while no targets exist (A13 D10).
  ///
  /// In en, this message translates to:
  /// **'Set up your targets'**
  String get todaySetupTitle;

  /// Today: second line of the setup row, how long setup takes.
  ///
  /// In en, this message translates to:
  /// **'About 2 minutes'**
  String get todaySetupTime;

  /// Today: second line of the 'Update the app' row, shown instead of the setup row when the stored profile was saved by a newer app version.
  ///
  /// In en, this message translates to:
  /// **'Your profile needs a newer version'**
  String get todayUpdateSubtitle;

  /// Today: the targets couldn't be read; the calories eaten still show (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your targets.'**
  String get todayTargetsLoadFailed;

  /// Today: retries loading the targets.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get todayTargetsTryAgain;

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

  /// Proposal card heading for a meal on another day than today: the day, then the meal and time, e.g. "Yesterday · Breakfast · 8:40 AM" (A22 review).
  ///
  /// In en, this message translates to:
  /// **'{day} · {when}'**
  String proposalOnDay(String day, String when);

  /// Proposal card for another day: calories left that day once the card is logged (AI-031).
  ///
  /// In en, this message translates to:
  /// **'{day} after this: {left} left'**
  String proposalDayAfter(String day, String left);

  /// Proposal card for another day: calories eaten that day once logged, when there is no target.
  ///
  /// In en, this message translates to:
  /// **'{day} after this: {eaten} eaten'**
  String proposalDayAfterEaten(String day, String eaten);

  /// Proposal card for another day: calories over that day's target once logged; neutral.
  ///
  /// In en, this message translates to:
  /// **'{day} after this: {over} over'**
  String proposalDayAfterOver(String day, String over);

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

  /// Proposal card: total calories when some items are estimates (SF-041, D-045).
  ///
  /// In en, this message translates to:
  /// **'~{kcal} kcal'**
  String proposalTotalKcalApprox(String kcal);

  /// An estimated calorie number inside a sentence, e.g. "Today after this: ~1,430 eaten".
  ///
  /// In en, this message translates to:
  /// **'~{kcal}'**
  String proposalApprox(String kcal);

  /// Estimate sheet of a card's total: why it is an estimate.
  ///
  /// In en, this message translates to:
  /// **'Some items are estimates, so the total is too.'**
  String get proposalEstimateReasonTotal;

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

  /// Screen-reader label of the Buddy chat sheet (UX-011).
  ///
  /// In en, this message translates to:
  /// **'Buddy chat'**
  String get buddySheetLabel;

  /// Hint of the Buddy composer (AI-001).
  ///
  /// In en, this message translates to:
  /// **'Tell Buddy what you ate…'**
  String get buddyComposerHint;

  /// Tooltip of the composer button that sends the message to Buddy.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get buddySend;

  /// Tooltip of the magnifier in the composer, and the action under a failed Buddy message: opens food search (works offline).
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get buddySearchFoods;

  /// Buddy sheet: shown before the first message of this session (AI-036).
  ///
  /// In en, this message translates to:
  /// **'Tell Buddy what you ate, like \"2 eggs and toast\". Nothing is logged until you tap Log it.'**
  String get buddyEmpty;

  /// Buddy's fixed English reply above one or more proposal cards (AI-143).
  ///
  /// In en, this message translates to:
  /// **'Here\'s your meal. Check it, then tap Log it.'**
  String get buddyReplyCards;

  /// Screen-reader label of the chat sheet's drag handle: a tap opens the sheet to full height (UX-012).
  ///
  /// In en, this message translates to:
  /// **'Expand chat'**
  String get buddySheetExpand;

  /// Screen-reader label of the chat sheet's drag handle when it's at full height: a tap brings it back down.
  ///
  /// In en, this message translates to:
  /// **'Shrink chat'**
  String get buddySheetCollapse;

  /// Buddy's fixed English reply when a follow-up message updated the open proposal card (AI-044, AI-143).
  ///
  /// In en, this message translates to:
  /// **'Updated your card. Check it, then tap Log it.'**
  String get buddyReplyUpdated;

  /// Buddy's fixed English reply when a follow-up's card was logged or discarded before the answer arrived (AI-044, AI-143).
  ///
  /// In en, this message translates to:
  /// **'That card was already logged or discarded, so I left it as it is.'**
  String get buddyReplyCardClosed;

  /// Chip above the composer: the next message will update this open card (AI-044, UX-023).
  ///
  /// In en, this message translates to:
  /// **'Updating {slot} card'**
  String buddyFollowUpTarget(String slot);

  /// Chip above the composer when the open card's meal has no name.
  ///
  /// In en, this message translates to:
  /// **'Updating the open card'**
  String get buddyFollowUpTargetNoSlot;

  /// Tooltip and screen-reader label of the ✕ on the follow-up chip: the next message starts a new card.
  ///
  /// In en, this message translates to:
  /// **'Send as a new message'**
  String get buddyFollowUpClear;

  /// Buddy's fixed English reply to a medical question (A22 D16).
  ///
  /// In en, this message translates to:
  /// **'I can\'t help with medical questions. A doctor or pharmacist is the right person to ask.'**
  String get buddyReplyMedical;

  /// Buddy's fixed English reply to a message that isn't about food (A22 D16).
  ///
  /// In en, this message translates to:
  /// **'I can log food here. Try something like \"2 eggs and toast\".'**
  String get buddyReplyNotFood;

  /// Buddy's fixed English reply when its answer can't become a card (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t make a card from that. Try search instead.'**
  String get buddyReplyNoCard;

  /// Buddy's fixed English reply to a request a newer app version handles (04 §4.2).
  ///
  /// In en, this message translates to:
  /// **'Buddy can\'t do that in this version yet. You can log food here.'**
  String get buddyReplyUnsupported;

  /// Under a Buddy message that could not be sent: no connection (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Food search still works.'**
  String get buddyFailureOffline;

  /// Under a Buddy message: no answer in time (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'Buddy didn\'t answer in time.'**
  String get buddyFailureTimeout;

  /// Under a Buddy message: a server error (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'Buddy couldn\'t answer just now.'**
  String get buddyFailureServer;

  /// Under a Buddy message: the service was unavailable once (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'Buddy is busy right now.'**
  String get buddyFailureUnavailable;

  /// Under a Buddy message: unavailable a second time; the text went back to the composer (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'Buddy is still busy. Your text is back in the box below.'**
  String get buddyFailureUnavailableFinal;

  /// Under a Buddy message the server refused (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'Buddy couldn\'t read that message.'**
  String get buddyFailureRejected;

  /// Under a Buddy message: today's limit is reached (A22 D6).
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s Buddy limit. Search still works.'**
  String get buddyFailureRateLimited;

  /// Under a failed Buddy message: sends the same message again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get buddyTryAgain;

  /// Screen-reader label of the placeholder card while Buddy answers (AI-030).
  ///
  /// In en, this message translates to:
  /// **'Buddy is making a card'**
  String get buddyWorking;

  /// Screen-reader label of the user's chat message.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String buddyBubbleYou(String text);

  /// Screen-reader label of Buddy's chat message.
  ///
  /// In en, this message translates to:
  /// **'Buddy: {text}'**
  String buddyBubbleBuddy(String text);

  /// The logged row when its numbers aren't known (fallback).
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get proposalLoggedPlain;

  /// Joins two short notes under a proposal item, e.g. "Your share: 50% · Most of the cooking oil counted".
  ///
  /// In en, this message translates to:
  /// **'{first} · {second}'**
  String proposalNoteJoin(String first, String second);

  /// Proposal card: calories eaten today once the card is logged, when there is no target (AI-031, A22 D15).
  ///
  /// In en, this message translates to:
  /// **'Today after this: {eaten} eaten'**
  String proposalTodayAfterEaten(String eaten);

  /// The one-line reply after Log it (AI-140).
  ///
  /// In en, this message translates to:
  /// **'Logged {kcal} kcal · {left} left today'**
  String proposalLogged(String kcal, String left);

  /// The one-line reply after Log it, when there is no target (AI-140).
  ///
  /// In en, this message translates to:
  /// **'Logged {kcal} kcal · {eaten} eaten today'**
  String proposalLoggedEaten(String kcal, String eaten);

  /// Proposal card: calories over the target once the card is logged; neutral, never alarming (SF-021).
  ///
  /// In en, this message translates to:
  /// **'Today after this: {over} over'**
  String proposalTodayAfterOver(String over);

  /// The one-line reply after Log it, over the target; neutral (SF-021).
  ///
  /// In en, this message translates to:
  /// **'Logged {kcal} kcal · {over} over today'**
  String proposalLoggedOver(String kcal, String over);

  /// The one-line reply after Log it for a meal on another day (AI-140). The day is 'yesterday' (lower case) or a date such as 'Fri, Oct 17'.
  ///
  /// In en, this message translates to:
  /// **'Logged {kcal} kcal for {day}'**
  String proposalLoggedOnDay(String kcal, String day);

  /// One-line state on a proposal card while a follow-up message about it is being answered; the card can't be changed meanwhile (AI-044).
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get proposalUpdating;

  /// Text button at the bottom of a proposal card's items: pick a food in search and add it to the card (AI-042).
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get proposalAddItem;

  /// Last option in the swap sheet: opens food search to pick another food for this item (AI-041).
  ///
  /// In en, this message translates to:
  /// **'Search foods…'**
  String get proposalSearchFoods;

  /// Title of the food search sheet opened from a proposal card (swap or add an item); nothing is logged there.
  ///
  /// In en, this message translates to:
  /// **'Pick a food'**
  String get proposalPickerTitle;

  /// Hint in the search field of the food picker opened from a proposal card.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get proposalPickerHint;

  /// A proposal line's amount while the user types it on the inline number pad: exactly what was typed so far, then the unit (AI-040).
  ///
  /// In en, this message translates to:
  /// **'{typed} {unit}'**
  String proposalAmountTyping(String typed, String unit);

  /// Tooltip and screen-reader label of the − next to an assumed amount on a proposal card (AI-040).
  ///
  /// In en, this message translates to:
  /// **'Less {food}'**
  String proposalAmountLess(String food);

  /// Tooltip and screen-reader label of the + next to an assumed amount on a proposal card (AI-040).
  ///
  /// In en, this message translates to:
  /// **'More {food}'**
  String proposalAmountMore(String food);

  /// Swipe action (and screen-reader action) that takes an item off a proposal card before logging (AI-042).
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get proposalRemoveLine;

  /// Inline row on a proposal card after an item was swiped off, next to Undo (AI-042).
  ///
  /// In en, this message translates to:
  /// **'Removed {food}'**
  String proposalLineRemoved(String food);

  /// Title of the small sheet with up to three other foods an item could be (AI-041).
  ///
  /// In en, this message translates to:
  /// **'Swap {food} for'**
  String proposalSwapTitle(String food);

  /// Title of the small sheet opened from a proposal card's header: pick another meal or change the time (AI-043).
  ///
  /// In en, this message translates to:
  /// **'Meal and time'**
  String get proposalWhenTitle;

  /// Option in the meal-and-time sheet that opens the time picker (AI-043).
  ///
  /// In en, this message translates to:
  /// **'Change time…'**
  String get proposalWhenChangeTime;

  /// Undoes a logged proposal card (AI-035).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get proposalUndo;

  /// A discarded proposal card (AI-037).
  ///
  /// In en, this message translates to:
  /// **'Discarded. Nothing was logged.'**
  String get proposalDiscarded;

  /// A historical proposal card another phone replaced; read-only (A23 D13).
  ///
  /// In en, this message translates to:
  /// **'No longer current. Nothing was logged.'**
  String get proposalSuperseded;

  /// A reopened proposal card whose food details changed since it was made; it can't be logged as it is (A23 D13).
  ///
  /// In en, this message translates to:
  /// **'Food details changed since.'**
  String get proposalFactsChanged;

  /// Button on a reopened card whose food details changed: rebuild it with the current details (A23 D13).
  ///
  /// In en, this message translates to:
  /// **'Update card'**
  String get proposalUpdateCard;

  /// Placeholder for a saved proposal card that can't be shown any more; it can be discarded (A23 D13).
  ///
  /// In en, this message translates to:
  /// **'This card couldn\'t be reopened.'**
  String get proposalUnrestorable;

  /// Note on a proposal card too large to sync to the user's other phones; it is kept on this phone and works as usual (A23 D15).
  ///
  /// In en, this message translates to:
  /// **'Too large to sync to your other phones. It stays on this phone.'**
  String get proposalTooLargeToSync;

  /// Note under a proposal card Buddy rebuilt with the current food details (A23 D11).
  ///
  /// In en, this message translates to:
  /// **'I updated this card with your current food details.'**
  String get buddyCardUpdatedNote;

  /// Proposal card: Log it wrote nothing (A22 D25).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t log this card.'**
  String get proposalCouldNotLog;

  /// Proposal card: shown while Log it is being applied (Log it disabled).
  ///
  /// In en, this message translates to:
  /// **'Logging…'**
  String get proposalLogging;

  /// Proposal card: why Log it is disabled, an item has no amount.
  ///
  /// In en, this message translates to:
  /// **'Add an amount to log this.'**
  String get proposalBlockedNeedsAmount;

  /// Proposal card: why Log it is disabled, a food is missing.
  ///
  /// In en, this message translates to:
  /// **'A food on this card isn\'t available. Search for it instead.'**
  String get proposalBlockedMissingFood;

  /// Proposal card: why Log it is disabled, any other reason.
  ///
  /// In en, this message translates to:
  /// **'This card can\'t be logged. Try search instead.'**
  String get proposalBlockedOther;

  /// Estimate sheet: the likely calorie range (AI-032).
  ///
  /// In en, this message translates to:
  /// **'{low}–{high} kcal'**
  String proposalEstimateRange(String low, String high);

  /// Estimate sheet: why the item is an estimate.
  ///
  /// In en, this message translates to:
  /// **'Based on a typical portion of a reference dish.'**
  String get proposalEstimateReasonReference;

  /// Estimate sheet: why the item is an estimate.
  ///
  /// In en, this message translates to:
  /// **'Buddy\'s estimate: no close match in the food database.'**
  String get proposalEstimateReasonBuddy;

  /// Estimate sheet: why the item is an estimate.
  ///
  /// In en, this message translates to:
  /// **'The amount was guessed.'**
  String get proposalEstimateReasonAmount;

  /// Proposal card question about the weighed state (AI-034).
  ///
  /// In en, this message translates to:
  /// **'How was the {food} weighed?'**
  String proposalQuestionState(String food);

  /// Proposal card question about added oil (AI-034).
  ///
  /// In en, this message translates to:
  /// **'Any cooking oil?'**
  String get proposalQuestionFat;

  /// Proposal card question about the kind of dish (AI-034).
  ///
  /// In en, this message translates to:
  /// **'Which one?'**
  String get proposalQuestionVariant;

  /// Proposal card question about the portion (AI-034).
  ///
  /// In en, this message translates to:
  /// **'How much {food}?'**
  String proposalQuestionPortion(String food);

  /// Proposal card question about the oil left in the pan (AI-034).
  ///
  /// In en, this message translates to:
  /// **'Did you eat all of the oil?'**
  String get proposalQuestionOilRetention;

  /// Proposal card question about a shared dish (AI-034).
  ///
  /// In en, this message translates to:
  /// **'How much of the {food} did you have?'**
  String proposalQuestionShare(String food);

  /// Answer or chip: weighed raw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get proposalStateRaw;

  /// Answer or chip: weighed cooked.
  ///
  /// In en, this message translates to:
  /// **'Cooked'**
  String get proposalStateCooked;

  /// Answer or chip: weighed dry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get proposalStateDry;

  /// Answer or chip: weighed drained.
  ///
  /// In en, this message translates to:
  /// **'Drained'**
  String get proposalStateDrained;

  /// Answer or chip: weighed fried.
  ///
  /// In en, this message translates to:
  /// **'Fried'**
  String get proposalStateFried;

  /// Answer or chip: weighed as sold.
  ///
  /// In en, this message translates to:
  /// **'As sold'**
  String get proposalStateAsSold;

  /// Answer or chip: no added oil.
  ///
  /// In en, this message translates to:
  /// **'No oil'**
  String get proposalOilNone;

  /// Answer or chip: an amount of added oil, e.g. "1 tbsp of oil".
  ///
  /// In en, this message translates to:
  /// **'{amount} of oil'**
  String proposalOilAmount(String amount);

  /// Answer or chip: all of the oil was eaten.
  ///
  /// In en, this message translates to:
  /// **'All of it'**
  String get proposalOilAll;

  /// Answer or chip: most of the oil was eaten.
  ///
  /// In en, this message translates to:
  /// **'Most of it'**
  String get proposalOilMost;

  /// Answer or chip: the share of a dish, e.g. "50% of it".
  ///
  /// In en, this message translates to:
  /// **'{percent}% of it'**
  String proposalShareOption(int percent);

  /// Screen-reader label of an assumption chip (AI-033).
  ///
  /// In en, this message translates to:
  /// **'Assumption: {label}'**
  String proposalChipSemantics(String label);

  /// Assumption chip naming the food it belongs to, e.g. "Rice: cooked" or "Chicken: 150 g" (AI-033).
  ///
  /// In en, this message translates to:
  /// **'{food}: {choice}'**
  String proposalChipFood(String food, String choice);

  /// Assumption chip: all of the cooking oil counts.
  ///
  /// In en, this message translates to:
  /// **'All oil eaten'**
  String get proposalChipOilAll;

  /// Assumption chip: most of the cooking oil counts (some stays in the pan).
  ///
  /// In en, this message translates to:
  /// **'Most oil eaten'**
  String get proposalChipOilMost;

  /// Screen-reader hint of an assumption chip, read as "Double tap to change it".
  ///
  /// In en, this message translates to:
  /// **'change it'**
  String get proposalChipTapHint;

  /// An assumption behind a logged item: a weighed amount converted between states, e.g. "200 g weighed dry, counted as 500 g cooked" (A22 D17).
  ///
  /// In en, this message translates to:
  /// **'{fromAmount} weighed {fromState}, counted as {toAmount} {toState}'**
  String assumptionYield(
    String fromAmount,
    String fromState,
    String toAmount,
    String toState,
  );

  /// Lower-case state word inside an assumption.
  ///
  /// In en, this message translates to:
  /// **'raw'**
  String get assumptionStateRaw;

  /// Lower-case state word inside an assumption.
  ///
  /// In en, this message translates to:
  /// **'cooked'**
  String get assumptionStateCooked;

  /// Lower-case state word inside an assumption.
  ///
  /// In en, this message translates to:
  /// **'dry'**
  String get assumptionStateDry;

  /// Lower-case state word inside an assumption.
  ///
  /// In en, this message translates to:
  /// **'drained'**
  String get assumptionStateDrained;

  /// Lower-case state word inside an assumption.
  ///
  /// In en, this message translates to:
  /// **'fried'**
  String get assumptionStateFried;

  /// Lower-case state word inside an assumption.
  ///
  /// In en, this message translates to:
  /// **'as sold'**
  String get assumptionStateAsSold;

  /// An assumption behind a logged item: all of the oil counts.
  ///
  /// In en, this message translates to:
  /// **'All of the cooking oil counted'**
  String get assumptionOilAll;

  /// An assumption behind a logged item: most of the oil counts.
  ///
  /// In en, this message translates to:
  /// **'Most of the cooking oil counted (some stays in the pan)'**
  String get assumptionOilMost;

  /// An assumption behind a logged item: the share of a dish eaten.
  ///
  /// In en, this message translates to:
  /// **'Your share: {percent}%'**
  String assumptionShare(int percent);

  /// An assumption behind a logged item: the choice came from the message.
  ///
  /// In en, this message translates to:
  /// **'As you said'**
  String get assumptionOriginStated;

  /// An assumption behind a logged item: the choice came from a saved default.
  ///
  /// In en, this message translates to:
  /// **'Your usual choice'**
  String get assumptionOriginSavedDefault;

  /// An assumption behind a logged item: a visible default was used.
  ///
  /// In en, this message translates to:
  /// **'A typical choice was assumed'**
  String get assumptionOriginFallback;

  /// An assumption behind a logged item: the user changed the choice on the card.
  ///
  /// In en, this message translates to:
  /// **'Changed by you'**
  String get assumptionOriginUserAdjusted;

  /// An assumption the app has no words for (an unknown or older code): never the raw text.
  ///
  /// In en, this message translates to:
  /// **'Assumed value'**
  String get assumptionGeneric;

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

  /// A body weight with its unit: "97.6 kg" (A14 D13). The value arrives formatted with one decimal.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String weightValue(String value, String unit);

  /// Unit label for kilograms, for body weight (A14).
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get weightUnitKg;

  /// Unit label for pounds, for body weight (A14).
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get weightUnitLb;

  /// Weekly rate of the weight trend, signed: "−0.4 kg/week" (WB-011). Neutral: no good/bad wording.
  ///
  /// In en, this message translates to:
  /// **'{rate} {unit}/week'**
  String weightCardRate(String rate, String unit);

  /// Weight card: the trend weight, the main number (WB-011): "Trend 97.6 kg".
  ///
  /// In en, this message translates to:
  /// **'Trend {weight}'**
  String weightCardTrend(String weight);

  /// Weight card: there is a trend but not enough history for a weekly rate yet (WB-011).
  ///
  /// In en, this message translates to:
  /// **'Weekly rate after 2 weeks of weigh-ins'**
  String get weightCardRateLater;

  /// Weight card: the last weigh-in is 4 weeks old or older, so no rate; the trend is from that day (A14 PA2).
  ///
  /// In en, this message translates to:
  /// **'Trend {weight} · from {date}'**
  String weightCardTrendFrom(String weight, String date);

  /// Weight card: the latest weigh-in on or before the page's day, smaller: "Last weigh-in 97.4 kg · Yesterday".
  ///
  /// In en, this message translates to:
  /// **'Last weigh-in {weight} · {when}'**
  String weightCardLast(String weight, String when);

  /// Weight card: the latest weigh-in when the trend line already says its date (stale): "Last weigh-in 97.4 kg".
  ///
  /// In en, this message translates to:
  /// **'Last weigh-in {weight}'**
  String weightCardLastValue(String weight);

  /// Weight card: no weigh-in at all yet (UX-050).
  ///
  /// In en, this message translates to:
  /// **'Log your first weigh-in'**
  String get weightCardEmpty;

  /// Weight card on a past day page: no weigh-in on or before that day, but later ones exist (UX-050).
  ///
  /// In en, this message translates to:
  /// **'No weigh-ins by this day. Tap to add one.'**
  String get weightCardEmptyPast;

  /// Weight card, today only: honest note when there are few weigh-ins (WB-012). Information, not a nag.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 weigh-in in 4 weeks · trend updates slowly} other{{count} weigh-ins in 4 weeks · trend updates slowly}}'**
  String weightCardSparse(int count);

  /// Weight card, today only: a suggestion shown at most once a month while weigh-ins are sparse (WB-012). Calm, no pressure.
  ///
  /// In en, this message translates to:
  /// **'Weighing in 2–3 times a week makes the trend steadier.'**
  String get weightCardTip;

  /// Weight card: dismisses the weigh-in suggestion.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get weightCardTipDismiss;

  /// Weight card: the weigh-ins couldn't be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your weigh-ins.'**
  String get weightCardLoadFailed;

  /// Weight card: retries loading the weigh-ins.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get weightCardTryAgain;

  /// Screen readers: a body weight in kilograms, unit in full: "97.6 kilograms". The value arrives formatted, possibly signed.
  ///
  /// In en, this message translates to:
  /// **'{value} kilograms'**
  String weightSpokenKg(String value);

  /// Screen readers: a body weight in pounds, unit in full: "215.2 pounds". The value arrives formatted, possibly signed.
  ///
  /// In en, this message translates to:
  /// **'{value} pounds'**
  String weightSpokenLb(String value);

  /// Weight card, first row, screen readers: the trend (weight with the unit in full).
  ///
  /// In en, this message translates to:
  /// **'Weight trend {weight}'**
  String weightCardTrendSemantics(String weight);

  /// Weight card, first row, screen readers: the trend and its signed weekly change, units in full. Neutral.
  ///
  /// In en, this message translates to:
  /// **'Weight trend {weight}, {change} per week'**
  String weightCardTrendRateSemantics(String weight, String change);

  /// Weight card, first row, screen readers: a trend whose last weigh-in is 4 weeks old or older.
  ///
  /// In en, this message translates to:
  /// **'Weight trend {weight}, from {date}'**
  String weightCardTrendFromSemantics(String weight, String date);

  /// Weight card, second row, screen readers: the latest weigh-in, unit in full, and its day.
  ///
  /// In en, this message translates to:
  /// **'Last weigh-in {weight}, {when}'**
  String weightCardLastSemantics(String weight, String when);

  /// Weight card, second row, screen readers: the latest weigh-in when the trend already says its date.
  ///
  /// In en, this message translates to:
  /// **'Last weigh-in {weight}'**
  String weightCardLastValueSemantics(String weight);

  /// Weight card without a weigh-in on or before the day, screen readers: the title and the visible invitation.
  ///
  /// In en, this message translates to:
  /// **'Weight. {message}'**
  String weightCardEmptySemantics(String message);

  /// Weight card, first row, screen readers: the trend sentence, then what a tap does.
  ///
  /// In en, this message translates to:
  /// **'{summary}. Log a weigh-in'**
  String weightCardLogSemantics(String summary);

  /// Weight card, first row, screen readers: the trend sentence, the visible note under it (rate after 2 weeks, or the weigh-in count), then what a tap does.
  ///
  /// In en, this message translates to:
  /// **'{summary}. {note}. Log a weigh-in'**
  String weightCardLogNoteSemantics(String summary, String note);

  /// Weight card, last weigh-in row, screen readers: the last weigh-in sentence, then what a tap does.
  ///
  /// In en, this message translates to:
  /// **'{summary}. Edit'**
  String weightCardEditSemantics(String summary);

  /// Weigh-in sheet: title when logging a new weigh-in (WB-001).
  ///
  /// In en, this message translates to:
  /// **'Log weigh-in'**
  String get weighInSheetTitle;

  /// Weigh-in sheet: title when editing a weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Edit weigh-in'**
  String get weighInEditTitle;

  /// Weigh-in sheet: the pinned button that saves the weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get weighInSave;

  /// Weigh-in sheet, edit mode: deletes the weigh-in (with Undo).
  ///
  /// In en, this message translates to:
  /// **'Delete weigh-in'**
  String get weighInDelete;

  /// Weigh-in sheet: what a screen reader says for the typed value: "Weight, 97.4 kg".
  ///
  /// In en, this message translates to:
  /// **'Weight, {weight}'**
  String weighInValueSemantics(String weight);

  /// Weigh-in sheet: label of the date and time chip.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get weighInWhenLabel;

  /// Weigh-in sheet: the measured date and time: "Today, 07:42".
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String weighInDayTime(String day, String time);

  /// Weigh-in sheet: chip that shows the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get weighInAddNote;

  /// Weigh-in sheet: label of the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get weighInNoteLabel;

  /// Weigh-in sheet: hint in the empty note field.
  ///
  /// In en, this message translates to:
  /// **'e.g. after Eid'**
  String get weighInNoteHint;

  /// Weigh-in sheet: the note is longer than the limit.
  ///
  /// In en, this message translates to:
  /// **'Keep the note to {max} characters'**
  String weighInNoteTooLong(int max);

  /// Weigh-in sheet: the note contains a control character.
  ///
  /// In en, this message translates to:
  /// **'The note has a character that can\'t be saved'**
  String get weighInNoteInvalid;

  /// Weigh-in sheet: hint once more digits can't bring the typed value into the allowed range (A14 D6). Both bounds arrive as whole numbers with their unit: "20 kg", "500 kg".
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between {min} and {max}'**
  String weighInOutOfRange(String min, String max);

  /// Weigh-in sheet: the chosen date and time are after now; Save is disabled.
  ///
  /// In en, this message translates to:
  /// **'This time is in the future. Choose an earlier time.'**
  String get weighInFuture;

  /// Weigh-in sheet: the chosen time is before 1 January 1970 (A14 PA9).
  ///
  /// In en, this message translates to:
  /// **'Choose a date from 1970 on.'**
  String get weighInTooEarly;

  /// Weigh-in sheet: in-sheet confirmation for a change over 3% within 7 days (WB-005). Neutral, factual. diff is signed ("+3.0 kg"), when is "today", "yesterday" or a date.
  ///
  /// In en, this message translates to:
  /// **'That\'s {diff} from your weigh-in {when} ({weight}). Save it?'**
  String weighInConfirmChange(String diff, String when, String weight);

  /// Weigh-in sheet, large-change confirmation: the pinned primary button, saves the value as typed: "Save 100.0 kg" (WB-005).
  ///
  /// In en, this message translates to:
  /// **'Save {weight}'**
  String weighInConfirmSaveValue(String weight);

  /// Weigh-in sheet, large-change confirmation: the pinned text button that closes the confirmation and goes back to the number pad (WB-005).
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get weighInConfirmEdit;

  /// Weigh-in sheet: likely unit mix-up (WB-005): "Did you mean 214.0 lb (97.1 kg)?".
  ///
  /// In en, this message translates to:
  /// **'Did you mean {weight} ({converted})?'**
  String weighInConfirmUnit(String weight, String converted);

  /// Weigh-in sheet, unit confirmation: the pinned primary button, saves the number in the other unit: "Save as 214.0 lb".
  ///
  /// In en, this message translates to:
  /// **'Save as {weight}'**
  String weighInSaveAsUnit(String weight);

  /// Weigh-in sheet, unit confirmation: the pinned text button, saves the number in the unit it was typed in: "Keep kg".
  ///
  /// In en, this message translates to:
  /// **'Keep {unit}'**
  String weighInKeepUnit(String unit);

  /// Weigh-in sheet: another weigh-in on the chosen day (WB-003).
  ///
  /// In en, this message translates to:
  /// **'Also on this day: {weight} at {time}'**
  String weighInSameDay(String weight, String time);

  /// Weigh-in sheet: another weigh-in on the chosen day, the one the trend uses now (WB-003).
  ///
  /// In en, this message translates to:
  /// **'Also on this day: {weight} at {time} · used for the trend'**
  String weighInSameDayUsed(String weight, String time);

  /// Weigh-in sheet: switch that picks this weigh-in as the day's trend value (WB-003).
  ///
  /// In en, this message translates to:
  /// **'Use this weigh-in for the trend'**
  String get weighInUseForTrend;

  /// Snackbar after logging a weigh-in, with Undo (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Weigh-in saved: {weight}'**
  String weighInSaved(String weight);

  /// Snackbar after editing a weigh-in, with Undo (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Weigh-in updated: {weight}'**
  String weighInUpdated(String weight);

  /// Snackbar after deleting a weigh-in, with Undo (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Weigh-in deleted'**
  String get weighInDeleted;

  /// Snackbar after only the day's trend choice changed, with Undo (WB-003).
  ///
  /// In en, this message translates to:
  /// **'Trend weigh-in for the day changed'**
  String get weighInTrendChosen;

  /// Weigh-in sheet, edit mode: the weigh-in or its day changed elsewhere; nothing was saved. Shown with a Reload action.
  ///
  /// In en, this message translates to:
  /// **'This weigh-in changed since you opened it. Reload to see the latest. What you typed stays.'**
  String get weighInChanged;

  /// Weigh-in sheet: loads the weigh-in as it is now and keeps what was typed (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get weighInReload;

  /// Weigh-in sheet, logging: the day's other weigh-ins changed elsewhere, so the trend choice wasn't saved; nothing was saved and a retry works.
  ///
  /// In en, this message translates to:
  /// **'Other weigh-ins on this day changed. Check the trend choice and save again.'**
  String get weighInDayChanged;

  /// Weigh-in sheet: the weigh-in being edited no longer exists; nothing was saved.
  ///
  /// In en, this message translates to:
  /// **'This weigh-in was deleted.'**
  String get weighInRemoved;

  /// Weigh-in sheet: the save was refused; nothing was saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the weigh-in. Try again.'**
  String get weighInSaveFailed;

  /// Weigh-in sheet: the weigh-ins couldn't be read (the sheet can't prefill or check).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your weigh-ins.'**
  String get weighInLoadFailed;

  /// Weigh-in sheet: retries loading the weigh-ins.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get weighInTryAgain;

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

  /// Setup (UX-060): the screen title.
  ///
  /// In en, this message translates to:
  /// **'Set up your targets'**
  String get setupTitle;

  /// Setup: where the user is in the five pages (D9).
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String setupStep(int current, int total);

  /// Setup: tooltip and screen-reader label of the close button.
  ///
  /// In en, this message translates to:
  /// **'Close setup'**
  String get setupClose;

  /// Setup: goes to the previous page; what was typed is kept.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get setupBack;

  /// Setup: goes to the next page; off until the page's required fields are valid.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// Setup: saves the profile, goal, first weigh-in and targets (last page).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get setupSave;

  /// Setup page 1 title (TG-001).
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get setupPageYou;

  /// Setup page 2 title (TG-001).
  ///
  /// In en, this message translates to:
  /// **'How active are you?'**
  String get setupPageActivity;

  /// Setup page 3 title (TG-010/011).
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get setupPageGoal;

  /// Setup page 4 title (UX-060).
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get setupPagePreferences;

  /// Setup page 5 title: the calculated targets.
  ///
  /// In en, this message translates to:
  /// **'Your targets'**
  String get setupPageTargets;

  /// Setup page 1: under the current weight field (WB-001).
  ///
  /// In en, this message translates to:
  /// **'Saved as your first weigh-in.'**
  String get setupWeightHint;

  /// Setup page 2: under the title.
  ///
  /// In en, this message translates to:
  /// **'Pick the one closest to a usual week.'**
  String get setupActivityHint;

  /// Setup page 4: under the title.
  ///
  /// In en, this message translates to:
  /// **'These are filled in from your settings. You can change them here or later in Me.'**
  String get setupPreferencesHint;

  /// Setup page 5: the daily target, the big number.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal a day'**
  String setupTargetsDaily(int kcal);

  /// Setup page 5: the weekly budget, under the daily target.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal a week'**
  String setupTargetsWeekly(int kcal);

  /// Setup page 5: heading above the plain-language explanation (TG-021).
  ///
  /// In en, this message translates to:
  /// **'How it\'s calculated'**
  String get setupTargetsHow;

  /// Setup page 5: heading above the macro targets.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get setupTargetsMacros;

  /// Setup page 5: how the targets are applied by default.
  ///
  /// In en, this message translates to:
  /// **'Your weekly budget adjusts the rest of the week when a day is over or under. You can change this later in Me.'**
  String get setupTargetsMode;

  /// Setup: title of the sheet shown when closing with something typed (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Leave setup?'**
  String get setupLeaveTitle;

  /// Setup: message of the leave sheet.
  ///
  /// In en, this message translates to:
  /// **'What you entered won\'t be saved.'**
  String get setupLeaveMessage;

  /// Setup leave sheet: the dominant choice, back to setup.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get setupLeaveStay;

  /// Setup leave sheet: closes setup without saving.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get setupLeaveConfirm;

  /// Snackbar after setup was saved, with Undo (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Targets set'**
  String get setupSaved;

  /// Setup: Save refused because a profile or targets exist (perhaps from another device).
  ///
  /// In en, this message translates to:
  /// **'Your targets are already set up.'**
  String get setupAlreadySetUp;

  /// Setup: Save refused for another reason; nothing was written.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your targets. Nothing you entered was lost. Try Save again.'**
  String get setupSaveFailed;

  /// Setup (A13a security review #3): a profile saved by a newer app version can't be read here.
  ///
  /// In en, this message translates to:
  /// **'Update the app'**
  String get setupUpdateTitle;

  /// Setup: the message under 'Update the app'.
  ///
  /// In en, this message translates to:
  /// **'Your profile was saved by a newer version of Fitness Buddy. Update the app to see and change it.'**
  String get setupUpdateMessage;

  /// Profile form: label of the formula sex choice (TG-001).
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get profileSexLabel;

  /// Profile form: why sex is asked, under its label (TG-001, TG-020).
  ///
  /// In en, this message translates to:
  /// **'Used for the energy formula'**
  String get profileSexHint;

  /// Profile form: formula sex choice.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileSexMale;

  /// Profile form: formula sex choice.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileSexFemale;

  /// Profile form: label of the birth year field (TG-001).
  ///
  /// In en, this message translates to:
  /// **'Birth year'**
  String get profileBirthYearLabel;

  /// Profile form: the birth year gives an age outside 18 to 100. Years are shown without grouping.
  ///
  /// In en, this message translates to:
  /// **'Enter a year between {min} and {max}.'**
  String profileBirthYearRange(int min, int max);

  /// Profile form: label of the height field, and of its unit choice (TG-001).
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeightLabel;

  /// Profile form: unit choice chip, height in centimetres (TG-002).
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get profileHeightUnitCm;

  /// Profile form: unit choice chip, height in feet and inches (TG-002).
  ///
  /// In en, this message translates to:
  /// **'ft + in'**
  String get profileHeightUnitFtIn;

  /// Profile form: label of the feet part of an imperial height.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get profileHeightFeet;

  /// Profile form: label of the inches part of an imperial height.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get profileHeightInches;

  /// Profile form: unit after the height number.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get profileUnitCm;

  /// Profile form: unit after the feet number.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get profileUnitFt;

  /// Profile form: unit after the inches number.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get profileUnitIn;

  /// Profile form: the height is outside the accepted range.
  ///
  /// In en, this message translates to:
  /// **'Enter a height between {min} and {max} cm.'**
  String profileHeightRangeCm(int min, int max);

  /// Profile form: the imperial height is outside the accepted range, or the inches are 12 or more.
  ///
  /// In en, this message translates to:
  /// **'Enter a height between {minFeet} ft {minInches} in and {maxFeet} ft {maxInches} in. Inches go up to 11.'**
  String profileHeightRangeFtIn(
    int minFeet,
    int minInches,
    int maxFeet,
    int maxInches,
  );

  /// Profile form: label of the current weight field (TG-001). Saved as a weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get profileWeightLabel;

  /// Targets forms: a body or target weight outside the accepted range.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between {min} and {max} {unit}.'**
  String targetsWeightRange(double min, double max, String unit);

  /// Targets: a weight or a weight change with its unit, e.g. '0.46 kg' or '−2 lb' (the sign is part of the amount).
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String targetsMassValue(String amount, String unit);

  /// Targets forms: a number field is empty or isn't a number.
  ///
  /// In en, this message translates to:
  /// **'Enter a number.'**
  String get targetsEnterNumber;

  /// Activity choice (TG-001): the lowest of four levels.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting'**
  String get profileActivitySedentary;

  /// Activity choice: plain description of the lowest level.
  ///
  /// In en, this message translates to:
  /// **'Desk work, little walking and no regular exercise'**
  String get profileActivitySedentaryHint;

  /// Activity choice (TG-001): the second level.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get profileActivityLight;

  /// Activity choice: plain description of the second level.
  ///
  /// In en, this message translates to:
  /// **'On your feet part of the day, or light exercise 1 to 3 days a week'**
  String get profileActivityLightHint;

  /// Activity choice (TG-001): the third level.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get profileActivityModerate;

  /// Activity choice: plain description of the third level.
  ///
  /// In en, this message translates to:
  /// **'An active job, or exercise 3 to 5 days a week'**
  String get profileActivityModerateHint;

  /// Activity choice (TG-001): the highest level.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get profileActivityHigh;

  /// Activity choice: plain description of the highest level.
  ///
  /// In en, this message translates to:
  /// **'Hard exercise 6 or 7 days a week, or a physical job'**
  String get profileActivityHighHint;

  /// The lowest activity level inside a sentence, lower case (the target explanation).
  ///
  /// In en, this message translates to:
  /// **'mostly sitting'**
  String get profileActivityShortSedentary;

  /// The second activity level inside a sentence, lower case.
  ///
  /// In en, this message translates to:
  /// **'lightly active'**
  String get profileActivityShortLight;

  /// The third activity level inside a sentence, lower case.
  ///
  /// In en, this message translates to:
  /// **'moderately active'**
  String get profileActivityShortModerate;

  /// The highest activity level inside a sentence, lower case.
  ///
  /// In en, this message translates to:
  /// **'very active'**
  String get profileActivityShortHigh;

  /// Setup and the targets forms: under a choice (sex, activity, goal) left empty when Next was tapped (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Choose one to continue.'**
  String get targetsChooseOne;

  /// Goal form: label above the lose, maintain and gain choices (TG-010).
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get goalTypeTitle;

  /// Goal type (TG-010); also the default name of a lose phase.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalTypeLose;

  /// Goal type (TG-010); also the default name of a maintain phase.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get goalTypeMaintain;

  /// Goal type (TG-010); also the default name of a gain phase.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get goalTypeGain;

  /// Goal form: label above the four ways to express a lose or gain goal (TG-011).
  ///
  /// In en, this message translates to:
  /// **'How do you want to set it?'**
  String get goalHow;

  /// Goal expression: an amount each week.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get goalKindWeekly;

  /// Goal expression: an amount over this calendar month (the owner's style).
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get goalKindMonthly;

  /// Goal expression: a target weight and the date to reach it.
  ///
  /// In en, this message translates to:
  /// **'Target weight by a date'**
  String get goalKindTargetDate;

  /// Goal expression: a target weight and a weekly pace toward it.
  ///
  /// In en, this message translates to:
  /// **'Target weight at a pace'**
  String get goalKindTargetRate;

  /// Goal form: label of the weekly amount field for a lose goal.
  ///
  /// In en, this message translates to:
  /// **'Lose each week'**
  String get goalRateLoseLabel;

  /// Goal form: label of the weekly amount field for a gain goal.
  ///
  /// In en, this message translates to:
  /// **'Gain each week'**
  String get goalRateGainLabel;

  /// Goal form: label of the monthly amount field for a lose goal.
  ///
  /// In en, this message translates to:
  /// **'Lose this month'**
  String get goalMonthLoseLabel;

  /// Goal form: label of the monthly amount field for a gain goal.
  ///
  /// In en, this message translates to:
  /// **'Gain this month'**
  String get goalMonthGainLabel;

  /// Goal form: label of the target weight field.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get goalTargetWeightLabel;

  /// Goal form: label of the target date chip, followed by the date.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get goalTargetDateLabel;

  /// Goal form: the target date chip before a date is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get goalTargetDatePick;

  /// Goal form: no target date picked yet.
  ///
  /// In en, this message translates to:
  /// **'Pick a target date.'**
  String get goalTargetDateMissing;

  /// Goal form: the target date is more than 5 years ahead.
  ///
  /// In en, this message translates to:
  /// **'Pick a date within 5 years.'**
  String get goalTargetDateTooFar;

  /// Goal form: label of the weekly pace toward the target weight.
  ///
  /// In en, this message translates to:
  /// **'Pace each week'**
  String get goalPaceLabel;

  /// Goal form: the weekly amount or pace is 0 or above the accepted range.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount up to {max} {unit} a week.'**
  String goalRateRange(double max, String unit);

  /// Goal form: the monthly amount is 0 or above the accepted range.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount up to {max} {unit} this month.'**
  String goalMonthRange(double max, String unit);

  /// Goal form (TG-011): the planned weekly change and what it means over a calendar month, e.g. '≈ −0.46 kg a week · −2 kg in November'.
  ///
  /// In en, this message translates to:
  /// **'≈ {rate} a week · {change} in {month}'**
  String goalProjection(String rate, String change, String month);

  /// Goal form (TG-011): as goalProjection, with the projected month the target weight is reached, e.g. 'March 2027'.
  ///
  /// In en, this message translates to:
  /// **'≈ {rate} a week · {change} in {month} · goal reached around {date}'**
  String goalProjectionWithDate(
    String rate,
    String change,
    String month,
    String date,
  );

  /// Goal form: shown for a maintain goal instead of the projection.
  ///
  /// In en, this message translates to:
  /// **'Your target keeps your weight steady.'**
  String get goalMaintainNote;

  /// Goal form and target explanation (TG-013, SF-011): a requested loss above 1% of body weight a week was capped. Calm, no warning words.
  ///
  /// In en, this message translates to:
  /// **'You asked for {requested} a week. Plans stay within 1% of your weight a week, so this plan uses {planned}.'**
  String goalCapMessage(String requested, String planned);

  /// Goal form (PA3): the target date isn't after today, so no numbers can be shown.
  ///
  /// In en, this message translates to:
  /// **'Pick a date after today.'**
  String get goalProblemDeadline;

  /// Goal form (PA3): a lose goal whose target weight isn't below the current weight.
  ///
  /// In en, this message translates to:
  /// **'This target weight isn\'t below your current weight. Choose a lower target, or another goal.'**
  String get goalProblemTargetNotBelow;

  /// Goal form (PA3): a gain goal whose target weight isn't above the current weight.
  ///
  /// In en, this message translates to:
  /// **'This target weight isn\'t above your current weight. Choose a higher target, or another goal.'**
  String get goalProblemTargetNotAbove;

  /// Me (PA3): the saved goal's date has passed. Neutral line next to 'Start a new goal'.
  ///
  /// In en, this message translates to:
  /// **'Your goal date has passed.'**
  String get goalStoredDatePassed;

  /// Me (PA3): the saved goal's target weight is reached. Neutral line next to 'Start a new goal'.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your target weight.'**
  String get goalStoredTargetReached;

  /// Shown when saving a goal is refused because it can't be worked out from the current weight (PA3).
  ///
  /// In en, this message translates to:
  /// **'This goal doesn\'t fit your current weight. Check the target weight and date.'**
  String get goalFailedUnresolvable;

  /// Shown when a change is refused because the saved goal can't be worked out any more (PA3).
  ///
  /// In en, this message translates to:
  /// **'Your current goal needs an update. Start a new goal to recalculate.'**
  String get goalFailedNeedsUpdate;

  /// Target explanation (TG-021), line 1: Mifflin-St Jeor resting energy.
  ///
  /// In en, this message translates to:
  /// **'Resting energy: about {kcal} kcal a day (from your weight, height, age and sex).'**
  String targetsExplainResting(int kcal);

  /// Target explanation (TG-021), line 2: the activity factor and the estimated expenditure. {level} is the lower-case activity level.
  ///
  /// In en, this message translates to:
  /// **'Activity ({level}): × {factor} = about {kcal} kcal a day.'**
  String targetsExplainActivity(String level, double factor, int kcal);

  /// Target explanation (TG-021), line 3 for a lose goal: the planned rate and the daily adjustment.
  ///
  /// In en, this message translates to:
  /// **'Goal: lose {rate} a week = {kcal} kcal less a day (about {perUnit} kcal per {unit}).'**
  String targetsExplainGoalLose(
    String rate,
    int kcal,
    int perUnit,
    String unit,
  );

  /// Target explanation (TG-021), line 3 for a gain goal.
  ///
  /// In en, this message translates to:
  /// **'Goal: gain {rate} a week = {kcal} kcal more a day (about {perUnit} kcal per {unit}).'**
  String targetsExplainGoalGain(
    String rate,
    int kcal,
    int perUnit,
    String unit,
  );

  /// Target explanation (TG-021), line 3 for a maintain goal.
  ///
  /// In en, this message translates to:
  /// **'Goal: keep your weight steady, so nothing is added or taken away.'**
  String get targetsExplainGoalMaintain;

  /// Target explanation (SF-010): the calculated target was below the safety floor and was raised to it.
  ///
  /// In en, this message translates to:
  /// **'Raised to your safety floor of {kcal} kcal a day.'**
  String targetsExplainFloor(int kcal);

  /// Target explanation (TG-021), last line: the daily and weekly targets.
  ///
  /// In en, this message translates to:
  /// **'Your target: {daily} kcal a day, {weekly} kcal a week.'**
  String targetsExplainTarget(int daily, int weekly);

  /// Target explanation (TG-021), last line without a weekly budget.
  ///
  /// In en, this message translates to:
  /// **'Your target: {daily} kcal a day.'**
  String targetsExplainTargetDaily(int daily);

  /// Macro summary: a daily macro target in grams.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String targetsMacroGrams(int grams);

  /// Macro summary: carbs and fat in 'calories and protein only' mode (TG-054).
  ///
  /// In en, this message translates to:
  /// **'No target'**
  String get targetsMacroNoTarget;

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

  /// Me tab: the heading of the section with the profile and targets (A13).
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get meSectionYou;

  /// Me tab: the row that opens setup while no profile and targets exist (A13 D10).
  ///
  /// In en, this message translates to:
  /// **'Set up profile & targets'**
  String get meSetUpTargets;

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

  /// Weight graph screen title and the Today/Progress row that opens it.
  ///
  /// In en, this message translates to:
  /// **'Weight graph'**
  String get weightGraphTitle;

  /// Weight graph range chip: one month.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get weightGraphRange1M;

  /// Weight graph range chip: three months.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get weightGraphRange3M;

  /// Weight graph range chip: six months.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get weightGraphRange6M;

  /// Weight graph range chip: one year.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get weightGraphRange1Y;

  /// Weight graph range chip: the whole history.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get weightGraphRangeAll;

  /// Weight graph chip shown after panning: back to the window ending today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weightGraphToday;

  /// Screen-reader summary of the weight chart.
  ///
  /// In en, this message translates to:
  /// **'Weight graph, {count} weigh-ins. Trend {trend}.'**
  String weightGraphSemantics(String count, String trend);

  /// Label of the dashed goal-weight line on the chart.
  ///
  /// In en, this message translates to:
  /// **'Goal {weight}'**
  String weightGraphGoal(String weight);

  /// Hint under the weight chart when no point is selected.
  ///
  /// In en, this message translates to:
  /// **'Tap a point to see details'**
  String get weightGraphTapHint;

  /// Selected weigh-in details: the trend on its day.
  ///
  /// In en, this message translates to:
  /// **'Trend {weight} that day'**
  String weightGraphTrendThatDay(String weight);

  /// Selected weigh-in details: another weigh-in that day feeds the trend.
  ///
  /// In en, this message translates to:
  /// **'Not used for the trend'**
  String get weightGraphNotUsed;

  /// Button: make the selected weigh-in its day's trend value (undoable).
  ///
  /// In en, this message translates to:
  /// **'Use for trend'**
  String get weightGraphUseForTrend;

  /// Button: edit the selected weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get weightGraphEdit;

  /// Legend: the faint dots are the raw weigh-ins.
  ///
  /// In en, this message translates to:
  /// **'Weigh-ins'**
  String get weightGraphLegendRaw;

  /// Legend: the solid line is the trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get weightGraphLegendTrend;

  /// Legend: the dashed line and shaded cone. Never a probability.
  ///
  /// In en, this message translates to:
  /// **'Projection, likely range at the current rate'**
  String get weightGraphLegendProjection;

  /// Weight graph stats card title.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get weightGraphStatsTitle;

  /// Stats row label: trend change since the phase start or first weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Change since {date}'**
  String weightGraphChangeSince(String date);

  /// Stats row label: trend change this month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get weightGraphThisMonth;

  /// Stats row label: change this month when the phase started this month.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String weightGraphThisMonthSince(String date);

  /// Stats value: this month's change against its target.
  ///
  /// In en, this message translates to:
  /// **'{change} of {target}'**
  String weightGraphMonthValue(String change, String target);

  /// Stats row label: average weekly change.
  ///
  /// In en, this message translates to:
  /// **'Average since {date}'**
  String weightGraphAverageSince(String date);

  /// Stats value: an average weekly change.
  ///
  /// In en, this message translates to:
  /// **'{change} per week'**
  String weightGraphPerWeek(String change);

  /// Stats line: projected month the trend meets the goal. Neutral, not a promise.
  ///
  /// In en, this message translates to:
  /// **'Goal around {month} at your current trend'**
  String weightGraphGoalAround(String month);

  /// Stats value when a number isn't available yet.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get weightGraphNone;

  /// Stats reason: not enough history yet.
  ///
  /// In en, this message translates to:
  /// **'Shows after 2 weeks of weigh-ins'**
  String get weightGraphAfterTwoWeeks;

  /// Stats reason: no active goal rate.
  ///
  /// In en, this message translates to:
  /// **'Set a goal to see a monthly target'**
  String get weightGraphNoMonthTarget;

  /// Weight graph empty state title.
  ///
  /// In en, this message translates to:
  /// **'No weigh-ins yet'**
  String get weightGraphEmptyTitle;

  /// Weight graph empty state message.
  ///
  /// In en, this message translates to:
  /// **'Log a weigh-in and your graph starts here.'**
  String get weightGraphEmptyMessage;

  /// Weight graph empty state button.
  ///
  /// In en, this message translates to:
  /// **'Log weigh-in'**
  String get weightGraphLog;

  /// Weight graph error state.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your weight'**
  String get weightGraphError;

  /// Weight graph error retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get weightGraphTryAgain;

  /// Label of a highlighted Ramadan period on charts (A41 supplies the dates).
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get weightGraphRamadan;

  /// Stats reason: the active goal can't be resolved (deadline passed or target reached).
  ///
  /// In en, this message translates to:
  /// **'Update your goal to see a monthly target'**
  String get weightGraphGoalNeedsUpdate;

  /// Stats reason: the manual calorie target needs review, so no monthly weight target is shown.
  ///
  /// In en, this message translates to:
  /// **'Review your manual target to see a monthly target'**
  String get weightGraphManualNeedsReview;

  /// Snack bar: Use for trend was refused because the day's weigh-ins changed meanwhile (nothing was written).
  ///
  /// In en, this message translates to:
  /// **'That day\'s weigh-ins changed. Check the point and try again.'**
  String get weightGraphUseForTrendChanged;

  /// Snack bar: Use for trend was refused (nothing was written).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the trend weigh-in. Try again.'**
  String get weightGraphUseForTrendFailed;

  /// Weight history screen title (A15b D17): many old weigh-ins typed as rows.
  ///
  /// In en, this message translates to:
  /// **'Past weigh-ins'**
  String get weightHistoryTitle;

  /// Weight graph AppBar action tooltip and empty-state button that open the weight history screen.
  ///
  /// In en, this message translates to:
  /// **'Add past weigh-ins'**
  String get weightHistoryOpen;

  /// Weight history screen intro.
  ///
  /// In en, this message translates to:
  /// **'Add weigh-ins from before you started, one row per day. They\'re saved together and can be undone in one go.'**
  String get weightHistoryIntro;

  /// Weight history row: the date chip before a date is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get weightHistoryPickDate;

  /// Weight history row: label of the date chip.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get weightHistoryDate;

  /// Weight history row: label of the value field.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightHistoryValue;

  /// Weight history row: tooltip of the remove button.
  ///
  /// In en, this message translates to:
  /// **'Remove row'**
  String get weightHistoryRemoveRow;

  /// Weight history: adds a row dated a week after the last one.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get weightHistoryAddRow;

  /// Weight history: the pinned Save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get weightHistorySave;

  /// Weight history: how many rows Save will add.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to save yet} =1{1 weigh-in to save} other{{count} weigh-ins to save}}'**
  String weightHistoryToSave(int count);

  /// Weight history: why Save is off while a row is incomplete.
  ///
  /// In en, this message translates to:
  /// **'Every row needs a date and a weight'**
  String get weightHistoryIncomplete;

  /// Weight history row: the date is after today (Save is off).
  ///
  /// In en, this message translates to:
  /// **'That date is in the future'**
  String get weightHistoryFuture;

  /// Weight history row: a stored weigh-in that day has the same value. The row is left out until kept.
  ///
  /// In en, this message translates to:
  /// **'Already logged on this day'**
  String get weightHistoryDuplicate;

  /// Weight history row: an earlier row has the same day and value. Left out until kept.
  ///
  /// In en, this message translates to:
  /// **'Same as an earlier row'**
  String get weightHistoryDuplicateRow;

  /// Weight history row: the number reads like the other unit (WB-005), e.g. "Did you mean 214.0 lb?". Left out until kept or switched.
  ///
  /// In en, this message translates to:
  /// **'Did you mean {weight}?'**
  String weightHistoryOtherUnit(String weight);

  /// Weight history row: switch this row to the suggested unit, e.g. "Use lb".
  ///
  /// In en, this message translates to:
  /// **'Use {unit}'**
  String weightHistoryUseUnit(String unit);

  /// Weight history row: a jump of more than 3 % within a week (WB-005). Neutral, no judgement. Left out until kept.
  ///
  /// In en, this message translates to:
  /// **'{change} from {date}. Is that right?'**
  String weightHistoryLargeChange(String change, String date);

  /// Weight history row: keep a flagged row so it's saved.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get weightHistoryKeep;

  /// Weight history row: the flagged row will be saved.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get weightHistoryKept;

  /// Weight history row: info only, the row is still saved (WB-003).
  ///
  /// In en, this message translates to:
  /// **'You already have a different weigh-in that day. The earliest one of the day is used for the trend.'**
  String get weightHistorySameDay;

  /// Undo snack bar after saving the weight history (one undo for all rows).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 weigh-in added} other{{count} weigh-ins added}}'**
  String weightHistorySaved(int count);

  /// Weight history: the save was refused; nothing was written and the rows are kept (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Your rows are still here, try again.'**
  String get weightHistoryFailed;

  /// Weight history: the save was refused because a time is in the future.
  ///
  /// In en, this message translates to:
  /// **'A date is in the future. Check the rows and try again.'**
  String get weightHistoryFailedFuture;

  /// Weight history: sheet title when leaving with typed rows.
  ///
  /// In en, this message translates to:
  /// **'Discard these rows?'**
  String get weightHistoryDiscardTitle;

  /// Weight history: discard sheet message.
  ///
  /// In en, this message translates to:
  /// **'You\'ve typed weigh-ins that aren\'t saved yet.'**
  String get weightHistoryDiscardMessage;

  /// Weight history: discard sheet, stay (the dominant choice).
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get weightHistoryDiscardKeep;

  /// Weight history: discard sheet, leave without saving.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get weightHistoryDiscardConfirm;

  /// Weight history: the stored weigh-ins couldn't be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your weigh-ins'**
  String get weightHistoryError;

  /// Weight history: retry after a load error.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get weightHistoryTryAgain;

  /// Measurements screen title and the Progress row that opens it (A15b D18).
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurementsTitle;

  /// Built-in measurement type.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get measurementKindWaist;

  /// Built-in measurement type.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get measurementKindChest;

  /// Built-in measurement type.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get measurementKindHips;

  /// Built-in measurement type (one value; a custom type covers left/right).
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get measurementKindArm;

  /// Built-in measurement type.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get measurementKindThigh;

  /// Built-in measurement type.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get measurementKindNeck;

  /// Built-in measurement type: body fat percentage, entered by hand (WB-042). No health judgement.
  ///
  /// In en, this message translates to:
  /// **'Body fat'**
  String get measurementKindBodyFat;

  /// Length unit: centimetres.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get measurementUnitCm;

  /// Length unit: inches.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get measurementUnitIn;

  /// Body fat unit.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get measurementUnitPercent;

  /// A measurement with its unit, e.g. "92.0 cm", "18.4 %".
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String measurementValue(String value, String unit);

  /// A measurement type without entries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get measurementNoEntries;

  /// Latest entry of a type, e.g. "Latest 92.0 cm · Oct 17".
  ///
  /// In en, this message translates to:
  /// **'Latest {value} · {date}'**
  String measurementLatest(String value, String date);

  /// Change from the first entry, neutral, e.g. "−3.5 cm since Jan 3".
  ///
  /// In en, this message translates to:
  /// **'{change} since {date}'**
  String measurementChangeSince(String change, String date);

  /// Button: open the measurement form.
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get measurementAdd;

  /// Button: create a custom measurement type (a length).
  ///
  /// In en, this message translates to:
  /// **'Add custom measurement'**
  String get measurementAddCustom;

  /// Measurements empty state title.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet'**
  String get measurementEmptyTitle;

  /// Measurements empty state message.
  ///
  /// In en, this message translates to:
  /// **'Track your waist, other body measurements and body fat. Each one gets its own graph.'**
  String get measurementEmptyMessage;

  /// A measurement type's screen without entries.
  ///
  /// In en, this message translates to:
  /// **'Add your first entry to start this graph.'**
  String get measurementTypeEmpty;

  /// Measurements error state.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your measurements'**
  String get measurementError;

  /// Measurements error retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get measurementTryAgain;

  /// A measurement type's screen when the type no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This measurement was removed'**
  String get measurementRemoved;

  /// A measurement type's screen when the type no longer exists.
  ///
  /// In en, this message translates to:
  /// **'It was deleted, here or on another device.'**
  String get measurementRemovedMessage;

  /// Measurement sheet title (new entry).
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get measurementSheetTitle;

  /// Measurement sheet title (edit).
  ///
  /// In en, this message translates to:
  /// **'Edit measurement'**
  String get measurementEditTitle;

  /// Measurement sheet: the type chips' label for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get measurementTypeLabel;

  /// Measurement sheet: the value field label.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get measurementValueLabel;

  /// Measurement sheet: the date chip label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get measurementDate;

  /// Measurement sheet: Save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get measurementSave;

  /// Measurement sheet and entry row: delete the entry (undoable).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get measurementDelete;

  /// Measurement sheet: the value is outside the local range, e.g. "10.0 cm" and "300.0 cm".
  ///
  /// In en, this message translates to:
  /// **'Enter a value between {min} and {max}'**
  String measurementOutOfRange(String min, String max);

  /// Undo snack bar after logging, e.g. "Waist saved: 92.0 cm".
  ///
  /// In en, this message translates to:
  /// **'{name} saved: {value}'**
  String measurementSaved(String name, String value);

  /// Undo snack bar after editing an entry.
  ///
  /// In en, this message translates to:
  /// **'{name} updated: {value}'**
  String measurementUpdated(String name, String value);

  /// Undo snack bar after deleting an entry.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get measurementDeleted;

  /// Measurement save refused: the entry changed (nothing written).
  ///
  /// In en, this message translates to:
  /// **'This entry changed meanwhile. Close it and try again.'**
  String get measurementFailedChanged;

  /// Measurement save refused: the entry is gone.
  ///
  /// In en, this message translates to:
  /// **'This entry was removed.'**
  String get measurementFailedRemoved;

  /// Measurement save refused: the custom type is gone.
  ///
  /// In en, this message translates to:
  /// **'This measurement type was removed.'**
  String get measurementFailedType;

  /// Measurement save refused: the time is in the future.
  ///
  /// In en, this message translates to:
  /// **'That time is in the future.'**
  String get measurementFailedFuture;

  /// Measurement save refused for another reason (nothing written).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check the value and try again.'**
  String get measurementFailedInvalid;

  /// Measurement type screen: the entries list header.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get measurementEntries;

  /// Hint under a measurement chart when no point is selected.
  ///
  /// In en, this message translates to:
  /// **'Tap a point to see details'**
  String get measurementTapHint;

  /// Button: edit the selected entry.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get measurementEdit;

  /// Chart legend / screen-reader name of the entry dots.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get measurementLegendEntries;

  /// Chart legend / screen-reader name of the trend line.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get measurementLegendTrend;

  /// Measurement chart: why there is no trend line yet (WB-041).
  ///
  /// In en, this message translates to:
  /// **'A trend line shows from 5 entries'**
  String get measurementTrendHint;

  /// Screen-reader summary of a measurement chart.
  ///
  /// In en, this message translates to:
  /// **'{name} graph, {count} entries.'**
  String measurementGraphSemantics(String name, String count);

  /// Tooltip of a custom type's menu button.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get measurementMenu;

  /// Custom type menu: rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get measurementRenameType;

  /// Custom type menu: delete the type and its entries (asks first when it has entries; undoable).
  ///
  /// In en, this message translates to:
  /// **'Delete type'**
  String get measurementDeleteType;

  /// Sheet title before deleting a custom type with entries.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String measurementDeleteTypeTitle(String name);

  /// Sheet message before deleting a custom type with entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Its 1 entry is deleted too. You can undo this.} other{Its {count} entries are deleted too. You can undo this.}}'**
  String measurementDeleteTypeMessage(int count);

  /// Sheet button: delete the custom type and its entries.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get measurementDeleteTypeConfirm;

  /// Sheet button: keep the custom type (the dominant choice).
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get measurementDeleteTypeKeep;

  /// Undo snack bar after creating a custom type.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String measurementTypeCreated(String name);

  /// Undo snack bar after renaming a custom type.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String measurementTypeRenamed(String name);

  /// Undo snack bar after deleting a custom type.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String measurementTypeDeleted(String name);

  /// Custom type sheet title (create).
  ///
  /// In en, this message translates to:
  /// **'New measurement'**
  String get measurementCustomTitle;

  /// Custom type sheet title (rename).
  ///
  /// In en, this message translates to:
  /// **'Rename measurement'**
  String get measurementRenameTitle;

  /// Custom type sheet: the name field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get measurementCustomName;

  /// Custom type sheet: the name field hint.
  ///
  /// In en, this message translates to:
  /// **'For example: Left arm'**
  String get measurementCustomHint;

  /// Custom type sheet: what a custom type measures.
  ///
  /// In en, this message translates to:
  /// **'Custom measurements are lengths, in cm or in.'**
  String get measurementCustomNote;

  /// Custom type sheet: the name is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get measurementCustomEmpty;

  /// Custom type sheet: the name is too long.
  ///
  /// In en, this message translates to:
  /// **'Use 40 characters or fewer'**
  String get measurementCustomTooLong;

  /// Custom type sheet: the name has a control character.
  ///
  /// In en, this message translates to:
  /// **'Remove line breaks and control characters'**
  String get measurementCustomInvalid;

  /// Custom type sheet: another live type has this name (ignoring case).
  ///
  /// In en, this message translates to:
  /// **'You already have a measurement with this name'**
  String get measurementCustomDuplicate;

  /// Custom type sheet: the save was refused for another reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the name. Try again.'**
  String get measurementCustomFailed;

  /// Me, You section: opens Profile & goal (A13c D13).
  ///
  /// In en, this message translates to:
  /// **'Profile & goal'**
  String get meProfileGoal;

  /// Me, You section: opens Targets (A13c D14).
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get meTargets;

  /// Profile & goal screen title (A13c D13).
  ///
  /// In en, this message translates to:
  /// **'Profile & goal'**
  String get profileGoalTitle;

  /// Profile & goal: section header above sex, birth year, height, activity and current weight.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get profileSectionAbout;

  /// Profile & goal: the activity row title and its edit sheet title (TG-001).
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profileActivityLabel;

  /// Profile & goal: the current weight row (A14's trend); opens the weigh-in sheet (PA1).
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get profileCurrentWeight;

  /// Profile & goal: current weight row subtitle before any weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Log a weigh-in'**
  String get profileCurrentWeightNone;

  /// Undo snackbar after a profile edit (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// Undo snackbar after a profile edit that recomputed the calculated target (D5).
  ///
  /// In en, this message translates to:
  /// **'Profile updated. Target now {kcal} kcal a day.'**
  String profileUpdatedTarget(int kcal);

  /// Edit sheets in Profile & goal: the row changed elsewhere since the sheet opened; Reload keeps what was typed (UX-052).
  ///
  /// In en, this message translates to:
  /// **'This changed. Reload.'**
  String get targetsChangedReload;

  /// Edit sheets in Profile & goal: loads the row as it is now and keeps what was typed (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get targetsReload;

  /// Profile, goal and target sheets: the button that saves.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get targetsSave;

  /// Profile, goal and target sheets: the save failed (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save just now. Nothing you entered was lost. Try again.'**
  String get targetsSaveFailed;

  /// Profile & goal: section header of the current goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalSectionTitle;

  /// Profile & goal: when the current goal started.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String goalSince(String date);

  /// Profile & goal: no goal phase covers today.
  ///
  /// In en, this message translates to:
  /// **'No goal set for today.'**
  String get goalNoneToday;

  /// Profile & goal: edits the current goal (D13).
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEdit;

  /// Profile & goal: starts a new goal from today; the current one ends yesterday (TG-012).
  ///
  /// In en, this message translates to:
  /// **'Start a new goal'**
  String get goalStartNew;

  /// Goal sheet title when editing the current goal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEditTitle;

  /// Goal sheet title when starting a new goal; the current goal ends yesterday.
  ///
  /// In en, this message translates to:
  /// **'New goal from today'**
  String get goalStartTitle;

  /// Goal sheet: what starting a new goal does (TG-012).
  ///
  /// In en, this message translates to:
  /// **'Your current goal ends yesterday and moves to Past goals.'**
  String get goalStartNote;

  /// Undo snackbar after editing the goal (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Goal updated'**
  String get goalUpdated;

  /// Undo snackbar after a goal edit that recomputed the calculated target (D5).
  ///
  /// In en, this message translates to:
  /// **'Goal updated. Target now {kcal} kcal a day.'**
  String goalUpdatedTarget(int kcal);

  /// Undo snackbar after starting a new goal (UX-030).
  ///
  /// In en, this message translates to:
  /// **'New goal started'**
  String get goalStarted;

  /// Undo snackbar after starting a new goal that recomputed the calculated target (D5).
  ///
  /// In en, this message translates to:
  /// **'New goal started. Target now {kcal} kcal a day.'**
  String goalStartedTarget(int kcal);

  /// Profile & goal: section header of ended goals (TG-012).
  ///
  /// In en, this message translates to:
  /// **'Past goals'**
  String get goalPastTitle;

  /// Past goals: the dates of an ended goal, e.g. '3 Jan 2026 – 30 Apr 2026'.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String goalPastRange(String from, String to);

  /// Past goals: empty state (UX-050).
  ///
  /// In en, this message translates to:
  /// **'Goals you finish show up here.'**
  String get goalPastNone;

  /// Goal rows: opens the rename sheet (TG-012).
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get goalRename;

  /// Rename sheet title.
  ///
  /// In en, this message translates to:
  /// **'Rename goal'**
  String get goalRenameTitle;

  /// Rename sheet: the name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get goalNameLabel;

  /// Rename sheet: an empty name means the default label of the goal type.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use \"{label}\".'**
  String goalNameHint(String label);

  /// Rename sheet: the name is too long or has characters that can't be used.
  ///
  /// In en, this message translates to:
  /// **'Use up to 40 characters.'**
  String get goalNameRange;

  /// Undo snackbar after renaming a goal (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Goal renamed'**
  String get goalRenamed;

  /// Profile & goal: the stored height in centimetres.
  ///
  /// In en, this message translates to:
  /// **'{cm} cm'**
  String profileHeightValueCm(int cm);

  /// Profile & goal: the stored height in feet and inches.
  ///
  /// In en, this message translates to:
  /// **'{feet} ft {inches} in'**
  String profileHeightValueFtIn(int feet, int inches);

  /// Profile & goal and Targets before setup (UX-050).
  ///
  /// In en, this message translates to:
  /// **'Answer a few questions and the app works out your daily and weekly targets. It takes about 2 minutes.'**
  String get targetsNotSetUpMessage;

  /// Profile & goal and Targets: reading the stored rows failed (UX-052).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile and targets.'**
  String get targetsLoadFailed;

  /// Profile & goal and Targets: retries a failed read.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get targetsTryAgain;

  /// Me › Targets screen title (A13c D14).
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get targetsTitle;

  /// Targets: section header of today's target, the weekly budget and the planned days.
  ///
  /// In en, this message translates to:
  /// **'Today and this week'**
  String get targetsSectionWeek;

  /// Targets: today's target, the big number.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String targetsTodayKcal(int kcal);

  /// Targets: caption under today's target.
  ///
  /// In en, this message translates to:
  /// **'Your target today'**
  String get targetsTodayCaption;

  /// Targets: the week's calorie budget (TG-040).
  ///
  /// In en, this message translates to:
  /// **'Weekly budget: {kcal} kcal'**
  String targetsWeeklyBudget(int kcal);

  /// Targets: a day's planned target in the week list.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String targetsPlannedDay(int kcal);

  /// Targets (TG-042, D7): rebalancing can't absorb the whole difference; neutral.
  ///
  /// In en, this message translates to:
  /// **'The rest of this week is already at its limit (25% above or below your usual target), so not all of the difference can be spread out.'**
  String get targetsCarryNote;

  /// Targets: section header of the plain-language explanation (TG-021).
  ///
  /// In en, this message translates to:
  /// **'How it\'s calculated'**
  String get targetsSectionHow;

  /// Targets: the explanation of a manual target (TG-021).
  ///
  /// In en, this message translates to:
  /// **'You set this yourself: {manual} kcal a day. The calculated target is {calculated} kcal a day.'**
  String targetsManualNote(int manual, int calculated);

  /// Targets (SF-012, manualNeedsReview): a manual target below a risen floor; neutral.
  ///
  /// In en, this message translates to:
  /// **'Your own target is below your safety floor now, so the floor of {floor} kcal is used. Set a new target or use the calculated one.'**
  String targetsManualNeedsReview(int floor);

  /// Targets (PA3, goalNeedsUpdate): the goal can't be resolved any more; neutral.
  ///
  /// In en, this message translates to:
  /// **'Your goal needs an update. Your targets stay as they are until then.'**
  String get targetsGoalNeedsUpdate;

  /// Targets: opens Profile & goal to start a new goal (PA3).
  ///
  /// In en, this message translates to:
  /// **'Update goal'**
  String get targetsGoalUpdateAction;

  /// Targets (D5): writes a new calculated target from the current weight trend.
  ///
  /// In en, this message translates to:
  /// **'Recalculate with your current weight'**
  String get targetsRecalculate;

  /// Targets (D5): why Recalculate is offered.
  ///
  /// In en, this message translates to:
  /// **'Your target was worked out at {basis}. Your current weight is {current}.'**
  String targetsRecalculateHint(String basis, String current);

  /// Undo snackbar after a target settings change (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Targets updated'**
  String get targetsUpdated;

  /// Targets: section header of the mode, rebalancing and higher-calorie days (TG-041–044).
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get targetsSectionBudget;

  /// Targets: mode option, the week's total counts (TG-041).
  ///
  /// In en, this message translates to:
  /// **'Weekly budget'**
  String get targetsModeWeekly;

  /// Targets: weekly budget option subtitle.
  ///
  /// In en, this message translates to:
  /// **'Days can go up or down; the week\'s total is what counts.'**
  String get targetsModeWeeklyHint;

  /// Targets: mode option, a fixed daily target (TG-044).
  ///
  /// In en, this message translates to:
  /// **'Same every day'**
  String get targetsModeFixed;

  /// Targets: fixed option subtitle.
  ///
  /// In en, this message translates to:
  /// **'One target for every day, no weekly budget.'**
  String get targetsModeFixedHint;

  /// Targets: switch, spreads a day's difference over the rest of the week (TG-042).
  ///
  /// In en, this message translates to:
  /// **'Rebalancing'**
  String get targetsRebalancing;

  /// Targets: rebalancing switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Spreads what you ate over or under across the rest of the week.'**
  String get targetsRebalancingHint;

  /// Targets (PA7, SF-012): why mode, rebalancing and higher-calorie days are off for an acknowledged below-floor target.
  ///
  /// In en, this message translates to:
  /// **'Below the safety floor the same target applies every day and weekly rebalancing is off.'**
  String get targetsForcedFixedNote;

  /// Targets: row and sheet title, weekdays with a higher share of the weekly budget (TG-043).
  ///
  /// In en, this message translates to:
  /// **'Higher-calorie days'**
  String get targetsShifting;

  /// Targets: no higher-calorie days.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get targetsShiftingNone;

  /// Shifting sheet: what a higher-calorie day does (TG-043).
  ///
  /// In en, this message translates to:
  /// **'The weekly total stays the same: the other days get a little less.'**
  String get targetsShiftingHint;

  /// Shifting sheet: a day without a shift.
  ///
  /// In en, this message translates to:
  /// **'Usual'**
  String get targetsShiftNormal;

  /// Shifting sheet: a day 15% above the others.
  ///
  /// In en, this message translates to:
  /// **'A little more'**
  String get targetsShiftLittle;

  /// Shifting sheet: a day 30% above the others.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get targetsShiftMore;

  /// Shifting sheet: a weekday and its planned target with this choice.
  ///
  /// In en, this message translates to:
  /// **'{day}: {kcal} kcal'**
  String targetsShiftDayPlanned(String day, int kcal);

  /// Targets: section header of the macro settings (TG-054).
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get targetsSectionMacros;

  /// Targets: row that opens the macro settings sheet (TG-054).
  ///
  /// In en, this message translates to:
  /// **'Macro targets'**
  String get targetsMacroSettings;

  /// Targets: the macro settings are the defaults.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get targetsMacroSettingsDefault;

  /// Targets: some macro settings were changed.
  ///
  /// In en, this message translates to:
  /// **'Your own settings'**
  String get targetsMacroSettingsCustom;

  /// Macro sheet: protein row.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get targetsMacroProtein;

  /// Macro sheet: fat row.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get targetsMacroFat;

  /// Macro sheet: carbs row.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get targetsMacroCarbs;

  /// Macro sheet: fiber row.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get targetsMacroFiber;

  /// Macro sheet: use the app's default for this macro.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get targetsMacroDefault;

  /// Macro sheet: a fixed amount in grams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get targetsMacroGramsChoice;

  /// Macro sheet: a share of the calorie target.
  ///
  /// In en, this message translates to:
  /// **'% of calories'**
  String get targetsMacroPercentChoice;

  /// Macro sheet: grams unit after the number.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get targetsMacroGramsUnit;

  /// Macro sheet: percent unit after the number.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get targetsMacroPercentUnit;

  /// Macro sheet: grams out of range.
  ///
  /// In en, this message translates to:
  /// **'Enter 0 to {max} g.'**
  String targetsMacroGramsRange(int max);

  /// Macro sheet: percent out of range.
  ///
  /// In en, this message translates to:
  /// **'Enter 0 to 100%.'**
  String get targetsMacroPercentRange;

  /// Macro sheet: switch, no carb and fat targets (TG-054).
  ///
  /// In en, this message translates to:
  /// **'Calories and protein only'**
  String get targetsMacroProteinOnly;

  /// Macro sheet: calories and protein only subtitle.
  ///
  /// In en, this message translates to:
  /// **'Carbs and fat are shown without a target.'**
  String get targetsMacroProteinOnlyHint;

  /// Targets: neutral note when macro energy is more than 50 kcal above the calorie target (TG-054).
  ///
  /// In en, this message translates to:
  /// **'Your macros add up to about {kcal} kcal more than your calorie target.'**
  String targetsMacroEnergyAbove(int kcal);

  /// Targets: neutral note when macro energy is more than 50 kcal below the calorie target (TG-054).
  ///
  /// In en, this message translates to:
  /// **'Your macros add up to about {kcal} kcal less than your calorie target.'**
  String targetsMacroEnergyBelow(int kcal);

  /// Targets: a settings change was refused because the targets changed meanwhile (UX-052).
  ///
  /// In en, this message translates to:
  /// **'This changed. Check it and try again.'**
  String get targetsChangedTryAgain;

  /// Targets: section header of the manual target (SF-012).
  ///
  /// In en, this message translates to:
  /// **'Your own target'**
  String get targetsSectionOwn;

  /// Targets: opens the manual target sheet (SF-012).
  ///
  /// In en, this message translates to:
  /// **'Set my own target'**
  String get targetsSetOwn;

  /// Targets: subtitle of 'Set my own target'.
  ///
  /// In en, this message translates to:
  /// **'Use a daily number you choose instead of the calculated one.'**
  String get targetsSetOwnHint;

  /// Targets: back to the calculated target from a manual one (TG-021).
  ///
  /// In en, this message translates to:
  /// **'Use the calculated target'**
  String get targetsUseCalculated;

  /// Manual target sheet: the number field.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get targetsManualLabel;

  /// Manual target sheet: unit after the number.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get targetsManualUnit;

  /// Manual target sheet: out of range (D15).
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 500 to 10,000.'**
  String get targetsManualRange;

  /// Manual target sheet: applies the number.
  ///
  /// In en, this message translates to:
  /// **'Use this target'**
  String get targetsManualApply;

  /// Warning screen title (SF-012); calm, no alarm.
  ///
  /// In en, this message translates to:
  /// **'Before you use this target'**
  String get targetsWarningTitle;

  /// Warning screen (SF-012, D16): a manual target below the floor. No moral words.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal a day is below your safety floor of {floor} kcal (your estimated resting energy). The app never suggests a target this low. Eating this little for a long time can leave you tired and make it harder to keep going. If you\'re unsure, talk to a health professional.'**
  String targetsWarningFloor(int kcal, int floor);

  /// Warning screen (SF-011, D16): a manual target implying loss above 1% of body weight a week.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal a day means losing about {rate} a week, more than 1% of your weight. Plans the app makes stay within 1% a week. Losing faster for a long time can leave you tired and make it harder to keep going.'**
  String targetsWarningRate(int kcal, String rate);

  /// Warning screen (SF-012, D16): what applying a below-floor target changes.
  ///
  /// In en, this message translates to:
  /// **'Below the floor the same target applies every day and weekly rebalancing is off.'**
  String get targetsWarningFixed;

  /// Warning screen: the acknowledgement checkbox (SF-012).
  ///
  /// In en, this message translates to:
  /// **'I understand and want to use {kcal} kcal a day'**
  String targetsWarningAcknowledge(int kcal);

  /// Warning screen: primary, disabled until the box is checked (SF-012).
  ///
  /// In en, this message translates to:
  /// **'Use {kcal} kcal'**
  String targetsWarningUse(int kcal);

  /// Warning screen: leaves without changing anything.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get targetsWarningBack;

  /// Goal sheet when editing (D13): editing rewrites the current phase from its start; a new phase starts today.
  ///
  /// In en, this message translates to:
  /// **'This changes your current goal, which started on {date}. To begin a new goal from today instead, use Start a new goal.'**
  String goalEditNote(String date);

  /// Me tab: Account section header (A33).
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get meSectionAccount;

  /// Me › Account: guest status line (AC-002).
  ///
  /// In en, this message translates to:
  /// **'You\'re using Fitness Buddy as a guest. Your data stays on this phone.'**
  String get accountGuest;

  /// Me › Account: signed-in status line. No email or id is shown.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get accountSignedIn;

  /// Me › Account and banner: registered session expired (A33 D9).
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign in again to keep your account.'**
  String get accountSessionExpired;

  /// Me › Account: kept copy after sign-out (AC-004).
  ///
  /// In en, this message translates to:
  /// **'This is a read-only copy. Sign in to edit.'**
  String get accountReadOnly;

  /// Me › Account: row that opens sign-in. Also the sign-in screen title.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account'**
  String get accountSignIn;

  /// Action on the session-expired banner/row.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get accountSignInAgain;

  /// Me › Account: sign-out row and sheet title.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// Sign-out sheet option: keep a read-only copy (AC-004).
  ///
  /// In en, this message translates to:
  /// **'Keep a copy on this phone'**
  String get accountSignOutKeep;

  /// Sign-out sheet option subtitle for keep.
  ///
  /// In en, this message translates to:
  /// **'You can see it but not edit it until you sign in.'**
  String get accountSignOutKeepDetail;

  /// Sign-out sheet option: wipe local data (AC-004).
  ///
  /// In en, this message translates to:
  /// **'Remove from this phone'**
  String get accountSignOutRemove;

  /// Sign-out sheet option subtitle for remove.
  ///
  /// In en, this message translates to:
  /// **'Your account data stays safe on the server.'**
  String get accountSignOutRemoveDetail;

  /// Me › Account: leave the read-only copy and use a guest profile.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get accountContinueAsGuest;

  /// Me › Account: placeholder row until A34.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get accountSyncPlaceholder;

  /// Me › Account: placeholder row until A35.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeletePlaceholder;

  /// Subtitle for placeholder rows.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get accountComingSoon;

  /// Sign-in screen: email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signInEmailLabel;

  /// Sign-in screen: button that emails a 6-digit code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get signInSendCode;

  /// Sign-in screen: code field label.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get signInCodeLabel;

  /// Sign-in screen: verify code button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get signInVerify;

  /// Sign-in screen: Google button (hidden until configured).
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInGoogle;

  /// Sign-in: 409 identity conflict title (AC-003).
  ///
  /// In en, this message translates to:
  /// **'This account already exists'**
  String get signInConflictTitle;

  /// Sign-in: conflict question.
  ///
  /// In en, this message translates to:
  /// **'What should happen to the data on this phone?'**
  String get signInConflictBody;

  /// Sign-in conflict option: merge this device's data into the account.
  ///
  /// In en, this message translates to:
  /// **'Add it to my account'**
  String get signInMerge;

  /// Sign-in conflict option: delete this device's guest data.
  ///
  /// In en, this message translates to:
  /// **'Discard it'**
  String get signInDiscard;

  /// Sign-in: success line.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in'**
  String get signInDone;

  /// Sign-in failure: offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Try again when you\'re connected.'**
  String get signInErrorOffline;

  /// Sign-in failure: wrong/expired code.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work. Check it or send a new one.'**
  String get signInErrorCode;

  /// Sign-in failure: rate limited.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a moment and try again.'**
  String get signInErrorThrottled;

  /// Sign-in failure: other.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Try again.'**
  String get signInErrorOther;

  /// Sign-in conflict: merge refused because a kept copy of the account exists on the device (A33 review 7). Both copies stay.
  ///
  /// In en, this message translates to:
  /// **'This account already has a copy on this phone, so the two can\'t be combined yet. Your guest data stays here. You can discard it to open your account, or go back.'**
  String get signInMergeBlocked;

  /// Sign-in success: closes the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get signInDoneButton;

  /// Today: the gentle guest prompt (AC-002), at most once a week after the first week.
  ///
  /// In en, this message translates to:
  /// **'You\'re using Fitness Buddy as a guest. Create a free account and everything you\'ve logged comes with you.'**
  String get guestPromptBody;

  /// Guest prompt: opens sign-in.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get guestPromptCreate;

  /// Guest prompt: dismisses the card.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get guestPromptNotNow;

  /// Full-screen calm state while sign-in, sign-out or the recovery of an interrupted one switches local profiles (A33). Usually under a second.
  ///
  /// In en, this message translates to:
  /// **'Updating your account…'**
  String get accountTransitionBusy;
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
