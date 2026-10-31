import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

// The Ramadan feature's words for dates, times and methods (A41a).

/// "Wed, Feb 18" in the device's locale.
String ramadanDateText(BuildContext context, LocalDate date) =>
    DateFormat.MMMEd(context.l10n.localeName)
        .format(DateTime(date.year, date.month, date.day));

/// A clock time for minute-of-day [minute], in the device's format.
String ramadanTimeText(BuildContext context, int minute) =>
    DateFormat.jm(context.l10n.localeName)
        .format(DateTime(2000, 1, 1, minute ~/ 60, minute % 60));

/// The name of a prayer-time calculation method.
String prayerMethodName(AppLocalizations l10n, PrayerMethod method) =>
    switch (method) {
      PrayerMethod.muslimWorldLeague => l10n.prayerMethodMwl,
      PrayerMethod.egypt => l10n.prayerMethodEgypt,
      PrayerMethod.jordan => l10n.prayerMethodJordan,
      PrayerMethod.ummAlQura => l10n.prayerMethodUmmAlQura,
      PrayerMethod.northAmerica => l10n.prayerMethodIsna,
    };
