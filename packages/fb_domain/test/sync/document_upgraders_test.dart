import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

Map<String, Object?> _v1({
  num kg = 75.5,
  num measuredAtUtc = 1761609600000, // 2025-10-28T00:00Z
  String localDate = '2025-10-28',
}) => {
  'createdAtMs': 1761609600000,
  'origin': 'direct',
  'editedByUser': false,
  'measuredAtUtc': measuredAtUtc,
  'localDate': localDate,
  'kg': kg,
  'note': null,
};

void main() {
  group('SyncDocumentUpgraders:', () {
    test('current versions: weighIn 2, every other entity 1', () {
      expect(SyncDocumentUpgraders.currentVersionOf('weighIn'), 2);
      expect(SyncDocumentUpgraders.currentVersionOf('diaryEntry'), 1);
    });

    test('weighIn v1 → v2 adds the A14 D7 fields and keeps v1 fields', () {
      final v2 = SyncDocumentUpgraders.upgrade('weighIn', 1, _v1())!;
      expect(v2, {
        ..._v1(),
        'tzOffsetMin': 0,
        'inputValue': 75.5,
        'inputUnit': 'kg',
        'preferredForDay': false,
      });
    });

    test('the current version passes through unchanged (a copy)', () {
      final payload = {'kg': 1};
      final same = SyncDocumentUpgraders.upgrade('weighIn', 2, payload)!;
      expect(same, payload);
      expect(identical(same, payload), isFalse);
      expect(SyncDocumentUpgraders.upgrade('diaryEntry', 1, payload), payload);
    });

    test('newer, zero or unreadable versions read as null', () {
      expect(SyncDocumentUpgraders.upgrade('weighIn', 3, _v1()), isNull);
      expect(SyncDocumentUpgraders.upgrade('diaryEntry', 2, _v1()), isNull);
      expect(SyncDocumentUpgraders.upgrade('weighIn', 0, _v1()), isNull);
      for (final broken in [
        {..._v1()}..remove('kg'),
        {..._v1(), 'measuredAtUtc': 1.5},
        {..._v1(), 'measuredAtUtc': '1'},
        {..._v1(), 'localDate': '2025-13-01'},
        {..._v1(), 'localDate': 7},
      ]) {
        expect(SyncDocumentUpgraders.upgrade('weighIn', 1, broken), isNull);
      }
    });

    test('the implied offset: east and west of UTC, nearest to 0, clamped', () {
      final date = LocalDate(2025, 10, 28);
      final midnight = DateTime.utc(2025, 10, 28).millisecondsSinceEpoch;
      int at(Duration d) => SyncDocumentUpgraders.impliedOffsetMinutes(
        midnight + d.inMilliseconds,
        date,
      );
      expect(at(const Duration(hours: 9)), 0);
      // 21:30 UTC the day before is the 28th from UTC+02:30 on.
      expect(at(const Duration(hours: -2, minutes: -30)), 150);
      // 02:00 UTC on the 29th is still the 28th west of UTC−02:00.
      expect(at(const Duration(hours: 26)), -121);
      expect(at(const Duration(hours: -20)), 840);
      expect(at(const Duration(hours: 40)), -720);
      // A whole-number 1.0-style `measuredAtUtc` is accepted.
      expect(
        SyncDocumentUpgraders.upgrade('weighIn', 1, {
          ..._v1(measuredAtUtc: 1761609600000.0),
        })!['tzOffsetMin'],
        0,
      );
    });

    Glados2(
      any.intInRange(-40 * 60, 64 * 60),
      any.intInRange(0, 60000),
      propertyRuns,
    ).test('an unclamped implied offset puts the instant on the local date', (
      minutes,
      ms,
    ) {
      final date = LocalDate(2026, 3, 1);
      final midnight = DateTime.utc(2026, 3).millisecondsSinceEpoch;
      final instant = midnight + minutes * 60000 + ms;
      final offset = SyncDocumentUpgraders.impliedOffsetMinutes(instant, date);
      expect(offset, inInclusiveRange(-720, 840));
      if (offset > -720 && offset < 840) {
        final local = DateTime.fromMillisecondsSinceEpoch(
          instant + offset * 60000,
          isUtc: true,
        );
        expect([local.year, local.month, local.day], [2026, 3, 1]);
      }
    });

    test('RemoteChangesApplied: value equality by entity set, no content', () {
      final a = RemoteChangesApplied(['diaryEntry', 'weighIn']);
      expect(a, RemoteChangesApplied(['weighIn', 'diaryEntry']));
      expect(
        a.hashCode,
        RemoteChangesApplied(['weighIn', 'diaryEntry']).hashCode,
      );
      expect(a, isNot(RemoteChangesApplied(['weighIn'])));
      expect('$a', contains('diaryEntry'));
      expect(() => a.entities.add('x'), throwsUnsupportedError);
    });
  });
}
