import 'package:material_ui/material_ui.dart';

/// Shows the date picker dialog (HM-009), themed by the app theme. No day
/// after [lastDate] can be picked (future days are not loggable, DY-003);
/// callers pass today as [lastDate]. Resolves to the picked day (at local
/// midnight) or null when dismissed.
///
/// The dialog's own words ("Select date", "OK", "Cancel", month names) come
/// from the app's Material localizations.
Future<DateTime?> showFbDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime lastDate,
  DateTime? firstDate,
}) => showDatePicker(
  context: context,
  initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
  firstDate: firstDate ?? DateTime(2000),
  lastDate: lastDate,
  initialEntryMode: DatePickerEntryMode.calendarOnly,
);
