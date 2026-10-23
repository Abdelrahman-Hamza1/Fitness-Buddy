import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/today/presentation/support/today_support.dart'
    show phoneApp;

const _id = '0199e3c2-5b1a-7c3d-8e4f-000000000001';

/// A stack holding one entry; its revert answers [answer].
UndoStack _stack(ManualClock clock, ApplyResult Function() answer) {
  final stack = UndoStack(revert: (_) async => answer(), clock: clock)
    ..push(
      UndoEntry(
        id: _id,
        label: UndoLabel('entryDeleted'),
        inverse: InverseChangeSet(changeSetId: _id, rows: const []),
        appliedAt: clock.nowUtc(),
      ),
    );
  addTearDown(stack.dispose);
  return stack;
}

Future<void> _show(WidgetTester tester, UndoStack stack) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [undoStackProvider.overrideWithValue(stack)],
      child: phoneApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showUndoFeedback(
                context,
                message: 'Deleted Food',
                undoEntryId: _id,
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Go'));
  // The snackbar slides in.
  await tester.pumpAndSettle();
}

void main() {
  final applied = Applied(
    changeSetId: 'r',
    inverse: InverseChangeSet(changeSetId: 'x', rows: const []),
    events: const [],
  );

  testWidgets('UX-030 D13 Undo undoes and says nothing more', (tester) async {
    final clock = ManualClock(DateTime.utc(2026, 10, 17, 12));
    final stack = _stack(clock, () => applied);
    await _show(tester, stack);
    expect(find.text('Deleted Food'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump();

    expect(stack.entries, isEmpty);
    expect(find.text("Couldn't undo, it was changed since."), findsNothing);
    expect(find.text('Too late to undo.'), findsNothing);
    stack.dispose();
  });

  testWidgets('D13 Undo after a conflicting change says "Can\'t undo: it '
      'changed since."', (tester) async {
    final clock = ManualClock(DateTime.utc(2026, 10, 17, 12));
    final stack = _stack(
      clock,
      () => const Rejected(
        VersionConflict(entity: 'diary_entry', id: 'x', expected: 1, actual: 2),
      ),
    );
    await _show(tester, stack);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't undo, it was changed since."), findsOneWidget);
    stack.dispose();
  });

  testWidgets('D13 Undo after the window says "Too late to undo."', (
    tester,
  ) async {
    final clock = ManualClock(DateTime.utc(2026, 10, 17, 12));
    final stack = _stack(clock, () => applied);
    await _show(tester, stack);

    // The snackbar is still on screen when the clock says the window is over.
    clock.advance(const Duration(seconds: 7));
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Too late to undo.'), findsOneWidget);
    stack.dispose();
  });
}
