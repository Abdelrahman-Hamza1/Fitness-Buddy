/// The source of "now" and of the device's time zone (S08 D7).
///
/// The domain never reads the system clock or the device zone itself: it gets
/// a [Clock]. The app passes `SystemClock` from `package:fb_domain/system.dart`
/// (its composition root is the only importer); tests pass a fake, so every
/// rule is deterministic.
abstract interface class Clock {
  /// The current instant, in UTC (`isUtc` is true).
  DateTime nowUtc();

  /// The device zone's offset from UTC, in minutes, **at the instant [utc]**
  /// (not now), so an instant on the other side of a DST change gets that
  /// side's offset. [utc] must be a UTC `DateTime`.
  int offsetMinutesAt(DateTime utc);
}
