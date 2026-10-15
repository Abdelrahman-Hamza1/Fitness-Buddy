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
      'Your day\'s meals and totals will show up here.';

  @override
  String get progressPlaceholder =>
      'Your weight trend and weekly summaries will show up here.';

  @override
  String get workoutsPlaceholder =>
      'Your workout plan and history will show up here.';

  @override
  String get mePlaceholder =>
      'Your profile, goals and settings will show up here.';

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
}
