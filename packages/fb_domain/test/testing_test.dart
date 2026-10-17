import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:test/test.dart';

void main() {
  group('testing:', () {
    test('ManualClock is deterministic and moves only by hand', () {
      final clock = ManualClock(DateTime.utc(2026, 10, 17), offsetMinutes: 180);
      expect(clock.nowUtc(), DateTime.utc(2026, 10, 17));
      expect(clock.nowUtc(), clock.nowUtc());
      expect(clock.offsetMinutesAt(DateTime.utc(2026)), 180);

      clock.advance(const Duration(seconds: 6));
      expect(clock.nowUtc(), DateTime.utc(2026, 10, 17, 0, 0, 6));
      clock.advance(const Duration(seconds: -7));
      expect(clock.nowUtc(), DateTime.utc(2026, 10, 16, 23, 59, 59));

      clock.millis = 1000;
      expect(clock.nowUtc(), utcMillis(1000));
      expect(clock.nowUtc().isUtc, isTrue);
      expect(clock.millis, 1000);

      final zoned = ManualClock.millis(0, offsetMinutes: 60)
        ..zone = (utc) => utc.month == 7 ? 60 : 0;
      expect(zoned.offsetMinutesAt(DateTime.utc(2026, 7)), 60);
      expect(zoned.offsetMinutesAt(DateTime.utc(2026)), 0);
    });

    test('SequenceIdGenerator is deterministic', () {
      final ids = SequenceIdGenerator();
      final again = SequenceIdGenerator();
      final first = [for (var i = 0; i < 20; i++) ids.next()];
      expect(first, [for (var i = 0; i < 20; i++) again.next()]);
      expect(ids.count, 20);
      expect(first.first, '0199e3c2-5b1a-7000-8000-000000000000');
      expect(first[1], '0199e3c2-5b1b-7000-8000-000000000001');
      for (final (i, id) in first.indexed) {
        expect(isUuidV7(id), isTrue, reason: id);
        expect(uuidV7Millis(id), 0x0199e3c25b1a + i);
        if (i > 0) expect(id.compareTo(first[i - 1]), greaterThan(0));
      }
    });

    test('SequenceIdGenerator starts where asked and stays in range', () {
      expect(
        SequenceIdGenerator(startMs: 0).next(),
        '00000000-0000-7000-8000-000000000000',
      );
      final last = SequenceIdGenerator(startMs: 0xFFFFFFFFFFFF);
      expect(last.next(), 'ffffffff-ffff-7000-8000-000000000000');
      expect(last.next, throwsStateError);
      expect(() => SequenceIdGenerator(startMs: -1), throwsRangeError);
    });
  });
}
