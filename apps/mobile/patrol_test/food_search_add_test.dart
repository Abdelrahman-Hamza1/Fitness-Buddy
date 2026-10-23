import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

const _pita = 'usda:pita_white';

/// Pumps in real time until [done] holds; fails with [reason] after
/// [timeout]. Local work only (database, pack), so the bounds are generous
/// for a slow emulator but nothing waits on a network.
Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() done,
  String reason, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > timeout) fail('Timed out waiting for $reason');
    await tester.pump(const Duration(milliseconds: 100));
  }
  // One more frame so the widgets reflect the state that satisfied [done].
  await tester.pump(const Duration(milliseconds: 100));
}

/// The same, for a condition that needs an `await` (the database).
Future<void> _waitUntilAsync(
  WidgetTester tester,
  Future<bool> Function() done,
  String reason, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!await done()) {
    if (watch.elapsed > timeout) fail('Timed out waiting for $reason');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The live (not undone) diary entries of the pita food around today, read
/// through the app's diary repository.
Future<List<DiaryEntry>> _livePitaEntries(ProviderContainer container) async {
  final today = EntryTime.now(container.read(clockProvider)).localDate;
  final entries = await container
      .read(diaryRepositoryProvider)
      .watchEntries(today.plusDays(-1), today.plusDays(1))
      .first;
  return [
    for (final e in entries)
      if (e.food.ref.id == _pita) e,
  ];
}

/// A07 WP5 on the device: the exit criterion of D13 through the real app and
/// the real router. Nothing is faked; no API is reachable (as in `app_test`),
/// so the food search runs on the bundled pack and the diary on the local
/// database, which is what "airplane mode" means for this flow (OF-01).
void main() {
  patrolTest('OF-01 FD-020 FD-022 AI-048 pita by EN, AR and Arabizi gives Pita '
      'bread, white first and once, add 1 loaf, it is in the diary, Undo '
      'removes it', ($) async {
    final config = AppConfig.fromEnvironment();
    final container = ProviderContainer(overrides: appOverrides(config));
    addTearDown(container.dispose);
    final tester = $.tester;

    await $.pumpWidgetAndSettle(
      UncontrolledProviderScope(
        container: container,
        child: const FitnessBuddyApp(),
      ),
    );
    expect($(TodayScreen), findsOneWidget);

    // The pack installs in the background after the first frame; wait for
    // it before typing, as the search would otherwise show history only.
    final db = container.read(appDatabaseProvider);
    await _waitUntilAsync(
      tester,
      db.isCatalogAttached,
      'the catalog pack to attach',
      timeout: const Duration(seconds: 60),
    );

    // Earlier runs on the same device leave tombstones (and, after a failed
    // run, maybe a live entry): compare against what is there now.
    final before = await _livePitaEntries(container);
    final knownIds = {
      for (final row in await db.select(db.diaryEntries).get()) row.id,
    };

    // Today's input bar opens the search through the real go_router.
    await $('Search for a food…').tap(settlePolicy: SettlePolicy.trySettle);
    await _waitUntil(
      tester,
      () => find.byType(FoodSearchScreen).evaluate().isNotEmpty,
      'the food search screen',
    );

    for (final query in ['pita', 'خبز عربي', 'khubz arabi']) {
      await tester.enterText(find.byType(TextField), query);
      List<FoodSearchRow> rows() =>
          container.read(foodSearchControllerProvider).results?.rows ??
          const [];
      await _waitUntil(tester, () {
        final state = container.read(foodSearchControllerProvider);
        return state.resultsFor?.trim() == query &&
            rows().isNotEmpty &&
            rows().first.choice.ref.id == _pita;
      }, 'Pita bread, white to be the first result of "$query"');

      // The state: first, and exactly once.
      expect(rows().first.choice.ref.id, _pita, reason: query);
      expect(
        rows().where((r) => r.choice.ref.id == _pita),
        hasLength(1),
        reason: query,
      );
      // The screen: the first row shown is Pita bread, white, and its name
      // appears once among the visible rows.
      final shown = tester
          .widgetList<FoodResultRow>(find.byType(FoodResultRow))
          .toList();
      expect(shown.first.row.choice.ref.id, _pita, reason: query);
      expect(
        shown.where((r) => r.row.choice.ref.id == _pita),
        hasLength(1),
        reason: query,
      );
      expect(find.text('Pita bread, white'), findsOneWidget, reason: query);
    }

    // Set the unit and amount explicitly, independent of saved history.
    await tester.tap(find.byType(FoodResultRow).first);
    await _waitUntil(
      tester,
      () =>
          find.byType(FoodSheet).evaluate().isNotEmpty &&
          find.text('Add').evaluate().isNotEmpty,
      'the food sheet to load',
    );
    final picker = tester.widget<FbUnitPicker>(find.byType(FbUnitPicker));
    final loafLabel = picker.units.singleWhere((u) => u.id == 'loaf').label;
    await tester.tap(
      find.descendant(
        of: find.byType(FbUnitPicker),
        matching: find.text(loafLabel),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    await tester.ensureVisible(find.text('1'));
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pump();
    final add = find.text('Add');
    expect(add, findsOneWidget);
    await tester.ensureVisible(add);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(add);

    // The sheet and the search close under the real router; Today shows the
    // undo snackbar (the WP4 note: appNavigatorProvider.pop() and the
    // snackbar on the root context).
    await _waitUntil(
      tester,
      () =>
          find.byType(FoodSearchScreen).evaluate().isEmpty &&
          find.byType(FoodSheet).evaluate().isEmpty &&
          find
              .textContaining('Added Pita bread, white to ')
              .evaluate()
              .isNotEmpty,
      'the search to close and the undo snackbar to show',
    );
    expect($(TodayScreen), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // The entry is in the diary: 1 loaf, 60 g, the catalog pita.
    late List<DiaryEntry> added;
    await _waitUntilAsync(tester, () async {
      added = [
        for (final e in await _livePitaEntries(container))
          if (!before.any((b) => b.id == e.id)) e,
      ];
      return added.isNotEmpty;
    }, 'the new entry in the diary');
    expect(added, hasLength(1));
    final entry = added.single;
    expect(entry.food.ref.kind, FoodRefKind.catalog);
    expect(entry.food.ref.id, _pita);
    expect(entry.amount.input.amount, 1);
    expect(entry.amount.input.unitCode, 'loaf');
    expect(entry.amount.amount, 60);
    expect(knownIds, isNot(contains(entry.id)));

    // Undo: gone from the diary, tombstoned (not deleted) in the table.
    await tester.tap(find.text('Undo'));
    await _waitUntilAsync(
      tester,
      () async =>
          !(await _livePitaEntries(container)).any((e) => e.id == entry.id),
      'Undo to remove the entry',
    );
    final row = await (db.select(
      db.diaryEntries,
    )..where((t) => t.id.equals(entry.id))).getSingle();
    expect(row.deletedAt, isNotNull);
    expect(await _livePitaEntries(container), hasLength(before.length));
  }, timeout: const Timeout(Duration(minutes: 4)));
}
