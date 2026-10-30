import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/barcode_coverage.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/data/barcode_api.dart';
import 'package:fb_mobile/features/foods/data/pending_scans_store.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../diary/support/diary_fixtures.dart' show fixtureId;
import '../presentation/food_add_flow_test.dart' show settleWrites;
import '../presentation/support/search_screen_support.dart';
import '../presentation/support/sheet_support.dart';

const _ean = '4006381333931';
final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

/// Pops the app's navigator like the router; records pushes.
final class _Navigator implements AppNavigator {
  new(this.key);
  final GlobalKey<NavigatorState> key;
  final pushed = <AppRoute>[];
  int pops = 0;

  @override
  void pop() {
    pops++;
    key.currentState!.pop();
  }

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) => pushed.add(route);
}

BarcodeLookup _lookup(BarcodeOutcome Function(String code) answer) =>
    BarcodeLookup(
      personalByBarcode: (_) async => null,
      packByBarcode: (code) async => switch (answer(code)) {
        BarcodeFound(:final choice) when choice.catalogFood != null =>
          choice.catalogFood,
        _ => null,
      },
      server: (code) async => switch (answer(code)) {
        BarcodeFound(:final choice) when choice.pendingCreate != null =>
          BarcodeApiFound(_offFor(code)),
        BarcodeNotFound() => const BarcodeApiNotFound(),
        _ => const BarcodeApiUnavailable(),
      },
      newId: () => fixtureId(950),
      count: (_) async {},
    );

OffProduct _offFor(String code) => OffProduct(
  code: code,
  isOff: true,
  complete: true,
  perMl: false,
  name: 'Synthetic halawa',
  brand: 'Synthetic Brand',
  kcal: 520,
  protein: 12,
  carbs: 50,
  fat: 30,
  fiber: 3,
  servingQuantity: 30,
);

Future<_Navigator> _pump(
  WidgetTester tester,
  SheetRig rig,
  BarcodeLookup lookup, {
  List<String> pending = const [],
  PendingScanState state = PendingScanState.waiting,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = PendingScansStore(SharedPreferencesAsync());
  final now = rig.diary.clock.nowUtc().millisecondsSinceEpoch;
  await store.write([
    for (final code in pending)
      PendingScan(code: code, scannedAtMs: now, state: state, name: 'Pita'),
  ]);
  final navigator = _Navigator(rig.navigatorKey);
  // The rig's navigator can't push; this one records pushes.
  rig.appNavigator = navigator;
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...rig.overrides,
        barcodeCameraEnabledProvider.overrideWithValue(false),
        halalProvider.overrideWith((ref) => Stream.value(true)),
        pendingScansStoreProvider.overrideWith((ref) async => store),
        barcodeLookupProvider.overrideWithValue(lookup),
      ],
      child: screenApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BarcodeScanScreen(),
                ),
              ),
              child: const Text('Today'),
            ),
          ),
        ),
        navigatorKey: rig.navigatorKey,
      ),
    ),
  );
  await tester.tap(find.text('Today'));
  await settleWrites(tester);
  return navigator;
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  await tester.tap(find.byKey(const ValueKey('barcode-type-code')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), code);
  await tester.tap(find.text(_l10n.barcodeLookUp));
  await settleWrites(tester);
}

Future<List<PendingScan>> _stored(WidgetTester tester) async => (await tester
    .runAsync(() => PendingScansStore(SharedPreferencesAsync()).read()))!;

