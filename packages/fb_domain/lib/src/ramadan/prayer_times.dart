import 'dart:math' as math;

import 'package:fb_domain/src/time/local_date.dart';

/// How Fajr is computed (LC-033, A41a D2): the sun's depression angle at
/// Fajr, and the minutes some official timetables add to sunset as a
/// precaution (ihtiyat). Maghrib is sunset (the sun's upper limb
/// on the horizon with standard refraction) in every method here.
///
/// Stored enum names are permanent synced values (the setting
/// `prayer.method`).
enum PrayerMethod {
  /// Muslim World League: Fajr 18°. The default (A41a D2): Ramallah's
  /// published timetables use it, and the computed times match them within
  /// two minutes (`prayer_times_test.dart`).
  muslimWorldLeague(fajrAngle: 18),

  /// Egyptian General Authority of Survey: Fajr 19.5°.
  egypt(fajrAngle: 19.5),

  /// Jordan's Ministry of Awqaf: Fajr 18°, Maghrib five minutes after
  /// sunset.
  jordan(fajrAngle: 18, maghribMinutes: 5),

  /// Umm al-Qura, Makkah: Fajr 18.5°.
  ummAlQura(fajrAngle: 18.5),

  /// Islamic Society of North America: Fajr 15°.
  northAmerica(fajrAngle: 15);

  new({required this.fajrAngle, this.maghribMinutes = 0});

  /// The sun's depression below the horizon at Fajr, in degrees.
  final double fajrAngle;

  /// Minutes added to sunset for Maghrib.
  final int maghribMinutes;

  /// The method stored as [name], or null.
  static PrayerMethod? fromName(String name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }
}

/// A place on Earth, in degrees (north and east positive).
final class GeoPoint {
  /// The point at [latitude] (−90…90) and [longitude] (−180…180). Throws an
  /// `ArgumentError` outside those ranges or for a non-finite value.
  new(this.latitude, this.longitude) {
    if (!latitude.isFinite || latitude.abs() > 90) {
      throw ArgumentError.value(latitude, 'latitude');
    }
    if (!longitude.isFinite || longitude.abs() > 180) {
      throw ArgumentError.value(longitude, 'longitude');
    }
  }

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  @override
  String toString() => 'GeoPoint';
}

/// One day's Fajr, sunrise and Maghrib as UTC instants in whole minutes
/// (Fajr and sunrise to the nearest, Maghrib rounded up), the way
/// timetables print them.
final class PrayerDay {
  const new _({
    required this.date,
    required this.fajrUtc,
    required this.sunriseUtc,
    required this.maghribUtc,
  });

  /// The local date the times belong to.
  final LocalDate date;

  /// Fajr (dawn: the fast begins).
  final DateTime fajrUtc;

  /// Sunrise.
  final DateTime sunriseUtc;

  /// Maghrib (sunset: the fast ends).
  final DateTime maghribUtc;

  @override
  String toString() => 'PrayerDay($date)';
}

/// Fajr, sunrise and Maghrib from the sun's position (LC-033, NT-026,
/// A41a D2), offline: the standard spherical-astronomy formulas (the
/// "PrayTimes" algorithm: the sun's declination and the equation of time
/// from the low-precision solar coordinates of the Astronomical Almanac,
/// good to about a minute between 1950 and 2050), refined once at the
/// computed time. Verified against a published Ramallah timetable in
/// `prayer_times_test.dart`.
abstract final class PrayerTimes {
  /// The sun's altitude at sunrise and sunset: its upper limb on the
  /// horizon with standard refraction (0.833°).
  static const double horizonAngle = 0.833;

