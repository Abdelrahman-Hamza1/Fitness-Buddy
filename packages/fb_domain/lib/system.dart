/// The production sources of time and randomness for `fb_domain` (S08 D8).
///
/// This is the **only** file of the package that reads the system clock,
/// the device time zone or a random source (`test/determinism_test.dart`
/// enforces it). The main barrel doesn't export it: only the app's
/// composition root imports it and injects these into the domain.
library;

import 'dart:math' show Random;

import 'package:fb_domain/fb_domain.dart';

/// The device clock and time zone.
final class SystemClock implements Clock {
  /// The device clock.
  const new();

  @override
  DateTime nowUtc() => DateTime.timestamp();

  @override
  int offsetMinutesAt(DateTime utc) {
    if (!utc.isUtc) throw ArgumentError.value(utc, 'utc', 'must be UTC');
    // The zone rules at that instant, so DST is right for past instants.
    return utc.toLocal().timeZoneOffset.inMinutes;
  }
}

/// A cryptographically secure random source, for IDs.
Random secureRandom() => Random.secure();

/// The app's UUIDv7 generator: the device clock and a secure random source.
UuidV7Generator systemUuidV7Generator() =>
    UuidV7Generator(const SystemClock(), secureRandom());
