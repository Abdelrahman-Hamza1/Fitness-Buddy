import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/ui/nutrition_summary.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/today/application/today_numbers_view.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../foods/presentation/support/search_screen_support.dart';
import '../../foods/presentation/support/sheet_support.dart';
import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));
final String _undo = lookupFbLocalizations(const Locale('en')).fbUndo;

/// Lets the database and the undo stack finish what a tap started.
/// A read starts on a fake timer and answers in real time, so a few rounds
/// (like `food_replace_test`).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _typeKcal(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(FbNumberPad), matching: find.text(d)),
    );
    await tester.pump();
  }
}

List<Override> _overrides(SheetRig rig) => [
  ...rig.overrides,
  diaryApplyProvider.overrideWithValue(rig.diary.applier.apply),
  idGeneratorProvider.overrideWithValue(rig.diary.ids),
];

Future<List<DiaryEntry>> _entries(WidgetTester tester, SheetRig rig) async =>
    (await tester.runAsync(() => rig.diary.reads.entriesOn(today)))!;

/// Opens the real search screen for a pushed [FoodSearchRoute], like the
/// router; [pop] closes the top screen.
final class _RouteNavigator implements AppNavigator {
  new(this.key);

  final GlobalKey<NavigatorState> key;
  final List<AppRoute> pushed = [];

  @override
  void push(AppRoute route) {
    pushed.add(route);
    if (route case FoodSearchRoute(
      :final date,
      :final slotId,
      :final replace,
    )) {
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FoodSearchScreen(date: date, slotId: slotId, replace: replace),
        ),
      );
    }
  }

  @override
  void pop() => key.currentState!.pop();

  @override
  void go(AppRoute route) => throw UnimplementedError();
}

