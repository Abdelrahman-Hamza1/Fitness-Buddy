import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ramallah (Asia/Hebron: UTC+2, UTC+3 from 2026-03-28 to 2026-10-23).
const _ramallah = CatalogCity(
  id: 'city:282239',
  nameEn: 'Ramallah',
  nameAr: 'رام الله',
  countryCode: 'PS',
  population: 24599,
  timezone: 'Asia/Hebron',
  latitude: 31.89964,
  longitude: 35.20422,
);

final _season = RamadanSeason(hijriYear: 1447, on: true);

ProviderContainer _device(int offsetMinutes) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(
        ManualClock(DateTime.utc(2026, 3), offsetMinutes: offsetMinutes),
      ),
      selectedCityProvider.overrideWith((ref) async => _ramallah),
      prayerMethodProvider.overrideWith(
        (ref) => Stream.value(PrayerMethod.muslimWorldLeague),
      ),
      ramadanSettingsProvider.overrideWith(
        (ref) => Stream.value(RamadanSettings([_season])),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<LocalPrayerTimes> _times(ProviderContainer c, LocalDate date) async {
  final sub = c.listen(prayerTimesProvider(date), (_, _) {});
  try {
    final times = await c.read(prayerTimesProvider(date).future);
    return times!;
  } finally {
    sub.close();
  }
}

int _hm(int h, int m) => h * 60 + m;

void main() {
  test("A41a fix 2: the city's own times come from its IANA zone, whatever "
      "the device's zone, across the city's DST change", () async {
    // A phone in New York (UTC−4) with Ramallah chosen.
    final c = _device(-240);
    // IslamicFinder: 2026-03-19 04:24 / 17:51 (UTC+2); 2026-03-28 05:10 /
    // 18:58 (UTC+3, Hebron's DST started that night).
    final before = await _times(c, LocalDate(2026, 3, 19));
    expect((before.cityFajrMinute - _hm(4, 24)).abs(), lessThanOrEqualTo(2));
    expect(
      (before.cityMaghribMinute - _hm(17, 51)).abs(),
      lessThanOrEqualTo(2),
    );
    final after = await _times(c, LocalDate(2026, 3, 28));
    expect((after.cityFajrMinute - _hm(5, 10)).abs(), lessThanOrEqualTo(2));
    expect((after.cityMaghribMinute - _hm(18, 58)).abs(), lessThanOrEqualTo(2));
    // The diary's minutes are the device's: six hours earlier in March.
    expect(before.fajrMinute, (before.cityFajrMinute - 6 * 60) % 1440);
  });

  test(
    'A41a fix 2: reminders keep the dated instant: a device far east of '
    'the city gets the iftar nudge on its next day, not 24 h early',
    () async {
      // A phone at UTC+14 (Kiritimati) with Ramallah chosen.
      final c = _device(14 * 60);
      final day = LocalDate(2026, 3, 1);
      final t = await _times(c, day);
      final calendar = RamadanCalendar(RamadanSettings([_season]));
      final candidates = RamadanReminders.candidates(
        calendar: calendar,
        today: day,
        prayer: (d) => d == day
            ? (fajrUtc: t.day.fajrUtc, maghribUtc: t.day.maghribUtc)
            : null,
        clock: c.read(clockProvider),
      );
      final iftar = candidates.firstWhere(
        (n) => n.type == NotificationType.iftar,
      );
      final at = t.day.maghribUtc.add(const Duration(minutes: 90));
      expect(iftar.atUtc, at);
      // 17:29 + 1:30 in Ramallah (UTC+2) is 16:59 UTC = 06:59 on 2 March at
      // UTC+14.
      expect(iftar.date, LocalDate(2026, 3, 2));
      expect(iftar.minute, EntryTime(at, 14 * 60).localDateTime.minuteOfDay);
    },
  );

  test('an unknown zone name falls back to the device clock', () async {
    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(
          ManualClock(DateTime.utc(2026, 3), offsetMinutes: 120),
        ),
        selectedCityProvider.overrideWith(
          (ref) async => const CatalogCity(
            id: 'city:1',
            nameEn: 'X',
            nameAr: null,
            countryCode: 'PS',
            population: 0,
            timezone: 'Nowhere/Unknown',
            latitude: 31.9,
            longitude: 35.2,
          ),
        ),
        prayerMethodProvider.overrideWith(
          (ref) => Stream.value(PrayerMethod.muslimWorldLeague),
        ),
      ],
    );
    addTearDown(c.dispose);
    final t = await _times(c, LocalDate(2026, 3, 1));
    expect(t.cityFajrMinute, t.fajrMinute);
  });
}
