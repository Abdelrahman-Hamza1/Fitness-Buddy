import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The wall clock of a city's IANA zone (A41a fix round 1): prayer times
/// are shown as the city's own times, whatever the device zone. The zone
/// database (bundled with `timezone`, already an A40 dependency) is loaded
/// on first use, never on the startup path.
abstract final class CityZone {
  static bool _loaded = false;

  /// The minute of the day of [utc] on the wall clock of [zone] (an IANA
  /// name like `Asia/Hebron`), with its date; null for an unknown zone.
  static ({DateTime local, int minute})? wallClock(String zone, DateTime utc) {
    if (!_loaded) {
      tzdata.initializeTimeZones();
      _loaded = true;
    }
    final tz.Location location;
    try {
      location = tz.getLocation(zone);
    } on tz.LocationNotFoundException {
      return null;
    }
    final local = tz.TZDateTime.from(utc, location);
    return (local: local, minute: local.hour * 60 + local.minute);
  }
}
