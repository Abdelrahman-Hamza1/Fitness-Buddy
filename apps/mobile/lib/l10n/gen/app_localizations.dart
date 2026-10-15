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
  /// **'Your day\'s meals and totals will show up here.'**
  String get todayPlaceholder;

  /// Placeholder body of the Progress tab until charts are built.
  ///
  /// In en, this message translates to:
  /// **'Your weight trend and weekly summaries will show up here.'**
  String get progressPlaceholder;

  /// Placeholder body of the Workouts tab until workouts are built.
  ///
  /// In en, this message translates to:
  /// **'Your workout plan and history will show up here.'**
  String get workoutsPlaceholder;

  /// Placeholder body of the Me tab until profile and settings are built.
  ///
  /// In en, this message translates to:
  /// **'Your profile, goals and settings will show up here.'**
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
