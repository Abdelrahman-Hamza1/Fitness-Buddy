import 'package:material_ui/material_ui.dart';

/// Shows the time picker dialog (D18), themed by the app theme. Resolves to
/// the picked time of day or null when dismissed.
///
/// The dialog opens on the dial; whether it shows a 12 or 24 hour clock
/// follows the device setting. Its words ("Select time", "OK", "Cancel", AM
/// and PM) come from the app's Material localizations.
Future<TimeOfDay?> showFbTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) => showTimePicker(context: context, initialTime: initialTime);
