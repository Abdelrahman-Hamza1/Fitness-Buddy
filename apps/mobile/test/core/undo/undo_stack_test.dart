import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../changes/support/test_db.dart';

final _label = UndoLabel('entriesLogged', args: const {'count': 2});

/// Entry `n` (a UUIDv7-shaped id), applied at [at].
UndoEntry _entry(int n, DateTime at) => UndoEntry(
  id: '0199e3c2-5b1a-7c3d-8e4f-${n.toString().padLeft(12, '0')}',
  label: _label,
  inverse: InverseChangeSet(changeSetId: '$n', rows: const []),
  appliedAt: at,
);

/// A revert that records what it was given and answers [answer].
final class _Revert {
  final List<InverseChangeSet> calls = [];
  ApplyResult Function(InverseChangeSet) answer = (inverse) => Applied(
    changeSetId: 'r${inverse.changeSetId}',
    inverse: InverseChangeSet(changeSetId: 'x', rows: const []),
    events: const [],
  );

  Future<ApplyResult> call(InverseChangeSet inverse) async {
    calls.add(inverse);
    return answer(inverse);
  }
}

void main() {
  test('UX-030 UndoStack keeps 5, expires after 6 s on the ManualClock, undo '
      'twice → unknown', () async {
    final clock = ManualClock.millis(t0);
    final revert = _Revert();
    final stack = UndoStack(revert: revert.call, clock: clock);
    addTearDown(stack.dispose);
    for (var n = 1; n <= 7; n++) {
      stack.push(_entry(n, clock.nowUtc()));
    }
    expect(stack.entries.map((e) => e.id.substring(30)), [
      '000007',
      '000006',
      '000005',
      '000004',
      '000003',
    ]);
    expect(await stack.undo(_entry(1, clock.nowUtc()).id), UndoOutcome.unknown);

    final seventh = _entry(7, clock.nowUtc()).id;
    expect(await stack.undo(seventh), UndoOutcome.undone);
    expect(revert.calls.single.changeSetId, '7');
    expect(await stack.undo(seventh), UndoOutcome.unknown);
    expect(stack.latest?.id, _entry(6, clock.nowUtc()).id);

    clock.advance(const Duration(milliseconds: 5999));
    expect(stack.entries, hasLength(4));
    clock.advance(const Duration(milliseconds: 1));
    expect(stack.entries, isEmpty);
    expect(stack.latest, isNull);
    expect(await stack.undo(_entry(6, clock.nowUtc()).id), UndoOutcome.expired);
    expect(
      revert.calls,
      hasLength(1),
      reason: 'an expired undo writes nothing',
    );
  });

  test('a rejected revert is a conflict, and the entry is gone', () async {
    final clock = ManualClock.millis(t0);
    final revert = _Revert()
      ..answer = (_) => const Rejected(
        VersionConflict(entity: 'testNote', id: 'x', expected: 1, actual: 2),
      );
    final stack = UndoStack(revert: revert.call, clock: clock);
    addTearDown(stack.dispose);
    final entry = _entry(1, clock.nowUtc());
    stack.push(entry);
    expect(await stack.undo(entry.id), UndoOutcome.conflict);
    expect(await stack.undo(entry.id), UndoOutcome.unknown);
  });

  test('UX-030 with the real applier: undo restores, and revert pushes no '
      'new entry', () async {
    final h = Harness(testDatabase());
    const id = '0199e3c2-5b1a-7c3d-8e4f-000000000001';
    final stack = UndoStack(revert: h.applier.revert, clock: h.clock);
    addTearDown(stack.dispose);
    final applied = await h.applied([
      [addNote(h.db, id, 'one')],
    ]);
    final entry = stack.record(applied, _label);
    expect(entry.id, applied.changeSetId);
    expect(entry.appliedAt, h.clock.nowUtc());
    expect(stack.entries, [entry]);
    h.clock.advance(const Duration(seconds: 5));
    expect(await stack.undo(entry.id), UndoOutcome.undone);
    expect(stack.entries, isEmpty);
    expect((await h.row('test_notes', id))!['deleted_at'], isNotNull);
  });

  testWidgets('UX-030 latestUndoProvider emits the newest entry, then null '
      'after expiry', (tester) async {
    // testWidgets runs on fake time: pump(d) elapses d and fires timers.
    final clock = ManualClock.millis(t0);
    final revert = _Revert();
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(clock),
        undoStackProvider.overrideWith((ref) {
          final stack = UndoStack(
            revert: revert.call,
            clock: ref.watch(clockProvider),
          );
          ref.onDispose(stack.dispose);
          return stack;
        }),
      ],
    );
    final seen = <UndoEntry?>[];
    container.listen(
      latestUndoProvider,
      (_, next) => seen.add(next.value),
      fireImmediately: true,
    );
    await tester.pump();
    final stack = container.read(undoStackProvider);
    final first = _entry(1, clock.nowUtc());
    stack.push(first);
    await tester.pump();
    clock.advance(const Duration(seconds: 2));
    final second = _entry(2, clock.nowUtc());
    stack.push(second);
    await tester.pump();

    // The first entry's window ends while the second's is still open.
    clock.advance(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    expect(seen.last, second);

    clock.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(seen.whereType<UndoEntry>().toList(), [first, second]);
    expect(seen.last, isNull);

    // A timer that fires before the clock moves just waits again.
    final third = _entry(3, clock.nowUtc());
    stack.push(third);
    await tester.pump(const Duration(seconds: 7));
    expect(seen.last, third);
    clock.advance(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 7));
    expect(seen.last, isNull);
    container.dispose();
  });

  test('labels and entries print no args', () {
    expect('$_label', 'UndoLabel(entriesLogged)');
    expect(_label, UndoLabel('entriesLogged', args: const {'count': 2}));
    expect(
      _label.hashCode,
      UndoLabel('entriesLogged', args: const {'count': 2}).hashCode,
    );
    expect(_label == UndoLabel('entriesLogged'), isFalse);
    expect('${_entry(1, utcMillis(t0))}', contains('UndoLabel(entriesLogged)'));
  });

  test("a label's args are a copy and unmodifiable", () {
    final args = <String, Object>{'count': 2};
    final label = UndoLabel('entriesLogged', args: args);
    args['count'] = 3;
    expect(label.args, {'count': 2});
    expect(() => label.args['count'] = 4, throwsUnsupportedError);
  });
}
