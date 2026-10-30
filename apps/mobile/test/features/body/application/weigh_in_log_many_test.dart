import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/application/weigh_in_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/weigh_in_harness.dart';

void main() {
  late WeighInHarness h;
  late ProviderContainer c;

  setUp(() {
    h = WeighInHarness();
    c = ProviderContainer.test(overrides: h.overrides);
  });

  WeighInActions actions() => c.read(weighInActionsProvider.notifier);

  Future<int> outboxCount() async =>
      (await h.db
              .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
              .getSingle())
          .read<int>('n');

  List<WeighInDraft> history(int count) => [
    for (var i = 0; i < count; i++)
      weighInDraft(
        97 - i * 0.1,
        date: day17.plusDays(-7 * (count - i)),
        hour: 8,
      ),
  ];

  test('WB-001 UX-030 logMany applies the batch with one undo entry; undo '
      'tombstones every created row with a newer version and one new outbox '
      'row each; a refused row writes nothing; an undo after one of the rows '
      'was edited is rejected atomically', () async {
    final before = await h.state();
    final drafts = history(3);
    final outbox0 = await outboxCount();
    final outcome = await actions().logMany(drafts) as WeighInDone;
    expect(outcome.kind, WeighInKind.weighInsLogged);
    expect(outcome.args, {'count': 3});
    final stack = c.read(undoStackProvider);
    expect(stack.latest!.id, outcome.undoId);
    expect(
      stack.latest!.label,
      UndoLabel('weighInsLogged', args: const {'count': 3}),
    );
    final live = await h.live();
    expect(live, hasLength(3));
    expect(live.map((w) => w.draft).toSet(), drafts.toSet());
    expect(await outboxCount(), outbox0 + 3);
    expect(c.read(weighInActionsProvider), isEmpty);

    // Undo: every row a tombstone at version 2 with a newer HLC and the
    // undo origin, one new outbox row each (PA2, row_writer.dart).
    final applied = {
      for (final row in await h.db.select(h.db.weighIns).get())
        row.id: row.updatedHlc,
    };
    expect(await stack.undo(outcome.undoId), UndoOutcome.undone);
    expect(await h.live(), isEmpty);
    expect(await h.state(), before);
    final rows = await h.db.select(h.db.weighIns).get();
    expect(rows, hasLength(3));
    for (final row in rows) {
      expect(row.deletedAt, isNotNull);
      expect(row.version, 2);
      expect(row.updatedHlc.compareTo(applied[row.id]!), greaterThan(0));
      expect(row.origin, startsWith('undo:'));
    }
    expect(await outboxCount(), outbox0 + 6);

    // A refused row (in the future) refuses the whole batch.
    final raw = await h.raw();
    final future = WeighInDraft(
      time: EntryTime(harnessNow.add(const Duration(minutes: 6)), 180),
      input: const WeighInInput(97, MassUnit.kilogram),
    );
    final refused = await actions().logMany([...history(2), future]);
    expect((refused as WeighInFailed).reason, WeighInFailure.future);
    final invalid = await actions().logMany([
      ...history(2),
      weighInDraft(19.9),
    ]);
    expect((invalid as WeighInFailed).reason, WeighInFailure.invalid);
    expect(await h.raw(), raw);

    // An undo after one of the rows was edited is rejected atomically.
    final again = await actions().logMany(history(2)) as WeighInDone;
    final first = (await h.live()).first;
    await actions().update(first, weighInDraft(90, date: first.localDate));
    final edited = await h.raw();
    expect(await stack.undo(again.undoId), UndoOutcome.conflict);
    expect(await h.raw(), edited);
    expect(await h.live(), hasLength(2));
  });

  test('WB-001 logMany takes up to 500 rows in one change set', () async {
    final drafts = [
      for (var i = 0; i < 500; i++)
        weighInDraft(80, date: LocalDate(2020, 1, 1).plusDays(i), hour: 8),
    ];
    final outcome = await actions().logMany(drafts) as WeighInDone;
    expect(outcome.args, {'count': 500});
    expect(await h.live(), hasLength(500));
    expect(
      () => actions().logMany([...drafts, weighInDraft(80)]),
      throwsArgumentError,
    );
  });

  test('a double tap on Save adds the batch once', () async {
    final drafts = history(2);
    final first = actions().logMany(drafts);
    expect(c.read(weighInActionsProvider), {WeighInActions.logManyKey});
    expect(await actions().logMany(drafts), isA<WeighInPending>());
    expect(await first, isA<WeighInDone>());
    expect(await h.live(), hasLength(2));
  });
}
