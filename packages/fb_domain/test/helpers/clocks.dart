import 'package:fb_domain/fb_domain.dart';

/// A [Clock] the test moves by hand. The zone offset is [offsetMinutes],
/// or [zone] when the test needs rules that depend on the instant (DST).
final class ManualClock implements Clock {
  /// A clock showing [utc].
  new(this.utc, {this.offsetMinutes = 0, this.zone});

  /// A clock showing [ms] Unix milliseconds.
  new millis(int ms, {int offsetMinutes = 0})
    : this(utcMillis(ms), offsetMinutes: offsetMinutes);

  /// What [nowUtc] returns.
  DateTime utc;

  /// The zone offset when there is no [zone].
  int offsetMinutes;

  /// Zone rules: the offset at an instant.
  int Function(DateTime utc)? zone;

  /// The clock's time in Unix milliseconds.
  int get millis => utc.millisecondsSinceEpoch;
  set millis(int ms) => utc = utcMillis(ms);

  @override
  DateTime nowUtc() => utc;

  @override
  int offsetMinutesAt(DateTime utc) => zone?.call(utc) ?? offsetMinutes;
}

/// [ms] Unix milliseconds as a UTC `DateTime`.
DateTime utcMillis(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
