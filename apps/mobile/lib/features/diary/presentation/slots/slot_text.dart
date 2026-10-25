import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart'
    show timeText;
import 'package:flutter/widgets.dart';

// Words for the Meal times screen and its sheets: a window as clock times in
// the device's format, and the counts of a meal's items and days.

/// A clock time of day for minute-of-day [minute].
String minuteText(BuildContext context, int minute) =>
    timeText(context, minute ~/ 60, minute % 60);

/// "4:00 AM – 11:00 AM", "10:00 PM – 2:00 AM, overnight" or "Any time".
String windowText(BuildContext context, TimeWindow? window) {
  final l10n = context.l10n;
  if (window == null) return l10n.mealTimesAnyTime;
  final start = minuteText(context, window.startMin);
  final end = minuteText(context, window.endMin);
  return window.wraps
      ? l10n.mealTimesWindowOvernight(start, end)
      : l10n.mealTimesWindow(start, end);
}

/// The window a meal gets when "Set times" is first switched on: from the
/// start of the current hour for two hours (past midnight is fine), so the
/// meal covers the time it is being set up at.
TimeWindow windowAround(LocalTime now) {
  final start = now.hour * 60;
  return TimeWindow(start, (start + 120) % LocalTime.minutesPerDay);
}
