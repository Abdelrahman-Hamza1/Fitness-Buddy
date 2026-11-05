import 'package:material_ui/material_ui.dart';

/// A clock time in the device's 12 or 24 hour format (A57 A74): the one
/// way the app writes a time of day, so a reminder, a weigh-in and a log
/// time read alike.
String deviceTimeFormat(BuildContext context, TimeOfDay time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
