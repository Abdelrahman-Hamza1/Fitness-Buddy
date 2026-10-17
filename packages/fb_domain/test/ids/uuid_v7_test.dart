import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

/// A `Random` that always returns the largest value: counters are seeded
/// at 0x7FF, so the overflow comes after exactly 2,049 IDs.
final class _MaxRandom implements Random {
  @override
  int nextInt(int max) => max - 1;

  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.999;
}

const _ms = 1760351234567; // 2025-10-13T10:27:14.567Z

void main() {
  group('UUIDv7:', () {
    test('UUIDv7 has version 7 and the RFC variant', () {
      final ids = UuidV7Generator(ManualClock.millis(_ms), Random(1));
      for (var i = 0; i < 100; i++) {
        final id = ids.next();
        expect(id, hasLength(36));
        expect(id[14], '7');
        expect('89ab', contains(id[19]));
        expect(isUuid(id), isTrue);
        expect(isUuidV7(id), isTrue);
      }
    });

    test('UUIDv7 encodes the clock ms', () {
      final id = UuidV7Generator(ManualClock.millis(_ms), Random(1)).next();
      expect(uuidV7Millis(id), _ms);
      expect(id.substring(0, 13), '0199dd1c-2a07'); // _ms in hex: 199dd1c2a07
      expect(
        uuidV7Millis(UuidV7Generator(ManualClock.millis(0), Random(1)).next()),
        0,
      );
    });

    test('UUIDv7 same seed → same ids', () {
      List<String> run() {
        final clock = ManualClock.millis(_ms);
        final ids = UuidV7Generator(clock, Random(42));
        return [
          for (var i = 0; i < 50; i++) ids.next(),
          for (var i = 0; i < 50; i++) (ids..next()).next(),
        ];
      }

      expect(run(), run());
      expect(
        UuidV7Generator(ManualClock.millis(_ms), Random(1)).next(),
        isNot(UuidV7Generator(ManualClock.millis(_ms), Random(2)).next()),
      );
    });

    test('UUIDv7 counter overflow moves to the next ms and reseeds (A5)', () {
      final ids = UuidV7Generator(ManualClock.millis(_ms), _MaxRandom());
      final first = ids.next();
      expect(first.substring(15, 18), '7ff'); // seed: top bit clear
      final batch = [for (var i = 0; i < 2048; i++) ids.next()];
      expect(batch.last.substring(15, 18), 'fff');
      expect(uuidV7Millis(batch.last), _ms);
      final overflow = ids.next();
      expect(uuidV7Millis(overflow), _ms + 1);
      expect(overflow.substring(15, 18), '7ff');
      expect(overflow.compareTo(batch.last), greaterThan(0));
    });

    test('UUIDv7 a clock outside the 48-bit range is an error', () {
      expect(
        () => UuidV7Generator(ManualClock.millis(-1), Random(1)).next(),
        throwsStateError,
      );
      expect(
        () => UuidV7Generator(
          ManualClock.millis(0x1000000000000),
          Random(1),
        ).next(),
        throwsStateError,
      );
      // The last millisecond can't be borrowed past.
      final ids = UuidV7Generator(
        ManualClock.millis(0xFFFFFFFFFFFF),
        _MaxRandom(),
      );
      for (var i = 0; i < 2049; i++) {
        ids.next();
      }
      expect(ids.next, throwsStateError);
    });

    test('UUIDv7 is an IdGenerator', () {
      final IdGenerator ids = UuidV7Generator(
        ManualClock.millis(_ms),
        Random(1),
      );
      expect(isUuidV7(ids.next()), isTrue);
    });

    test('isUuid / isUuidV7 / uuidV7Millis reject non-canonical text', () {
      const v4 = '0199e3c2-5b1a-4c3d-8e4f-0123456789ab';
      expect(isUuid(v4), isTrue);
      expect(isUuidV7(v4), isFalse);
      expect(() => uuidV7Millis(v4), throwsFormatException);
      for (final bad in [
        '0199E3C2-5B1A-7C3D-8E4F-0123456789AB',
        '{0199e3c2-5b1a-7c3d-8e4f-0123456789ab}',
        '0199e3c25b1a7c3d8e4f0123456789ab',
        '0199e3c2-5b1a-7c3d-8e4f-0123456789a',
        '0199e3c2-5b1a-7c3d-ce4f-0123456789ab', // wrong variant
        '',
      ]) {
        expect(isUuid(bad) && isUuidV7(bad), isFalse, reason: bad);
        expect(() => uuidV7Millis(bad), throwsFormatException, reason: bad);
      }
    });
  });

  group('property: UUIDv7', () {
    Glados2(
      any.listWithLengthInRange(1, 60, any.intInRange(-3, 4)),
      any.int,
      propertyRuns,
    ).test('ids from one generator are strictly increasing, even with a clock '
        'that goes backwards', (steps, seed) {
      final clock = ManualClock.millis(_ms);
      final ids = UuidV7Generator(clock, Random(seed));
      var previous = ids.next();
      for (final step in steps) {
        clock.millis += step;
        // Two IDs per step, so the same ms is reused too.
        for (var i = 0; i < 2; i++) {
          final id = ids.next();
          expect(isUuidV7(id), isTrue, reason: id);
          expect(id.compareTo(previous), greaterThan(0), reason: id);
          previous = id;
        }
      }
    });

    Glados2(any.intInRange(0, 0xFFFFFFFFFFFF - 10), any.int, propertyRuns).test(
      'frozen clock: 5,000 ids are strictly increasing and valid (A5)',
      (ms, seed) {
        final ids = UuidV7Generator(ManualClock.millis(ms), Random(seed));
        var previous = ids.next();
        for (var i = 1; i < 5000; i++) {
          final id = ids.next();
          if (!isUuidV7(id) || id.compareTo(previous) <= 0) {
            fail('id $i: $id after $previous');
          }
          previous = id;
        }
        // 5,000 ids overflow a counter seeded below 0x800 at least once.
        expect(uuidV7Millis(previous), greaterThan(ms));
      },
    );
  });
}