void main() {
  testWidgets('FD-030 T17 UX-006 a typed barcode opens the product in the '
      'food sheet; one tap on Add logs it, closes the scanner and offers '
      'Undo', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    final navigator = await _pump(
      tester,
      rig,
      _lookup(
        (_) => BarcodeFound(
          rig.choice,
          const ScannedProduct(code: _ean, source: ScannedSource.pack),
        ),
      ),
    );
    await _typeCode(tester, _ean);
    expect(find.byType(FoodSheet), findsOneWidget);

    await tester.tap(find.text(_l10n.foodSheetAdd));
    await settleWrites(tester);
    expect(find.byType(FoodSheet), findsNothing);
    expect(find.byType(BarcodeScanScreen), findsNothing);
    expect(navigator.pops, 1);
    expect(find.byType(SnackBar), findsOneWidget);
    final db = rig.diary.db;
    final live = (await tester.runAsync(
      () => (db.select(
        db.diaryEntries,
      )..where((t) => t.deletedAt.isNull())).get(),
    ))!;
    expect(live.single.foodId, pita.id);
    rig.stack.dispose();
  });

  testWidgets('review: an Open Food Facts product → Add saves the food and '
      'the entry; Undo removes both', (tester) async {
    final draft = draftFromOff(_offFor(_ean))!;
    final scanned = scannedChoice(fixtureId(950), draft);
    final rig = SheetRig(scanned);
    await _pump(
      tester,
      rig,
      _lookup(
        (_) => BarcodeFound(
          scanned,
          const ScannedProduct(code: _ean, source: ScannedSource.openFoodFacts),
        ),
      ),
    );
    await _typeCode(tester, _ean);
    await tester.tap(find.text(_l10n.foodSheetAdd));
    await settleWrites(tester);
    final db = rig.diary.db;
    Future<(int, int)> live() async => (await tester.runAsync(() async {
      final foods = await (db.select(
        db.personalFoods,
      )..where((t) => t.deletedAt.isNull())).get();
      final entries = await (db.select(
        db.diaryEntries,
      )..where((t) => t.deletedAt.isNull())).get();
      return (foods.length, entries.length);
    }))!;
    expect(await live(), (1, 1));

    await tester.tap(find.byType(SnackBarAction));
    await settleWrites(tester);
    expect(await live(), (0, 0));
    rig.stack.dispose();
  });

  testWidgets('review fix 3: dismissing the sheet of a ready scan keeps it '
      'waiting in the list', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    await _pump(
      tester,
      rig,
      _lookup(
        (_) => BarcodeFound(
          rig.choice,
          const ScannedProduct(code: _ean, source: ScannedSource.pack),
        ),
      ),
      pending: const [_ean],
      state: PendingScanState.ready,
    );
    await tester.tap(find.byKey(const ValueKey('pending-$_ean')));
    await settleWrites(tester);
    expect(find.byType(FoodSheet), findsOneWidget);
    await tester.tapAt(const Offset(180, 20));
    await settleWrites(tester);
    expect(find.byType(FoodSheet), findsNothing);
    expect((await _stored(tester)).single.code, _ean);
    rig.stack.dispose();
  });

  testWidgets('review fix 3: "Add it yourself" keeps the scan until the food '
      'is saved', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    final navigator = await _pump(
      tester,
      rig,
      _lookup(BarcodeNotFound.new),
      pending: const [_ean],
    );
    // Opening the scanner retried the waiting scan: it's now "not found",
    // and tapping it opens the form ("Add it yourself").
    await tester.tap(find.byKey(const ValueKey('pending-$_ean')));
    await settleWrites(tester);
    expect(navigator.pushed.single, isA<NewFoodFromScanRoute>());
    // The form was opened (and, here, never saved): the scan stays.
    final stored = await _stored(tester);
    expect(stored.single.code, _ean);
    expect(stored.single.state, PendingScanState.notFound);
    rig.stack.dispose();
  });

  testWidgets('review fix 4: an ambiguous typed code asks EAN-8 or UPC-E', (
    tester,
  ) async {
    final asked = <String>[];
    final rig = SheetRig(catalogChoice(pita));
    await _pump(
      tester,
      rig,
      BarcodeLookup(
        personalByBarcode: (_) async => null,
        packByBarcode: (_) async => null,
        server: (code) async {
          asked.add(code);
          return const BarcodeApiNotFound();
        },
        newId: () => fixtureId(951),
        count: (_) async {},
      ),
    );
    await _typeCode(tester, '01000009');
    expect(find.text(_l10n.barcodeWhichKind), findsOneWidget);
    await tester.tap(find.text(_l10n.barcodeKindUpcE));
    await settleWrites(tester);
    expect(asked, [Gtin.normalize('010000000009')]);
    rig.stack.dispose();
  });

  test('A28a D12 the coverage counter adds up on the device', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final coverage = BarcodeCoverage(SharedPreferencesAsync());
    await coverage.add(BarcodeCoverageKind.found);
    await coverage.add(BarcodeCoverageKind.found);
    await coverage.add(BarcodeCoverageKind.notFound);
    expect(await coverage.read(), (found: 2, incomplete: 0, notFound: 1));
  });
}
