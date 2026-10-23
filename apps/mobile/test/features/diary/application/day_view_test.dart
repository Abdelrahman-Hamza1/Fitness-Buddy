import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

ProviderContainer setup(DiaryHarness h) {
  final container = ProviderContainer(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(DiaryRepository(h.db)),
      changeSetApplierProvider.overrideWithValue(h.applier),
      clockProvider.overrideWithValue(h.clock),
      diaryApplyProvider.overrideWithValue(h.applier.apply),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void setApply(
  ProviderContainer c,
  DiaryHarness h,
  Future<ApplyResult> Function(ChangeSet) apply,
) {
  c.updateOverrides([
    diaryRepositoryProvider.overrideWithValue(c.read(diaryRepositoryProvider)),
    changeSetApplierProvider.overrideWithValue(h.applier),
    clockProvider.overrideWithValue(h.clock),
    diaryApplyProvider.overrideWithValue(apply),
  ]);
}

Future<DayView> view(ProviderContainer c, LocalDate day) async {
  final ready = Completer<DayView>();
  final sub = c.listen(dayViewProvider(day), (_, next) {
    if (next case AsyncData(:final value)) {
      if (!ready.isCompleted) ready.complete(value);
    }
    if (next case AsyncError(:final error, :final stackTrace)) {
      if (!ready.isCompleted) ready.completeError(error, stackTrace);
    }
  }, fireImmediately: true);
  final result = await ready.future;
  sub.close();
  return result;
}

DiaryDay raw(LocalDate date, Iterable<DiaryEntry> entries) =>
    DiaryDay(date: date, slots: DefaultSlots.all, groups: [], entries: entries);

void main() {
  test('DY-022 UX-030 delete uses shown version, direct origin and '
      'undo revives beyond cache window', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1)]),
    ]);
    final c = setup(h);
    final sub = c.listen(dayViewProvider(today), (_, _) {});
    final entry = (await view(c, today)).raw.entries.single;
    final actions = c.read(diaryActionsControllerProvider.notifier);
    final release = Completer<void>();
    setApply(c, h, (change) async {
      await release.future;
      return await h.applier.apply(change);
    });
    final deleting = actions.deleteEntry(entry);
    sub.close();
    await c.pump();
    release.complete();
    final result = await deleting as DiaryActionDone;
    expect(c.read(diaryActionsControllerProvider).hidden, hasLength(1));
    expect(result.kind, DiaryActionKind.entryDeleted);
    expect(c.read(undoStackProvider).latest!.label.key, 'entryDeleted');
    expect((await h.entry(1)).origin, 'direct');
    await c.pump();
    final away = c.listen(dayViewProvider(today.plusDays(-3)), (_, _) {});
    await view(c, today.plusDays(-3));
    expect(
      await c.read(undoStackProvider).undo(result.undoEntryId),
      UndoOutcome.undone,
    );
    away.close();
    final back = await view(c, today);
    expect(back.layout.entryCount, 1);
    expect(back.raw.entries.single.version, greaterThan(entry.version));
    expect(c.read(diaryActionsControllerProvider).hidden, isEmpty);
  });

  test('DY-022 same slot writes nothing; stale delete rejects changed '
      'and restores visibility', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1)]),
    ]);
    final c = setup(h);
    final sub = c.listen(dayViewProvider(today), (_, _) {});
    addTearDown(sub.close);
    final entry = (await view(c, today)).raw.entries.single;
    final actions = c.read(diaryActionsControllerProvider.notifier);
    final before = await h.state();
    expect(
      await actions.moveEntry(entry, entry.slotId),
      isA<DiaryActionUnchanged>(),
    );
    expect(await h.state(), before);
    await h.apply([
      MoveEntries([
        VersionedId(entry.id, entry.version),
      ], toSlotId: DefaultSlots.dinnerId),
    ]);
    final result = await actions.deleteEntry(entry) as DiaryActionFailed;
    expect(result.reason, DiaryActionFailure.changed);
    expect(c.read(diaryActionsControllerProvider).hidden, isEmpty);
    expect((await view(c, today)).layout.entryCount, 1);
    expect(c.read(undoStackProvider).latest, isNull);
  });

  test('DY-022 PA4 pending outlives provider eviction; duplicate '
      'dropped; origin raw and version filtering', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1)]),
    ]);
    final c = setup(h);
    final sub = c.listen(dayViewProvider(today), (_, _) {});
    final entry = (await view(c, today)).raw.entries.single;
    final complete = Completer<ApplyResult>();
    var calls = 0;
    setApply(c, h, (change) {
      calls++;
      expect(change.origin, Origin.direct);
      final op = change.ops.single as DeleteEntries;
      expect(op.entries.single, VersionedId(entry.id, entry.version));
      return complete.future;
    });
    final actions = c.read(diaryActionsControllerProvider.notifier);
    final pending = actions.deleteEntry(entry);
    await c.pump();
    final hiddenView = c.read(dayViewProvider(today)).requireValue;
    expect(hiddenView.raw.entries, hasLength(1));
    expect(hiddenView.layout.entryCount, 0);
    expect(hiddenView.layout.totals, Nutrients.zero);
    actions
      ..onRaw(today.plusDays(-1), raw(today.plusDays(-1), []))
      ..onRaw(today, raw(today, [entry]));
    expect(c.read(diaryActionsControllerProvider).hidden, hasLength(1));
    expect(await actions.deleteEntry(entry), isA<DiaryActionUnchanged>());
    sub.close();
    await c.pump();
    expect(c.read(diaryActionsControllerProvider).pending, {entry.id});
    expect(calls, 1);
    complete.complete(const Rejected(InvalidOp('test')));
    expect(await pending, isA<DiaryActionFailed>());
    expect(c.read(diaryActionsControllerProvider).pending, isEmpty);
    expect(c.read(diaryActionsControllerProvider).hidden, isEmpty);
  });

  test(
    'DY-022 PA4 only origin emission without marked version clears hidden mark',
    () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      final c = setup(h);
      final entry = (await h.reads.day(today)).entries.single;
      final complete = Completer<ApplyResult>();
      setApply(c, h, (_) => complete.future);
      final actions = c.read(diaryActionsControllerProvider.notifier);
      final pending = actions.deleteEntry(entry);
      actions
        ..onRaw(today.plusDays(-1), raw(today.plusDays(-1), []))
        ..onRaw(today, raw(today, [entry]));
      expect(c.read(diaryActionsControllerProvider).hidden, hasLength(1));
      actions.onRaw(today, raw(today, []));
      expect(c.read(diaryActionsControllerProvider).hidden, isEmpty);
      complete.complete(
        const Rejected(RowNotFound(entity: 'diary_entries', id: 'missing')),
      );
      expect(
        (await pending as DiaryActionFailed).reason,
        DiaryActionFailure.removed,
      );
    },
  );

  testWidgets(
    'DY-022 PA4 forgotten marks swept at undo window plus 10 seconds',
    (tester) async {
      final h = DiaryHarness();
      late DiaryEntry entry;
      late ProviderContainer c;
      await tester.runAsync(() async {
        await h.apply([
          LogEntries([newEntry(1)]),
        ]);
        c = setup(h);
        entry = (await h.reads.day(today)).entries.single;
      });
      final complete = Completer<ApplyResult>();
      setApply(c, h, (_) => complete.future);
      final pending = c
          .read(diaryActionsControllerProvider.notifier)
          .deleteEntry(entry);
      complete.complete(
        Applied(
          changeSetId: fixtureId(99),
          inverse: InverseChangeSet(changeSetId: fixtureId(99), rows: []),
          events: [],
        ),
      );
      await tester.pump();
      await pending;
      h.clock.advance(const Duration(seconds: 15));
      await tester.pump(const Duration(seconds: 15));
      expect(c.read(diaryActionsControllerProvider).hidden, hasLength(1));
      h.clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(c.read(diaryActionsControllerProvider).hidden, isEmpty);
      c.dispose();
    },
  );

  test('DY-024 UX-013 rows: slots persist, groups start open, one '
      'expanded entry; own-day cleanup and slot move', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1), newEntry(2)]),
    ]);
    final c = setup(h);
    final data = await h.reads.day(today);
    final entry = data.entries.first;
    final state = c.read(diaryViewStateProvider.notifier);
    final layout = DayLayout.build(data.slots, data.groups, data.entries);
    expect(
      DayRows.of(layout, c.read(diaryViewStateProvider), isToday: true).length,
      5,
    );
    state
      ..toggleSlot(entry.slotId)
      ..toggleEntry(entry);
    var rows = DayRows.of(
      layout,
      c.read(diaryViewStateProvider),
      isToday: true,
    );
    expect(rows.whereType<SlotMacrosRow>(), hasLength(1));
    expect(rows.whereType<EntryRow>(), hasLength(2));
    expect(rows.whereType<EntryDetailsRow>().single.entry.id, entry.id);
    state
      ..onRaw(today, data)
      ..toggleSlot(entry.slotId)
      ..onRaw(today, data);
    expect(
      c.read(diaryViewStateProvider).expandedSlotIds,
      isNot(contains(entry.slotId)),
    );
    state
      ..toggleSlot(entry.slotId)
      ..toggleEntry(data.entries.last);
    expect(
      c.read(diaryViewStateProvider).expandedEntry!.id,
      data.entries.last.id,
    );
    state.toggleEntry(data.entries.last);
    expect(c.read(diaryViewStateProvider).expandedEntry, isNull);
    state
      ..toggleEntry(entry)
      ..onRaw(today.plusDays(-1), raw(today.plusDays(-1), []));
    expect(c.read(diaryViewStateProvider).expandedEntry, isNotNull);
    await c
        .read(diaryActionsControllerProvider.notifier)
        .moveEntry(entry, DefaultSlots.dinnerId);
    state.onRaw(today, await h.reads.day(today));
    expect(c.read(diaryViewStateProvider).expandedEntry, (
      date: today,
      id: entry.id,
    ));
    expect(
      c.read(diaryViewStateProvider).expandedSlotIds,
      contains(DefaultSlots.dinnerId),
    );
    state.onRaw(today, raw(today, []));
    expect(c.read(diaryViewStateProvider).expandedEntry, isNull);
    expect(
      c.read(diaryViewStateProvider).expandedSlotIds,
      contains(entry.slotId),
    );
    state.toggleSlot(entry.slotId);
    expect(
      c.read(diaryViewStateProvider).expandedSlotIds,
      isNot(contains(entry.slotId)),
    );
    final group = DishGroup(
      id: fixtureId(90),
      version: 1,
      name: 'Dish',
      localDate: today,
      slotId: entry.slotId,
    );
    final member = DiaryEntry(
      id: entry.id,
      version: entry.version,
      time: entry.time,
      localDate: today,
      slotId: entry.slotId,
      food: entry.food,
      amount: entry.amount,
      snapshot: entry.snapshot,
      dishGroupId: group.id,
    );
    final grouped = DayLayout.build(data.slots, [group], [member]);
    state
      ..toggleSlot(entry.slotId)
      ..toggleEntry(entry);
    rows = DayRows.of(grouped, c.read(diaryViewStateProvider), isToday: true);
    expect(rows.whereType<GroupHeaderRow>().single.expanded, isTrue);
    expect(rows.whereType<GroupMemberRow>().single.groupId, group.id);
    expect(rows.whereType<EntryDetailsRow>(), hasLength(1));
    state.toggleGroup(group.id);
    rows = DayRows.of(grouped, c.read(diaryViewStateProvider), isToday: true);
    expect(rows.whereType<GroupMemberRow>(), isEmpty);
    state.toggleGroup(group.id);
    expect(c.read(diaryViewStateProvider).collapsedGroupIds, isEmpty);
    final empty = DayRows.of(
      DayLayout.build(data.slots, [], []),
      c.read(diaryViewStateProvider),
      isToday: false,
    );
    expect(empty.whereType<EmptyHintRow>().single.isToday, isFalse);
  });
  test(
    'DY-022 hidden versions do not hide a newer row on another day',
    () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      final c = setup(h);
      final entry = (await h.reads.day(today)).entries.single;
      final complete = Completer<ApplyResult>();
      setApply(c, h, (_) => complete.future);
      final pending = c
          .read(diaryActionsControllerProvider.notifier)
          .deleteEntry(entry);
      final previous = today.plusDays(-1);
      await h.apply([
        MoveEntries([VersionedId(entry.id, entry.version)], toDate: previous),
      ]);
      final moved = await view(c, previous);
      expect(moved.raw.entries.single.version, greaterThan(entry.version));
      expect(moved.layout.entryCount, 1);
      expect(c.read(diaryActionsControllerProvider).hidden, hasLength(1));
      complete.complete(const Rejected(InvalidOp('test')));
      await pending;
    },
  );

  test(
    'DY-022 unexpected apply error still clears pending and hidden',
    () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      final c = setup(h);
      final entry = (await h.reads.day(today)).entries.single;
      setApply(c, h, (_) async => throw StateError('test'));
      await expectLater(
        c.read(diaryActionsControllerProvider.notifier).deleteEntry(entry),
        throwsStateError,
      );
      expect(c.read(diaryActionsControllerProvider).pending, isEmpty);
      expect(c.read(diaryActionsControllerProvider).hidden, isEmpty);
    },
  );
}
