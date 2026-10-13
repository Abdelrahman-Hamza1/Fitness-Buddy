import 'dart:math' show Random;

import 'package:fb_domain/src/time/clock.dart';

/// Makes new unique IDs for user data (`05` §1: UUIDv7 text, created on the
/// device). Injected, so tests can pass a predictable one.
abstract interface class IdGenerator {
  /// A new ID, never returned before by this generator.
  String next();
}

/// UUIDv7 IDs (RFC 9562 §5.7) with the "method 1" counter (§6.2), written
/// in-house because the `uuid` package brings runtime dependencies (S08 D9,
/// A5).
///
/// Layout: 48-bit Unix milliseconds, version `7`, a 12-bit counter
/// (`rand_a`), the RFC variant `10`, 62 random bits (`rand_b`). Output is
/// lowercase `8-4-4-4-12` text.
///
/// IDs from one generator are **strictly increasing**, as numbers and as
/// text: the counter is seeded randomly with its top bit clear on each new
/// millisecond and incremented within the same one; when the clock goes
/// backwards the last millisecond is reused; when the counter overflows the
/// generator moves on to the next millisecond and reseeds.
///
/// The app passes `Random.secure()` (`package:fb_domain/system.dart`); tests
/// pass a seeded `Random`.
final class UuidV7Generator implements IdGenerator {
  /// A generator that reads time from a [Clock] and bits from a `Random`.
  new(this._clock, this._random);

  final Clock _clock;
  final Random _random;

  /// The millisecond and counter of the last ID; -1 before the first.
  int _lastMs = -1;
  int _counter = 0;

  /// The largest 48-bit millisecond value (year 10889).
  static const int _maxMs = 0xFFFFFFFFFFFF;
  static const int _maxCounter = 0xFFF;

  @override
  String next() {
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    if (now < 0 || now > _maxMs) {
      throw StateError('clock out of the UUIDv7 range: $now ms');
    }
    if (now > _lastMs) {
      _lastMs = now;
      _counter = _seed();
    } else if (_counter < _maxCounter) {
      _counter++;
    } else {
      // Counter overflow: borrow the next millisecond (RFC 9562 §6.2).
      if (_lastMs == _maxMs) throw StateError('UUIDv7 range exhausted');
      _lastMs++;
      _counter = _seed();
    }

    final ms = _hex(_lastMs, 12);
    // rand_b: 8 random bytes, the top two bits replaced by the variant 10.
    final tail = StringBuffer(_hex(_random.nextInt(0x40) | 0x80, 2));
    for (var i = 1; i < 8; i++) {
      tail.write(_hex(_random.nextInt(0x100), 2));
    }
    final rand = tail.toString();
    return '${ms.substring(0, 8)}-${ms.substring(8)}-7${_hex(_counter, 3)}-'
        '${rand.substring(0, 4)}-${rand.substring(4)}';
  }

  /// A fresh counter, top bit clear, so at least 2,048 IDs fit in one
  /// millisecond before an overflow.
  int _seed() => _random.nextInt(0x800);
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
final _uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Whether [text] is a UUID in lowercase canonical `8-4-4-4-12` form (any
/// version). Uppercase or braces are not canonical.
bool isUuid(String text) => _uuid.hasMatch(text);

/// Whether [text] is a lowercase canonical UUID with version 7 and the RFC
/// variant.
bool isUuidV7(String text) => _uuidV7.hasMatch(text);

/// The Unix milliseconds encoded in the UUIDv7 [text]. Throws a
/// `FormatException` if [text] isn't a canonical UUIDv7.
int uuidV7Millis(String text) {
  if (!isUuidV7(text)) throw FormatException('not a UUIDv7', text);
  return int.parse(text.substring(0, 8) + text.substring(9, 13), radix: 16);
}

String _hex(int value, int width) =>
    value.toRadixString(16).padLeft(width, '0');
