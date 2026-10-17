import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/diary/application/diary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/diary_fixtures.dart';

void main() {
  test('DY-001 dayProvider and dayTotalsProvider follow the day: totals are '
      'the sum of the stored snapshots', () async {
    final db = memoryDatabase();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final date = LocalDate(2026, 10, 17);
    final days = <int>[];
    final totals = <double>[];
    container
      ..listen(dayProvider(date), (_, next) {
        if (next.value case final d?) days.add(d.entries.length);
      }, fireImmediately: true)
      ..listen(dayTotalsProvider(date), (_, next) {
        if (next.value case final t?) totals.add(t.kcal);
      }, fireImmediately: true);
    await pumpEventQueue();
    await insertEntries(db, [
      entryRow(1, date: '2026-10-17', slotId: DefaultSlots.lunchId, kcal: 120),
      entryRow(2, date: '2026-10-17', slotId: DefaultSlots.lunchId, kcal: 30),
    ]);
    await pumpEventQueue();
    expect(days.last, 2);
    expect(totals.last, 150);
  });
}
