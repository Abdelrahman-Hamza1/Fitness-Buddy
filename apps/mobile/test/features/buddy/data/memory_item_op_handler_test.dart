import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/buddy/data/memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

void main() {
  late AppDatabase db;
  late ChangeSetApplier<AppDatabase> applier;

  setUp(() {
    db = memoryDatabase();
    final bus = DomainEventBus();
    addTearDown(bus.close);
    final clock = ManualClock(DateTime.utc(2026, 11, 7, 8));
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [MemoryItemOpHandler(db)],
      clock: clock,
      ids: UuidV7Generator(clock, Random(3)),
      deviceId: () async => testDevice,
      events: bus,
    );
  });

  Future<ApplyResult> apply(MemoryItemOp op) =>
      applier.apply(ChangeSet([op], origin: Origin.direct));

  test('AI-055 an overwrite keeps the one row of a kind and key; delete and '
      'save again revives it', () async {
    final repo = MemoryRepository(db);
    const rice = SaveMemoryItem(
      kind: 'default',
      key: 'state:rice',
      value: 'raw',
    );
    expect(await apply(rice), isA<Applied>());
    expect(
      await apply(
        const SaveMemoryItem(
          kind: 'default',
          key: 'state:rice',
          value: 'cooked',
        ),
      ),
      isA<Applied>(),
    );
    final items = await repo.all();
    expect(items.map((i) => i.value), ['cooked']);
    expect(items.single.id, memoryItemId('default', 'state:rice'));

    final item = items.single;
    expect(
      await apply(DeleteMemoryItem(item.id, item.version)),
      isA<Applied>(),
    );
    expect(await repo.all(), isEmpty);
    // Deleting again: the row isn't live any more.
    expect(
      await apply(DeleteMemoryItem(item.id, item.version)),
      isA<Rejected>(),
    );
    expect(await apply(rice), isA<Applied>());
    expect((await repo.all()).single.value, 'raw');
  });

  test(
    'AI-082 clear all tombstones every item; invalid text is refused',
    () async {
      await apply(
        const SaveMemoryItem(
          kind: 'alias',
          key: 'my shake',
          value: 'whey shake',
        ),
      );
      await apply(
        const SaveMemoryItem(
          kind: 'habit',
          key: 'fat:chicken',
          value: 'oil',
          origin: MemoryOrigin.learned,
        ),
      );
      expect(await MemoryRepository(db).all(), hasLength(2));
      expect(await apply(const ClearMemoryItems()), isA<Applied>());
      expect(await MemoryRepository(db).all(), isEmpty);
      final rows = await db.select(db.memoryItems).get();
      expect(
        rows.every((r) => r.memoryKey.isEmpty && r.memoryValue.isEmpty),
        isTrue,
      );
      expect(
        await apply(const SaveMemoryItem(kind: 'alias', key: ' ', value: 'x')),
        isA<Rejected>(),
      );
    },
  );

  test('AI-055 a checked save refuses a row that changed or went since the '
      'card showed it', () async {
    const shown = SaveMemoryItem(
      kind: 'alias',
      key: 'shake',
      value: 'whey',
      checked: true,
    );
    expect(await apply(shown), isA<Applied>());
    // Planned on an absent row, but one exists now: refused.
    expect(await apply(shown), isA<Rejected>());
    final item = (await MemoryRepository(db).all()).single;
    const atV1 = SaveMemoryItem(
      kind: 'alias',
      key: 'shake',
      value: 'milk',
      checked: true,
      expectedVersion: 1,
    );
    await apply(DeleteMemoryItem(item.id, item.version));
    // Deleted meanwhile: never revived by an older card.
    expect(await apply(atV1), isA<Rejected>());
    expect(await MemoryRepository(db).all(), isEmpty);
  });
}
