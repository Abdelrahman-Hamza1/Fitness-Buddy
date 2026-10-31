import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/catalog/barcode_coverage.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/data/barcode_api.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../features/foods/presentation/support/personal_food_support.dart'
    show dbOf, settle, useWindow;
import '../helpers/pump_app.dart';
import 'support/acceptance_app.dart';
import 'support/hanging_network.dart';

const _ean = '4006381333931';
final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

/// The server's barcode endpoint: unreachable until [online].
final class _Server {
  bool online = false;
  final List<String> asked = [];

  Future<BarcodeApiResult> lookup(String code) async {
    asked.add(code);
    if (!online) return const BarcodeApiUnavailable();
    return BarcodeApiFound(
      OffProduct(
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
      ),
    );
  }
}

Future<void> _openScanner(WidgetTester tester, ProviderContainer c) async {
  c.read(appRouterProvider).push(const BarcodeScanRoute());
  await settle(tester);
  expect(find.byType(BarcodeScanScreen), findsOneWidget);
}

void main() {
  // covers: OF-02 (barcode half; the Buddy half, AI-047, is A23b's)
  testWidgets('OF-02 AT-005 a barcode scanned offline waits as pending; once '
      'online the next scanner visit looks it up and one tap logs it', (
    tester,
  ) async {
    useWindow(tester, width: 360, height: 800);
    final server = _Server();
    // Production wiring around the fakes: pack updates, online search and
    // notifications on; every other request hangs unanswered.
    final phone = TestPhone(
      onlineSearch: true,
      packUpdates: true,
      notifications: true,
    );
    final network = HangingNetwork();
    phone.adapter.respond = network.respond;
    final container = await pumpApp(
      tester,
      phone: phone,
      overrides: [
        ...acceptanceOverrides(),
        halalProvider.overrideWith((ref) => Stream.value(true)),
        // The app's own lookup chain (your foods, the pack, the coverage
        // counter); only the server's endpoint is the fake above.
        barcodeLookupProvider.overrideWith(
          (ref) => BarcodeLookup(
            personalByBarcode: ref
                .watch(personalFoodRepositoryProvider)
                .byBarcode,
            packByBarcode: ref.watch(foodCatalogRepositoryProvider).byBarcode,
            server: server.lookup,
            newId: ref.watch(idGeneratorProvider).next,
            count: ref.watch(barcodeCoverageProvider).add,
          ),
        ),
      ],
    );
    final db = dbOf(container);

    // Offline: the typed code is asked for, can't be answered, and waits.
    await _openScanner(tester, container);
    await tester.tap(find.byKey(const ValueKey('barcode-type-code')));
    await settle(tester);
    await tester.enterText(find.byType(TextField), _ean);
    await tester.tap(find.text(_l10n.barcodeLookUp));
    await settle(tester);
    expect(server.asked, [_ean]);
    var pending = await container.read(pendingScansProvider.future);
    expect(pending.single.code, _ean);
    expect(pending.single.state, PendingScanState.waiting);
    expect(find.byType(FoodSheet), findsNothing);

    // Back online; the next visit to the scanner processes the list.
    server.online = true;
    container.read(appRouterProvider).go(const TodayRoute());
    await settle(tester);
    await _openScanner(tester, container);
    pending = await container.read(pendingScansProvider.future);
    expect(pending.single.state, PendingScanState.ready);

    // Ready: one tap opens it, one tap on Add logs it (UX-006).
    await tester.tap(find.byKey(const ValueKey('pending-$_ean')));
    await settle(tester);
    expect(find.byType(FoodSheet), findsOneWidget);
    await tester.tap(find.text(_l10n.foodSheetAdd));
    await settle(tester);
    final (foods, entries) = (await tester.runAsync(() async {
      final foods = await (db.select(
        db.personalFoods,
      )..where((t) => t.deletedAt.isNull())).get();
      final entries = await (db.select(
        db.diaryEntries,
      )..where((t) => t.deletedAt.isNull())).get();
      return (foods, entries);
    }))!;
    expect(foods.single.barcodesJson, contains(_ean));
    expect(entries.single.foodId, foods.single.id);
    // Logged, it leaves the list.
    expect(await container.read(pendingScansProvider.future), isEmpty);
    expect(network.answered, 0, reason: 'nothing waited for the network');
    network.failAll();
    await unmountApp(tester, container);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