/// A 700 kcal / 30 g protein estimate in lunch today, shown as its tile.
Future<DiaryEntry> _pumpEstimateTile(
  WidgetTester tester,
  SheetRig rig, {
  List<Override> extra = const [],
}) async {
  tester.view
    ..physicalSize = const Size(360, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(
    () => rig.diary.apply([
      LogEntries([
        NewDiaryEntry(
          id: fixtureId(1),
          when: .at(EntryTime(DateTime.utc(2026, 10, 17, 11), 0)),
          slotId: DefaultSlots.lunchId,
          food: const UserEstimate(kcal: 700, protein: 30).food(),
          amount: UserEstimate.amount,
        ),
      ]),
    ]),
  );
  final entry = (await _entries(tester, rig)).single;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [..._overrides(rig), ...extra],
      child: screenApp(
        Scaffold(
          body: DiaryEntryTile(
            entry: entry,
            slots: DefaultSlots.all,
            expanded: false,
          ),
        ),
        navigatorKey: rig.navigatorKey,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return entry;
}

Future<void> _openPopup(WidgetTester tester, DiaryEntry entry) async {
  await tester.tap(find.byKey(ValueKey('estimate-marker-${entry.id}')));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

void main() {
  testWidgets('AI-048 DY-005 food search estimate row prefills the name from '
      'the query; the sheet adds ~kcal with Undo (E1 B)', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._overrides(rig), searchOverride(FakeFoodSearch())],
        child: screenApp(
          const FoodSearchScreen(
            slotId: DefaultSlots.lunchId,
            initialQuery: 'shawarma plate',
          ),
          navigatorKey: rig.navigatorKey,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('food-search-scan')), findsOneWidget);
    expect(find.byKey(const ValueKey('food-search-estimate')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('food-search-estimate-query')));
    await tester.pumpAndSettle();
    final name = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('estimate-name')),
        matching: find.byType(EditableText),
      ),
    );
    expect(name.controller.text, 'shawarma plate');
    final submit = find.byKey(const ValueKey('estimate-submit'));
    expect(tester.widget<FbButton>(submit).onPressed, isNull);

    await _typeKcal(tester, '780');
    await tester.tap(submit);
    await _settle(tester);

    final logged = await _entries(tester, rig);
    expect(logged, hasLength(1));
    expect(logged.single.food.userEstimate, isTrue);
    expect(logged.single.food.names.en, 'shawarma plate');
    expect(logged.single.snapshot.kcal, 780);
    expect(logged.single.slotId, DefaultSlots.lunchId);
    expect(find.text(_undo), findsOneWidget);

    await tester.tap(find.text(_undo));
    await _settle(tester);
    expect(await _entries(tester, rig), isEmpty);
    rig.stack.dispose();
  });

  testWidgets('AI-032 tapping ~ on your estimate offers Edit and Swap for '
      'foods; the row shows ~ and only the given macros', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([
          NewDiaryEntry(
            id: fixtureId(1),
            when: .at(EntryTime(DateTime.utc(2026, 10, 17, 11), 0)),
            slotId: DefaultSlots.lunchId,
            food: const UserEstimate(kcal: 700, protein: 30).food(),
            amount: UserEstimate.amount,
          ),
        ]),
      ]),
    );
    final entry = (await _entries(tester, rig)).single;
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(rig),
        child: screenApp(
          Scaffold(
            body: DiaryEntryTile(
              entry: entry,
              slots: DefaultSlots.all,
              expanded: false,
            ),
          ),
          navigatorKey: rig.navigatorKey,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_l10n.approx(_l10n.diaryKcal(700))), findsOneWidget);
    expect(
      find.text(_l10n.estimateProtein('30')),
      findsOneWidget,
      reason: 'the given macro only',
    );

    await tester.tap(find.byKey(ValueKey('estimate-marker-${entry.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('estimate-popup-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('estimate-popup-swap')), findsOneWidget);

    // Edit opens the sheet prefilled.
    await tester.tap(find.byKey(const ValueKey('estimate-popup-edit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('estimate-submit')), findsOneWidget);
    rig.stack.dispose();
  });

  testWidgets('DY-005 popup Edit prefills the sheet (kcal, the given macro, '
      'unknowns empty) and saves the change on the same entry with Undo', (
    tester,
  ) async {
    final rig = SheetRig(catalogChoice(pita));
    final entry = await _pumpEstimateTile(tester, rig);
    await _openPopup(tester, entry);
    await tester.tap(find.byKey(const ValueKey('estimate-popup-edit')));
    await tester.pumpAndSettle();

    final kcal = tester.widget<FbAmountDisplay>(
      find.byKey(const ValueKey('estimate-kcal')),
    );
    expect(kcal.amount, '700');
    expect(_fieldText(tester, 'estimate-name'), isEmpty);
    expect(_fieldText(tester, 'estimate-protein'), '30');
    expect(_fieldText(tester, 'estimate-carbs'), isEmpty, reason: 'unknown');
    expect(_fieldText(tester, 'estimate-fat'), isEmpty, reason: 'unknown');

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('estimate-protein')),
        matching: find.byType(EditableText),
      ),
      '45',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('estimate-submit')));
    await _settle(tester);

    final edited = (await _entries(tester, rig)).single;
    expect(edited.id, entry.id);
    expect(edited.version, entry.version + 1);
    expect(edited.snapshot.kcal, 700);
    expect(edited.snapshot.protein, 45);
    expect(edited.food.known, {NutrientField.protein});
    await tester.tap(find.text(_undo));
    await _settle(tester);
    expect((await _entries(tester, rig)).single.snapshot.protein, 30);
    rig.stack.dispose();
  });

  testWidgets('A65 m8 UX-052 a dirty estimate asks before Back or a tap '
      'outside closes it: Keep editing keeps it, Discard writes nothing; a '
      'Save closes without asking', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    final entry = await _pumpEstimateTile(tester, rig);
    Finder protein() => find.descendant(
      of: find.byKey(const ValueKey('estimate-protein')),
      matching: find.byType(EditableText),
    );
    Future<void> openEdit() async {
      await _openPopup(tester, entry);
      await tester.tap(find.byKey(const ValueKey('estimate-popup-edit')));
      await tester.pumpAndSettle();
    }

    final submit = find.byKey(const ValueKey('estimate-submit'));
    await openEdit();
    await tester.enterText(protein(), '45');
    await tester.pumpAndSettle();

    // Back asks; Keep editing keeps the typed value.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_l10n.sheetDiscardMessage), findsOneWidget);
    await tester.tap(find.text(_l10n.personalFoodDiscardKeep));
    await tester.pumpAndSettle();
    expect(submit, findsOneWidget);
    expect(_fieldText(tester, 'estimate-protein'), '45');

    // A tap outside (the barrier) asks too; Discard closes, nothing written.
    await tester.tapAt(const Offset(180, 4));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.sheetDiscardMessage), findsOneWidget);
    await tester.tap(find.text(_l10n.personalFoodDiscardConfirm));
    await tester.pumpAndSettle();
    expect(submit, findsNothing);
    expect((await _entries(tester, rig)).single.snapshot.protein, 30);

    // Dirty again, Save: closes without asking and writes.
    await openEdit();
    await tester.enterText(protein(), '50');
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await _settle(tester);
    expect(find.text(_l10n.sheetDiscardMessage), findsNothing);
    expect(submit, findsNothing);
    expect((await _entries(tester, rig)).single.snapshot.protein, 50);
    rig.stack.dispose();
  });

  testWidgets('DY-005 popup Swap for foods: the estimate stays while '
      'searching and cancel writes nothing; picking a food replaces it in '
      'one change set and one Undo restores the estimate', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    final navigator = _RouteNavigator(rig.navigatorKey);
    rig.appNavigator = navigator;
    final entry = await _pumpEstimateTile(
      tester,
      rig,
      // The search opens twice: each open needs a fresh controller.
      extra: [
        foodSearchControllerProvider.overrideWith(
          () => FakeFoodSearch(recent: [rig.row]),
        ),
      ],
    );
    final before = (await tester.runAsync(rig.diary.state))!;

    // Swap, then back out of the search: nothing written.
    await _openPopup(tester, entry);
    await tester.tap(find.byKey(const ValueKey('estimate-popup-swap')));
    await tester.pumpAndSettle();
    expect(
      navigator.pushed.single,
      isA<FoodSearchRoute>().having(
        (r) => r.replace,
        'replace',
        VersionedId(entry.id, entry.version),
      ),
    );
    expect(find.byType(FoodSearchScreen), findsOneWidget);
    expect(await tester.runAsync(rig.diary.state), before);
    rig.navigatorKey.currentState!.pop();
    await _settle(tester);
    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(await tester.runAsync(rig.diary.state), before);

    // Swap again and pick a food: one write, the estimate is gone.
    await _openPopup(tester, entry);
    await tester.tap(find.byKey(const ValueKey('estimate-popup-swap')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pita bread, white'));
    await _settle(tester);
    await tester.tap(find.text('Use this food'));
    await _settle(tester);
    expect(find.byType(FoodSearchScreen), findsNothing);
    final swapped = (await _entries(tester, rig)).single;
    expect(swapped.id, entry.id);
    expect(swapped.version, entry.version + 1);
    expect(swapped.food.userEstimate, isFalse);
    expect(swapped.food.names.en, 'Pita bread, white');
    expect(swapped.food.known, EntryFood.allKnown);

    await tester.tap(find.text(_undo));
    await _settle(tester);
    final restored = (await _entries(tester, rig)).single;
    expect(restored.food.userEstimate, isTrue);
    expect(restored.snapshot.kcal, 700);
    expect(restored.food.known, {NutrientField.protein});
    rig.stack.dispose();
  });

  test('HM-001 Today shows ~ with an estimate and — for an unknown macro', () {
    final day = DiaryTotals.intake([
      DiaryEntry(
        id: fixtureId(1),
        version: 1,
        time: EntryTime(DateTime.utc(2026, 10, 17, 11), 0),
        localDate: today,
        slotId: DefaultSlots.lunchId,
        food: const UserEstimate(kcal: 700, protein: 30).food(),
        amount: UserEstimate.amount,
        snapshot: const UserEstimate(kcal: 700, protein: 30).food().per100,
      ),
    ]);
    final view = TodayNumbersView.of(day, null) as EatenNumbers;
    expect(view.estimated, isTrue);
    expect(view.eatenKcal, 700);
    expect(view.protein, 30);
    expect(view.carbs, isNull, reason: 'unknown, never 0');
    expect(view.approximate, containsAll([NutrientField.protein]));
  });

  testWidgets('D26 NutritionSummary shows — for an unknown macro', (
    tester,
  ) async {
    await tester.pumpWidget(
      screenApp(
        Scaffold(
          body: NutritionSummary(
            nutrients: const UserEstimate(kcal: 700, protein: 30).food().per100,
            known: const {NutrientField.protein},
          ),
        ),
      ),
    );
    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((t) => t.contains(_l10n.unknownValue), orElse: () => '');
    expect(text, isNotEmpty);
  });
}