  /// The times on [date] at [place] with [method], or null when the sun
  /// doesn't rise or set that day (polar day or night). Fajr at high
  /// latitudes follows the "middle of the night" rule.
  static PrayerDay? on(
    LocalDate date,
    GeoPoint place, {
    PrayerMethod method = PrayerMethod.muslimWorldLeague,
  }) {
    // Julian date at 0h UT of the date, then shifted to local solar
    // midnight, as the algorithm expects.
    final jd = _julian(date) - place.longitude / (15 * 24);
    final lat = place.latitude;
    // Initial guesses in local solar hours, refined once (PrayTimes).
    var fajr = _sunAngleTime(jd, lat, method.fajrAngle, 5, ccw: true);
    var sunrise = _sunAngleTime(jd, lat, horizonAngle, 6, ccw: true);
    var sunset = _sunAngleTime(jd, lat, horizonAngle, 18, ccw: false);
    if (sunrise == null || sunset == null) return null;
    sunrise = _sunAngleTime(jd, lat, horizonAngle, sunrise, ccw: true);
    sunset = _sunAngleTime(jd, lat, horizonAngle, sunset, ccw: false);
    if (sunrise == null || sunset == null) return null;
    fajr = fajr == null
        ? null
        : _sunAngleTime(jd, lat, method.fajrAngle, fajr, ccw: true);
    // High latitudes (the "middle of the night" rule, PrayTimes'
    // NightMiddle): Fajr is never earlier than the middle of the night
    // (half the night before sunrise), and is that bound when the sun
    // doesn't get low enough. The same bound in both places, so Fajr moves
    // smoothly from day to day. At Ramallah's latitude it never applies.
    final night = 24 - (sunset - sunrise);
    final earliest = sunrise - night / 2;
    if (fajr == null || fajr.isNaN || fajr < earliest) fajr = earliest;
    final offset = -place.longitude / 15;
    // Whole minutes as timetables print them: Fajr to the nearest minute,
    // Maghrib rounded up, so the fast is never shown ending early.
    DateTime instant(
      double localSolarHours,
      int addMinutes, {
      bool up = false,
    }) {
      final exact = (localSolarHours + offset) * 60;
      final minutes = (up ? exact.ceil() : exact.round()) + addMinutes;
      return DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: minutes));
    }

    return PrayerDay._(
      date: date,
      fajrUtc: instant(fajr, 0),
      sunriseUtc: instant(sunrise, 0),
      maghribUtc: instant(sunset, method.maghribMinutes, up: true),
    );
  }

  /// The local solar time (hours) when the sun is [angle] degrees below
  /// the horizon, near the guess [hours]: before noon ([ccw]) or after.
  /// Null when the sun never gets there that day.
  static double? _sunAngleTime(
    double jd,
    double lat,
    double angle,
    double hours, {
    required bool ccw,
  }) {
    final (:decl, :eqt) = _sun(jd + hours / 24);
    final noon = _fixHour(12 - eqt);
    final cos =
        (-_sinD(angle) - _sinD(decl) * _sinD(lat)) / (_cosD(decl) * _cosD(lat));
    if (cos < -1 || cos > 1) return null;
    final t = _acosD(cos) / 15;
    return noon + (ccw ? -t : t);
  }

  /// The sun's declination (degrees) and the equation of time (hours) at
  /// Julian date [jd].
  static ({double decl, double eqt}) _sun(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sinD(g) + 0.020 * _sinD(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final ra = _fixHour(_atan2D(_cosD(e) * _sinD(l), _cosD(l)) / 15);
    return (decl: _asinD(_sinD(e) * _sinD(l)), eqt: q / 15 - ra);
  }

  static double _julian(LocalDate date) {
    var y = date.year;
    var m = date.month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        date.day +
        b -
        1524.5;
  }

  static const double _rad = math.pi / 180;
  static double _sinD(double d) => math.sin(d * _rad);
  static double _cosD(double d) => math.cos(d * _rad);
  static double _asinD(double x) => math.asin(x) / _rad;
  static double _acosD(double x) => math.acos(x) / _rad;
  static double _atan2D(double y, double x) => math.atan2(y, x) / _rad;
  static double _fixAngle(double a) => a - 360 * (a / 360).floor();
  static double _fixHour(double h) => h - 24 * (h / 24).floor();
}
