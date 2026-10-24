import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// "Today", "Yesterday", else the weekday and date ("Fri, Oct 17"; with the
/// year for another year). The one wording of a day, shared by the Today
/// header and the copy messages (A08).
String dayLabel(BuildContext context, LocalDate date, LocalDate today) {
  final l10n = context.l10n;
  if (date == today) return l10n.diaryDateToday;
  if (date == today.plusDays(-1)) return l10n.diaryDateYesterday;
  final locale = Localizations.localeOf(context).toString();
  final format = date.year == today.year
      ? DateFormat.MMMEd(locale)
      : DateFormat.yMMMEd(locale);
  return format.format(DateTime(date.year, date.month, date.day));
}

/// Like [dayLabel] but for use inside a sentence: "today" and "yesterday" in
/// lower case; a date stays as it is ("Fri, Oct 17").
String dayLabelInline(BuildContext context, LocalDate date, LocalDate today) {
  final l10n = context.l10n;
  if (date == today) return l10n.diaryDateTodayInline;
  if (date == today.plusDays(-1)) return l10n.diaryDateYesterdayInline;
  return dayLabel(context, date, today);
}

/// Adds the day to a snackbar [message] when it isn't today: "{message} for
/// yesterday". One ARB string, so a translation can reorder the parts.
String withDayClause(
  BuildContext context,
  String message,
  LocalDate date,
  LocalDate today,
) => date == today
    ? message
    : context.l10n.quickAddLoggedOn(
        message,
        dayLabelInline(context, date, today),
      );
