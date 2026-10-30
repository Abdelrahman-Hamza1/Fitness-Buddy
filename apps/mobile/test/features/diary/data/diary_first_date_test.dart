import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

void main() {
  test('DY-004 IN-009 the earliest diary day counts live day marks too, '
      'never tombstoned marks or entries', () async {
    final h = DiaryHarness();
    final repository = DiaryRepository(h.db);
    Future<LocalDate?> first() => repository.watchFirstDiaryDate().first;
    expect(await first(), isNull);

    // Mark-only history: a day marked incomplete with no entries.
    final marked = today.plusDays(-30);
    await h.apply([MarkDay(marked, incomplete: true)]);
    expect(await first(), marked);

    // A later entry doesn't move it.
    await insertEntries(h.db, [
      entryRow(1, date: '${today.plusDays(-10)}', slotId: DefaultSlots.lunchId),
    ]);
    expect(await first(), marked);

    // An older tombstoned mark and an older tombstoned entry are ignored.
    await runAuthorizedWrite(
      () => h.db
          .into(h.db.dayMarks)
          .insert(
            DayMarksCompanion.insert(
              id: fixtureId(900),
              createdAt: 1,
              updatedHlc: hlcAt(1),
              version: 2,
              deletedAt: const Value(5),
              deviceId: testDevice,
              origin: 'direct',
              localDate: '${today.plusDays(-60)}',
              incomplete: true,
            ),
          ),
    );
    await insertEntries(h.db, [
      entryRow(
        2,
        date: '${today.plusDays(-90)}',
        slotId: DefaultSlots.lunchId,
        deletedAt: 5,
      ),
    ]);
    expect(await first(), marked);

    // An entry before the mark is the new first day.
    await insertEntries(h.db, [
      entryRow(3, date: '${today.plusDays(-40)}', slotId: DefaultSlots.lunchId),
    ]);
    expect(await first(), today.plusDays(-40));
  });
}
