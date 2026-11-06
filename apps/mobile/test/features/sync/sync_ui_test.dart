import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/sync/application/sync_view.dart';
import 'package:fb_mobile/features/sync/sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart' show phoneApp;

const _now = 1760351234567;

SyncView _view({
  int pending = 0,
  int parked = 0,
  SyncProblem problem = SyncProblem.none,
  int? oldest,
  bool running = false,
}) => SyncView(
  enabled: true,
  running: running,
  restoring: false,
  restoredRows: 0,
  problem: problem,
  pending: pending,
  parked: parked,
  lastSuccessMs: _now - 60000,
  oldestPendingMs: oldest,
  nowMs: _now,
);

Future<void> _pump(WidgetTester tester, Widget child, SyncView view) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [syncViewProvider.overrideWithValue(view)],
      child: phoneApp(Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  // covers: AC-013, UX-053
  testWidgets('Today shows the sync line only when something waits too long '
      'or is wrong', (tester) async {
    await _pump(tester, const SyncTodayLine(), _view());
    expect(find.byKey(const ValueKey('today-sync-line')), findsNothing);
    await _pump(
      tester,
      const SyncTodayLine(key: ValueKey(2)),
      _view(pending: 2, oldest: _now - 30000),
    );
    expect(
      find.byKey(const ValueKey('today-sync-line')),
      findsNothing,
      reason: 'a fresh change syncs quietly',
    );
    await _pump(
      tester,
      const SyncTodayLine(key: ValueKey(3)),
      _view(pending: 2, oldest: _now - 30000, problem: SyncProblem.offline),
    );
    expect(find.byKey(const ValueKey('today-sync-line')), findsOneWidget);
  });

  testWidgets('#242 a 426 says "update the app to sync" on Today', (
    tester,
  ) async {
    await _pump(
      tester,
      const SyncTodayLine(),
      _view(
        pending: 1,
        oldest: _now - 30000,
        problem: SyncProblem.updateRequired,
      ),
    );
    expect(
      find.text('Update the app to sync. Your changes are kept on this phone.'),
      findsOneWidget,
    );
  });

  testWidgets('the sync sheet shows the state, Try again for parked '
      'changes and Sync now (A65 m16: no pull-to-refresh)', (tester) async {
    await _pump(tester, const SyncSheetBody(), _view(pending: 1, parked: 2));
    expect(find.byKey(const ValueKey('sync-sheet-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sheet-parked')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-now')), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('A65 m16 a running sync shows Sync now busy and disabled', (
    tester,
  ) async {
    await _pump(
      tester,
      const SyncSheetBody(),
      _view(pending: 1, running: true),
    );
    final button = tester.widget<FbButton>(
      find.byKey(const ValueKey('sync-now')),
    );
    expect(button.busy, isTrue);
    expect(button.onPressed, isNull);
  });

  testWidgets('earlier versions list each version with Restore', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncViewProvider.overrideWithValue(_view()),
          earlierVersionsProvider('diaryEntry', 'x').overrideWith(
            (ref) async => const [
              EarlierVersion(
                hlc: '1760351230000-00000-00000000-0000-7000-8000-000000000002',
                wallMs: 1760351230000,
                deleted: false,
                payload: {'nameEn': 'Rice', 'kcal': 130},
              ),
            ],
          ),
        ],
        child: phoneApp(
          const Scaffold(
            body: EarlierVersionsBody(entity: 'diaryEntry', id: 'x'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(EarlierVersionsBody), findsOneWidget);
    expect(
      find.byType(TextButton).evaluate().length +
          find.byType(OutlinedButton).evaluate().length +
          find.byType(FilledButton).evaluate().length,
      greaterThanOrEqualTo(1),
    );
  });

  testWidgets('A57 A49 T-R4 earlier versions: rows while loading, Try again '
      'after a failure, Sign in when signed out', (tester) async {
    Exception? failure = const FormatException('failed');
    final waiting = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          syncViewProvider.overrideWithValue(_view()),
          earlierVersionsProvider('diaryEntry', 'x').overrideWith((ref) async {
            await waiting.future;
            if (failure case final error?) throw error;
            return const <EarlierVersion>[];
          }),
        ],
        child: phoneApp(
          const Scaffold(
            body: EarlierVersionsBody(entity: 'diaryEntry', id: 'x'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('versions-loading')), findsOneWidget);
    waiting.complete();
    await tester.pump();
    await tester.pump();
    final failed = find.byKey(const ValueKey('versions-failed'));
    expect(failed, findsOneWidget);
    failure = EarlierVersionsFailure.signedOut;
    await tester.tap(
      find.descendant(of: failed, matching: find.byType(TextButton)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('versions-signed-out')), findsOneWidget);
  });

  testWidgets("G7 #236 the editors' Earlier versions button shows only "
      'while sync is on', (tester) async {
    SyncView off() => const SyncView(
      enabled: false,
      running: false,
      restoring: false,
      restoredRows: 0,
      problem: SyncProblem.none,
      pending: 0,
      parked: 0,
      lastSuccessMs: null,
      oldestPendingMs: null,
      nowMs: _now,
    );
    await _pump(
      tester,
      const EarlierVersionsButton(entity: 'weighIn', id: 'w'),
      off(),
    );
    expect(find.text('Earlier versions'), findsNothing);

    await _pump(
      tester,
      const EarlierVersionsButton(key: ValueKey(2), entity: 'weighIn', id: 'w'),
      _view(),
    );
    expect(find.text('Earlier versions'), findsOneWidget);
  });
}
