import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

final _day = LocalDate(2026, 10, 13);
final _yesterday = LocalDate(2026, 10, 12);

void main() {
  group('diary events:', () {
    test('events carry entry IDs and dates only', () {
      final logged = EntriesLogged([entryA, entryB, entryA], [_day, _day]);
      expect(logged, isA<DomainEvent>());
      expect(logged.entryIds, {entryA, entryB});
      expect(logged.dates, {_day});
      expect(() => logged.entryIds.add(entryC), throwsUnsupportedError);
      expect(() => logged.dates.add(_yesterday), throwsUnsupportedError);
      expect(
        '${EntryChanged([entryA], [_day, _yesterday])}',
        'EntryChanged(1 entries, 2026-10-12, 2026-10-13)',
      );
      expect(
        '${EntryDeleted([entryA, entryB], [_day])}',
        'EntryDeleted(2 entries, 2026-10-13)',
      );
      expect('$logged', 'EntriesLogged(2 entries, 2026-10-13)');
    });

    test('equality by kind, IDs and dates, in any order', () {
      expect(
        EntriesLogged([entryA, entryB], [_day, _yesterday]),
        EntriesLogged([entryB, entryA], [_yesterday, _day]),
      );
      expect(
        EntriesLogged([entryA, entryB], [_day]).hashCode,
        EntriesLogged([entryB, entryA], [_day]).hashCode,
      );
      expect(
        EntriesLogged([entryA], [_day]),
        isNot(EntryChanged([entryA], [_day])),
      );
      expect(
        EntryChanged([entryA], [_day]),
        isNot(EntryDeleted([entryA], [_day])),
      );
      expect(
        EntryDeleted([entryA], [_day]),
        isNot(EntryDeleted([entryA, entryB], [_day])),
      );
      expect(
        EntryDeleted([entryA], [_day]),
        isNot(EntryDeleted([entryB], [_day])),
      );
      expect(
        EntryDeleted([entryA], [_day]),
        isNot(EntryDeleted([entryA], [_yesterday])),
      );
      expect(
        EntryDeleted([entryA], [_day]),
        isNot(EntryDeleted([entryA], [_day, _yesterday])),
      );
    });

    test('DY-004 DayMarked carries the date and the mark', () {
      final event = DayMarked(_day, incomplete: true);
      expect(event, isA<DomainEvent>());
      expect(event, DayMarked(_day, incomplete: true));
      expect(event.hashCode, DayMarked(_day, incomplete: true).hashCode);
      expect(event, isNot(DayMarked(_day, incomplete: false)));
      expect(event, isNot(DayMarked(_yesterday, incomplete: true)));
      expect('$event', 'DayMarked(2026-10-13, incomplete: true)');
    });
  });
}
