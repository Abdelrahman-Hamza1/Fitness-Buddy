import 'package:fb_domain/src/notifications/notification_planner.dart';
import 'package:fb_domain/src/notifications/notification_prefs.dart';
import 'package:fb_domain/src/ramadan/ramadan_calendar.dart';
import 'package:fb_domain/src/time/clock.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// A fasting day's Fajr and Maghrib as instants (UTC), with their dates.
typedef FajrMaghrib = ({DateTime fajrUtc, DateTime maghribUtc});

/// The suhoor and iftar reminders (NT-008, NT-009, NT-026, A41a D10): the
/// planner's `extra` candidates for the fasting days of the horizon. Pure:
/// the app passes the calendar, the not-fasting days and each day's prayer
/// times (the chosen city's, LC-033).
abstract final class RamadanReminders {
  /// The suhoor reminder fires this long before Fajr (`spec/17` NT-008).
  static const int suhoorLeadMinutes = 45;

  /// The iftar log nudge fires this long after Maghrib (NT-009).
  static const int iftarDelayMinutes = 90;

  /// One suhoor and one iftar candidate per fasting day around [today]
  /// (the planner's horizon and a day either side): in a Ramadan whose
  /// mode is on, not marked not fasting (LC-034), with prayer times known
  /// ([prayer] returns null without a city: no reminder rather than a
  /// wrong time). Suhoor may fire
  /// in quiet hours (NT-021); both are outside the daily cap (NT-022).
  ///
  /// Each reminder keeps its exact instant (`atUtc`, A41a fix round 1): the
  /// lead or delay is added to the dated prayer instant, then [clock]'s
  /// zone gives the device-local date and minute, so a time past midnight
  /// (or a city in another zone) lands on the right day, and a DST change
  /// in between never moves it.
  static List<NotificationCandidate> candidates({
    required RamadanCalendar calendar,
    required LocalDate today,
    required FajrMaghrib? Function(LocalDate date) prayer,
    required Clock clock,
  }) {
    final out = <NotificationCandidate>[];
    NotificationCandidate at(
      NotificationType type,
      DateTime utc, {
      bool quiet = false,
    }) {
      final local = EntryTime.at(utc, clock).localDateTime;
      return NotificationCandidate(
        type: type,
        date: local.date,
        minute: local.minuteOfDay,
        atUtc: utc,
        capExempt: true,
        quietHoursExempt: quiet,
      );
    }

    // The fasting days are the city's dates, the horizon the device's
    // days: a reminder of the day before [today] (an iftar nudge past the
    // device's midnight) or after the last day (a suhoor the evening
    // before) can fall inside it. The planner keeps those in the horizon
    // and still ahead (A41a fix round 2).
    for (var i = -1; i <= NotificationPlanner.horizonDays; i++) {
      final date = today.plusDays(i);
      if (!calendar.isFastingDay(date)) continue;
      final times = prayer(date);
      if (times == null) continue;
      out
        ..add(
          at(
            NotificationType.suhoor,
            times.fajrUtc.subtract(const Duration(minutes: suhoorLeadMinutes)),
            quiet: true,
          ),
        )
        ..add(
          at(
            NotificationType.iftar,
            times.maghribUtc.add(const Duration(minutes: iftarDelayMinutes)),
          ),
        );
    }
    return out;
  }
}
