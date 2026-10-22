import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'fb_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FbLocalizations
/// returned by `FbLocalizations.of(context)`.
///
/// Applications need to include `FbLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/fb_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FbLocalizations.localizationsDelegates,
///   supportedLocales: FbLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the FbLocalizations.supportedLocales
/// property.
abstract class FbLocalizations {
  FbLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FbLocalizations of(BuildContext context) {
    return Localizations.of<FbLocalizations>(context, FbLocalizations)!;
  }

  static const LocalizationsDelegate<FbLocalizations> delegate =
      _FbLocalizationsDelegate();

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

  /// Action on the undo snackbar (UX-030).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get fbUndo;

  /// Confirms the number pad.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fbDone;

  /// Marks the answer chip that is assumed when the user does not pick one (AI-034).
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get fbAnswerDefault;

  /// Letter in the badge for values that are yours (your label scans, your edits).
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get fbSourceBadgeYours;

  /// Letter in the badge for values from the food database.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get fbSourceBadgeDatabase;

  /// Letter in the badge for values from a reference dish.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get fbSourceBadgeReference;

  /// Mark for estimated values.
  ///
  /// In en, this message translates to:
  /// **'~'**
  String get fbSourceBadgeEstimate;

  /// No description provided for @fbSourceLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Where numbers come from'**
  String get fbSourceLegendTitle;

  /// No description provided for @fbSourceYoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get fbSourceYoursTitle;

  /// No description provided for @fbSourceYoursBody.
  ///
  /// In en, this message translates to:
  /// **'Numbers you entered or scanned from a label.'**
  String get fbSourceYoursBody;

  /// No description provided for @fbSourceDatabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Food database'**
  String get fbSourceDatabaseTitle;

  /// No description provided for @fbSourceDatabaseBody.
  ///
  /// In en, this message translates to:
  /// **'Looked up in the food database, scaled to your portion.'**
  String get fbSourceDatabaseBody;

  /// No description provided for @fbSourceReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference dish'**
  String get fbSourceReferenceTitle;

  /// No description provided for @fbSourceReferenceBody.
  ///
  /// In en, this message translates to:
  /// **'Typical numbers for a dish, scaled to your portion.'**
  String get fbSourceReferenceBody;

  /// No description provided for @fbSourceEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get fbSourceEstimateTitle;

  /// No description provided for @fbSourceEstimateBody.
  ///
  /// In en, this message translates to:
  /// **'A rough guess. The real value could be higher or lower.'**
  String get fbSourceEstimateBody;

  /// No description provided for @fbEstimateRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get fbEstimateRangeTitle;

  /// No description provided for @fbEstimateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Likely range'**
  String get fbEstimateRangeLabel;

  /// No description provided for @fbEstimateReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Why it is an estimate'**
  String get fbEstimateReasonLabel;

  /// No description provided for @fbNumberPadBackspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get fbNumberPadBackspace;

  /// No description provided for @fbNumberPadDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal point'**
  String get fbNumberPadDecimal;

  /// No description provided for @fbInputCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get fbInputCamera;

  /// No description provided for @fbInputBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode'**
  String get fbInputBarcode;

  /// Tooltip and screen-reader label of the button that empties a search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get fbSearchClear;

  /// No description provided for @fbDatePrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get fbDatePrevious;

  /// No description provided for @fbDateNext.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get fbDateNext;

  /// No description provided for @fbChartPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Chart coming soon'**
  String get fbChartPlaceholder;

  /// No description provided for @fbSheetDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Drag handle'**
  String get fbSheetDragHandle;

  /// No description provided for @fbLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get fbLoading;
}

class _FbLocalizationsDelegate extends LocalizationsDelegate<FbLocalizations> {
  const _FbLocalizationsDelegate();

  @override
  Future<FbLocalizations> load(Locale locale) {
    return SynchronousFuture<FbLocalizations>(lookupFbLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_FbLocalizationsDelegate old) => false;
}

FbLocalizations lookupFbLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return FbLocalizationsEn();
  }

  throw FlutterError(
    'FbLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
