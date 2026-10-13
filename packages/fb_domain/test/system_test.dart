import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/system.dart';
import 'package:test/test.dart';

void main() {
  group('system:', () {
    test('SystemClock returns UTC and the device offset', () {
      const clock = SystemClock();
      final before = DateTime.now().toUtc();
      final now = clock.nowUtc();
      final after = DateTime.now().toUtc();
      expect(now.isUtc, isTrue);
      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);

      for (final instant in [now, DateTime.utc(2026), DateTime.utc(2026, 7)]) {
        expect(
          clock.offsetMinutesAt(instant),
          instant.toLocal().timeZoneOffset.inMinutes,
        );
      }
      expect(() => clock.offsetMinutesAt(DateTime(2026)), throwsArgumentError);
      expect(EntryTime.now(clock).occurredAtUtc.isUtc, isTrue);
    });

    test('the system UUIDv7 generator uses the clock and a secure source', () {
      final ids = systemUuidV7Generator();
      final first = ids.next();
      final second = ids.next();
      expect(isUuidV7(first), isTrue);
      expect(second.compareTo(first), greaterThan(0));
      final ms = DateTime.now().millisecondsSinceEpoch;
      expect(uuidV7Millis(first), inInclusiveRange(ms - 60000, ms));
      expect(secureRandom().nextInt(10), inInclusiveRange(0, 9));
    });
  });
}
