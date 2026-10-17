/// Deterministic fakes of the domain's injected sources, for tests in any
/// package (A01 D20): a [ManualClock] and a [SequenceIdGenerator].
///
/// Like `package:fb_domain/system.dart`, the main barrel doesn't export it.
/// Only tests import it.
library;

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

  /// Moves the clock by [by] (backwards if negative).
  void advance(Duration by) => utc = utc.add(by);

  @override
  DateTime nowUtc() => utc;

  @override
  int offsetMinutesAt(DateTime utc) => zone?.call(utc) ?? offsetMinutes;
}

/// [ms] Unix milliseconds as a UTC `DateTime`.
DateTime utcMillis(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// An [IdGenerator] of predictable UUIDv7s: the n-th ID (from 0) has the
/// Unix millisecond `startMs + n` and ends in `n` in hex, e.g.
/// `0199e3c2-5b1a-7000-8000-000000000000`, then `…5b1b-7000-8000-…01`.
/// IDs are strictly increasing, as text too.
final class SequenceIdGenerator implements IdGenerator {
  /// A generator whose first ID has the millisecond [startMs]
  /// (default 2025-10-14T17:26:29.402Z).
  new({this.startMs = 0x0199e3c25b1a}) {
    if (startMs < 0) throw RangeError.value(startMs, 'startMs', 'is < 0');
  }

  /// The millisecond of the first ID.
  final int startMs;

  /// How many IDs were made.
  int get count => _count;
  int _count = 0;

  @override
  String next() {
    final ms = startMs + _count;
    if (ms > 0xFFFFFFFFFFFF) throw StateError('UUIDv7 range exhausted');
    final hex = ms.toRadixString(16).padLeft(12, '0');
    final tail = _count.toRadixString(16).padLeft(12, '0');
    _count++;
    return '${hex.substring(0, 8)}-${hex.substring(8)}-7000-8000-$tail';
  }
}
