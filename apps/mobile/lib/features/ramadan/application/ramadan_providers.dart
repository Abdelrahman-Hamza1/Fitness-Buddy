import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/ramadan/application/city_zone.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ramadan_providers.g.dart';

/// The user's Ramadan decisions (LC-030/031, A41a D3).
@riverpod
Stream<RamadanSettings> ramadanSettings(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.ramadanSeasons);

/// How prayer times are computed (LC-033, A41a D2).
@riverpod
Stream<PrayerMethod> prayerMethod(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.prayerMethod);

/// The days marked not fasting (LC-034) in the Ramadans with the mode on:
/// one per-date setting each (A41a fix round 2).
@riverpod
Stream<Set<LocalDate>> ramadanNotFasting(Ref ref) async* {
  final settings = await ref.watch(ramadanSettingsProvider.future);
  final calendar = RamadanCalendar(settings);
  final byName = {
    for (final season in settings.seasons)
      if (season.on)
        if (calendar.calendarPeriod(season.hijriYear) case final period?)
          for (final d in RamadanFasting.datesOf(period))
            RamadanFasting.keyName(d): d,
  };
  if (byName.isEmpty) {
    yield const {};
    return;
  }
  yield* ref
      .watch(settingsStoreProvider)
      .watchValues(byName.keys)
      .map(
        (values) => {
          for (final MapEntry(:key, :value) in values.entries)
            if (AppSettings.fastingMark(byName[key]!).valueOf(value) ==
                FastingMark.notFasting)
              byName[key]!,
        },
      );
}

/// The Ramadan calendar over the stored decisions (A41a D1).
@riverpod
Future<RamadanCalendar> ramadanCalendar(Ref ref) async {
  final settingsFuture = ref.watch(ramadanSettingsProvider.future);
  final notFasting = await ref.watch(ramadanNotFastingProvider.future);
  return RamadanCalendar(await settingsFuture, notFasting: notFasting);
}

/// A fasting day's prayer times (LC-033, A41a D2 and fix round 1): the
/// dated instants ([PrayerDay]), the device-local minutes the diary uses
/// (slot windows: an entry's day and time are the device's, DY-001), and
/// the city's own wall-clock minutes for display (its IANA zone, so a city
/// in another zone or across a DST change shows its real times). Null
/// without a chosen city, or on a polar day. The chosen city only: no
/// location permission (LC-033 default).
typedef LocalPrayerTimes = ({
  PrayerDay day,
  int fajrMinute,
  int sunriseMinute,
  int maghribMinute,
  int cityFajrMinute,
  int cityMaghribMinute,
});

/// [LocalPrayerTimes] of the fasting day [date] (the city's calendar date).
@riverpod
Future<LocalPrayerTimes?> prayerTimes(Ref ref, LocalDate date) async {
  final cityFuture = ref.watch(selectedCityProvider.future);
  final method = await ref.watch(prayerMethodProvider.future);
  final city = await cityFuture;
  if (city == null) return null;
  final GeoPoint place;
  try {
    place = GeoPoint(city.latitude, city.longitude);
  }
  // Bundled data is validated (A05b); a bad row means no times, not a crash.
  // ignore: avoid_catching_errors
  on ArgumentError {
    return null;
  }
  final day = PrayerTimes.on(date, place, method: method);
  if (day == null) return null;
  final clock = ref.watch(clockProvider);
  int device(DateTime utc) =>
      EntryTime.at(utc, clock).localDateTime.minuteOfDay;
  // An unknown zone name falls back to the device's clock.
  int atCity(DateTime utc) =>
      CityZone.wallClock(city.timezone, utc)?.minute ?? device(utc);
  return (
    day: day,
    fajrMinute: device(day.fajrUtc),
    sunriseMinute: device(day.sunriseUtc),
    maghribMinute: device(day.maghribUtc),
    cityFajrMinute: atCity(day.fajrUtc),
    cityMaghribMinute: atCity(day.maghribUtc),
  );
}

/// The Ramadan to propose switching on for today (LC-031, A41a D4), or
/// null.
@riverpod
Future<RamadanPeriod?> ramadanProposal(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final calendar = await ref.watch(ramadanCalendarProvider.future);
  return calendar.proposalOn(await todayFuture);
}

/// The Ramadan that matters on today (in progress, else the next one) with
/// its stored decision, for Settings › Ramadan. Null past the table.
typedef RamadanStatus = ({RamadanPeriod period, RamadanSeason? season});

/// [RamadanStatus] on today.
@riverpod
Future<RamadanStatus?> ramadanStatus(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final calendar = await ref.watch(ramadanCalendarProvider.future);
  final period = calendar.relevant(await todayFuture);
  if (period == null) return null;
  return (period: period, season: calendar.settings[period.hijriYear]);
}

/// The Ramadan periods whose mode is on, for chart shading (WB-021).
@riverpod
Future<List<RamadanPeriod>> ramadanOnPeriods(Ref ref) async =>
    (await ref.watch(ramadanCalendarProvider.future)).onPeriods;

/// The Ramadan targets offer (TG-060, A41a D8) due today in the weekly
/// summary: the season, when it is due and the targets are generated (a
/// manual target is the user's own number and "maintain" leaves it as is).
@riverpod
Future<RamadanSeason?> ramadanTargetsOffer(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final calendar = await ref.watch(ramadanCalendarProvider.future);
  final today = await todayFuture;
  final period = calendar.targetsOfferOn(today);
  if (period == null) return null;
  final targets = await ref.watch(dayTargetsProvider(today).future);
  if (targets == null || targets.version.manual) return null;
  return calendar.settings[period.hijriYear];
}

/// Today's day of Ramadan with mode on (LC-020: the Hijri date alongside),
/// or null.
typedef RamadanDay = ({int day, int hijriYear});

/// [RamadanDay] of [date].
@riverpod
Future<RamadanDay?> ramadanDay(Ref ref, LocalDate date) async {
  final calendar = await ref.watch(ramadanCalendarProvider.future);
  final p = calendar.onPeriodContaining(date);
  return p == null ? null : (day: p.dayOf(date)!, hijriYear: p.hijriYear);
}
