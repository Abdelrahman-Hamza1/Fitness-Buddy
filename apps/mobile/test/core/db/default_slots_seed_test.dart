import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/migrations/from_12_to_13.dart';
import 'package:fb_mobile/core/db/migrations/from_2_to_3.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/seeds/default_slots_seed.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/diary/support/diary_harness.dart';
import 'support/db_support.dart';

void main() {
  test('DY-010 the DefaultSlots ids are the natural ids of '
      'mealSlot:normal:<key>', () {
    for (final slot in DefaultSlots.all) {
      expect(
        naturalId('mealSlot', 'normal:${slot.defaultKey}'),
        slot.id,
        reason: slot.defaultKey,
      );
    }
  });

  test('DY-012 the RamadanSlots ids are the natural ids of '
      'mealSlot:ramadan:<key>', () {
    for (final slot in RamadanSlots.all) {
      expect(
        naturalId('mealSlot', 'ramadan:${slot.defaultKey}'),
        slot.id,
        reason: slot.defaultKey,
      );
    }
  });

  test('DY-012 the v13 migration seed list equals today RamadanSlots.all', () {
    expect(v13RamadanSlots, hasLength(RamadanSlots.all.length));
    for (final (i, slot) in RamadanSlots.all.indexed) {
      final pinned = v13RamadanSlots[i];
      expect(pinned.id, slot.id);
      expect(pinned.key, slot.defaultKey);
      expect(pinned.sortOrder, slot.sortOrder);
      expect(slot.window, isNull);
      expect(slot.mode, SlotMode.ramadan);
    }
  });

  test('DY-010 DY-012 a new database has the four default and three Ramadan '
      'slots, not captured', () async {
    final db = memoryDatabase();
    final rows = await db.select(db.mealSlots).get();
    expect(rows.map((r) => r.id).toSet(), {
      for (final slot in DefaultSlots.all) slot.id,
      for (final slot in RamadanSlots.all) slot.id,
    });
    expect(
      rows.where((r) => r.mode == 'ramadan').map((r) => r.defaultKey),
      unorderedEquals(['suhoor', 'iftar', 'snacks']),
    );
    expect(rows.every((r) => r.createdAt == 0 && r.name == null), isTrue);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('DY-010 a reopened seed does not overwrite an edited slot', () async {
    final h = DiaryHarness();
    await h.editSlot(
      DefaultSlots.lunchId,
      const MealSlotsCompanion(name: Value('Midday'), active: Value(false)),
    );
    await seedDefaultSlots(h.db, h.db.mealSlots);
    final lunch = await (h.db.select(
      h.db.mealSlots,
    )..where((t) => t.id.equals(DefaultSlots.lunchId))).getSingle();
    expect(lunch.name, 'Midday');
    expect(lunch.active, isFalse);
    expect(await h.db.select(h.db.mealSlots).get(), hasLength(7));
  });

  test('DY-010 the v3 migration seed list equals today DefaultSlots.all', () {
    expect(v3SeedSlots, hasLength(DefaultSlots.all.length));
    for (final (i, slot) in DefaultSlots.all.indexed) {
      final pinned = v3SeedSlots[i];
      expect(pinned.id, slot.id);
      expect(pinned.key, slot.defaultKey);
      expect(pinned.sortOrder, slot.sortOrder);
      expect(pinned.startMin, slot.window?.startMin);
      expect(pinned.endMin, slot.window?.endMin);
      expect(slot.mode, SlotMode.normal);
      expect(slot.active, isTrue);
    }
  });
}
