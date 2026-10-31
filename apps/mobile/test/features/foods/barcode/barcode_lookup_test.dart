import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:fb_mobile/features/foods/data/barcode_api.dart';
import 'package:fb_mobile/features/foods/data/pending_scans_store.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../data/personal_food_harness.dart';
import '../presentation/support/sheet_support.dart' show pita;

/// A valid EAN-13 and its UPC-A twin.
const _ean = '4006381333931';
const _upcA = '036000291452';

OffProduct _off({
  String code = _ean,
  String? name = 'Synthetic halawa',
  double? kcal = 520,
  double? protein = 12,
  double? carbs = 50,
  double? fat = 30,
  double? fiber = 3,
  double? serving = 30,
  String? ingredients,
  List<String> labels = const [],
  bool checkLabel = false,
}) => OffProduct(
  code: code,
  isOff: true,
  complete: [kcal, protein, carbs, fat, fiber].every((v) => v != null),
  perMl: false,
  name: name,
  brand: 'Synthetic Brand',
  kcal: kcal,
  protein: protein,
  carbs: carbs,
  fat: fat,
  fiber: fiber,
  servingQuantity: serving,
  ingredients: ingredients,
  labels: labels,
  checkLabel: checkLabel,
);

final class _Ports {
  PersonalFood? personal;
  CatalogFood? pack;
  BarcodeApiResult server = const BarcodeApiNotFound();
  final calls = <String>[];

  /// When set, the server answers only once it completes.
  Completer<void>? hold;
  final asked = Completer<void>();
  final counted = <BarcodeCoverageKind>[];
  var _next = 0;

  BarcodeLookup lookup() => BarcodeLookup(
    personalByBarcode: (code) async {
      calls.add('personal $code');
      return personal;
    },
    packByBarcode: (code) async {
      calls.add('pack $code');
      return pack;
    },
    server: (code) async {
      calls.add('server $code');
      if (!asked.isCompleted) asked.complete();
      await hold?.future;
      return server;
    },
    newId: () => fixtureId(900 + _next++),
    count: (kind) async => counted.add(kind),
  );
}

void main() {
  group('A28a chain (07 §7): personal → pack → server', () {
    test(
      'a personal food with the barcode wins; nothing else is asked',
      () async {
        final ports = _Ports()
          ..personal = PersonalFood(
            id: fixtureId(1),
            version: 1,
            draft: PersonalFoodDraft(
              names: FoodNames('Halawa'),
              per100: Nutrients(
                kcal: 500,
                protein: 10,
                carbs: 50,
                fat: 30,
                fiber: 2,
              ),
              barcodes: [_upcA],
            ),
          );
        final outcome = await ports.lookup().lookup(_upcA);
        expect(outcome, isA<BarcodeFound>());
        final found = outcome as BarcodeFound;
        expect(found.choice.pendingCreate, isNull);
        expect(found.choice.ref, FoodRef.personal(fixtureId(1)));
        expect(found.product.source, ScannedSource.personal);
        expect(ports.calls, ['personal 0$_upcA']);
        expect(ports.counted, [BarcodeCoverageKind.found]);
      },
    );

    test('the offline pack comes before the server', () async {
      final ports = _Ports()..pack = pita;
      final outcome = await ports.lookup().lookup(_ean);
      expect((outcome as BarcodeFound).choice.catalogFood, pita);
      expect(ports.calls, ['personal $_ean', 'pack $_ean']);
    });

    test(
      'a complete OFF product becomes a not-yet-saved personal food',
      () async {
        final ports = _Ports()..server = BarcodeApiFound(_off());
        final outcome = await ports.lookup().lookup(_ean) as BarcodeFound;
        final draft = outcome.choice.pendingCreate!;
        expect(draft.createdFrom, 'off');
        expect(draft.barcodes, [_ean]);
        expect(draft.brand, 'Synthetic Brand');
        expect(draft.per100.kcal, 520);
        expect(draft.servings.single.amount, 30);
        // FD-022: a never-logged scan defaults to one serving.
        expect(outcome.choice.defaultPortion().unitCode, 'serving');
        expect(outcome.product.source, ScannedSource.openFoodFacts);
        expect(outcome.product.fiberMissing, isFalse);
        expect(ports.counted, [BarcodeCoverageKind.found]);
      },
    );

    test('the check-the-label flag reaches the product header', () async {
      final ports = _Ports()..server = BarcodeApiFound(_off(checkLabel: true));
      final outcome = await ports.lookup().lookup(_ean) as BarcodeFound;
      expect(outcome.product.checkLabel, isTrue);
      final plain = _Ports()..server = BarcodeApiFound(_off());
      expect(
        ((await plain.lookup().lookup(
          _ean,
        )) as BarcodeFound).product.checkLabel,
        isFalse,
      );
    });

    test(
      'missing fiber logs as 0 with a note and counts as incomplete',
      () async {
        final ports = _Ports()..server = BarcodeApiFound(_off(fiber: null));
        final outcome = await ports.lookup().lookup(_ean) as BarcodeFound;
        expect(outcome.choice.pendingCreate!.per100.fiber, 0);
        expect(outcome.product.fiberMissing, isTrue);
        expect(ports.counted, [BarcodeCoverageKind.incomplete]);
      },
    );

    test(
      'a missing core value, no name or impossible values need the form',
      () async {
        for (final off in [
          _off(fat: null),
          _off(name: null),
          _off(kcal: 900, protein: 90, carbs: 90, fat: 90),
        ]) {
          final ports = _Ports()..server = BarcodeApiFound(off);
          final outcome = await ports.lookup().lookup(_ean);
          expect(outcome, isA<BarcodeIncomplete>());
          final prefill = (outcome as BarcodeIncomplete).prefill;
          expect(prefill.code, _ean);
          expect(prefill.servingQuantity, 30);
        }
      },
    );

    test(
      'not found counts; unavailable waits uncounted; junk is invalid',
      () async {
        final ports = _Ports();
        expect(await ports.lookup().lookup(_ean), isA<BarcodeNotFound>());
        expect(ports.counted, [BarcodeCoverageKind.notFound]);
        ports.server = const BarcodeApiUnavailable();
        expect(await ports.lookup().lookup(_ean), isA<BarcodeWaiting>());
        expect(ports.counted, [BarcodeCoverageKind.notFound]);
        ports.calls.clear();
        expect(
          await ports.lookup().lookup('4006381333932'),
          isA<BarcodeInvalid>(),
        );
        expect(ports.calls, isEmpty);
      },
    );

    test('UPC-E is expanded before the lookup', () async {
      final ports = _Ports();
      await ports.lookup().lookup('04252614', upcE: true);
      expect(ports.calls.last, 'server 0042100005264');
    });

    test(
      'review fix 4: a typed code valid as EAN-8 and UPC-E is ambiguous',
      () {
        expect(BarcodeLookup.typedReadings('01000009'), [
          TypedReading.gtin,
          TypedReading.upcE,
        ]);
        expect(Gtin.expandUpcE('01000009'), '010000000009');
        expect(BarcodeLookup.typedReadings('96385074'), [TypedReading.gtin]);
        expect(BarcodeLookup.typedReadings('0425261'), [TypedReading.upcE]);
        expect(BarcodeLookup.typedReadings('12'), isEmpty);
      },
    );

    test('FD-081 halal flags come from the ingredients and tags', () async {
      final ports = _Ports()
        ..server = BarcodeApiFound(
          _off(ingredients: 'Sugar, gelatine, pork fat', labels: ['en:halal']),
        );
      final outcome = await ports.lookup().lookup(_ean) as BarcodeFound;
      expect(outcome.product.halal, {HalalFlag.pork});
    });
  });

  group('A28a D8 logging a scanned product', () {
    test('one change set saves the food and logs it; Undo removes both; the '
        'next scan finds it locally', () async {
      final h = PersonalHarness();
      addTearDown(h.db.close);
      final clock = ManualClock(DateTime.utc(2026, 10, 23, 12));
      final undo = UndoStack(revert: h.applier.revert, clock: clock);
      addTearDown(undo.dispose);
      final ports = _Ports()..server = BarcodeApiFound(_off(code: '0$_upcA'));
      final found = await ports.lookup().lookup(_upcA) as BarcodeFound;
      final result = await LogFood(
        apply: h.applier.apply,
        undoStack: undo,
        clock: clock,
        ids: SequenceIdGenerator(),
      )(choice: found.choice, input: Quantity(1, 'serving'), date: today);
      expect(result, isA<FoodLogged>());

      final repo = PersonalFoodRepository(h.db);
      final saved = await repo.byBarcode(_upcA);
      expect(saved?.id, found.choice.ref.id);
      expect(saved?.createdFrom, 'off');
      final entries = await DiaryRepository(h.db)
          .watchEntries(today, today)
          .first;
      expect(entries.single.food.ref, FoodRef.personal(saved!.id));
      expect(entries.single.amount.amount, 30);

      // Second scan: step 1 finds it, no server call.
      final again = _Ports()..personal = saved;
      expect(
        (await again.lookup().lookup(
          _upcA,
        ) as BarcodeFound).choice.pendingCreate,
        isNull,
      );

      await undo.undo((result as FoodLogged).undoEntryId);
      expect(await repo.byBarcode(_upcA), isNull);
      expect(
        await DiaryRepository(h.db).watchEntries(today, today).first,
        isEmpty,
      );
    });
  });

  group('review fix 2: OFF provenance stays with the saved food', () {
    test(
      'the second scan shows the same halal flags, fiber note and credit',
      () async {
        final h = PersonalHarness();
        addTearDown(h.db.close);
        final clock = ManualClock(DateTime.utc(2026, 10, 23, 12));
        final undo = UndoStack(revert: h.applier.revert, clock: clock);
        addTearDown(undo.dispose);
        final ports = _Ports()
          ..server = BarcodeApiFound(
            _off(
              name: 'Gummy bears',
              fiber: null,
              ingredients: 'sugar, gelatine',
            ),
          );
        final first = await ports.lookup().lookup(_ean) as BarcodeFound;
        expect(first.product.halal, {HalalFlag.unknownSource});
        await LogFood(
          apply: h.applier.apply,
          undoStack: undo,
          clock: clock,
          ids: SequenceIdGenerator(),
        )(choice: first.choice, input: Quantity(1, 'serving'), date: today);
        final saved = (await PersonalFoodRepository(h.db).byBarcode(_ean))!;
        final again = await (_Ports()..personal = saved).lookup().lookup(
          _ean,
        ) as BarcodeFound;
        expect(again.product.source, ScannedSource.personal);
        expect(again.product.halal, {HalalFlag.unknownSource});
        expect(again.product.fiberMissing, isTrue);
        expect(again.product.fromOff, isTrue);
      },
    );

    test('an OFF prefill completed in the form keeps the OFF origin; typing '
        'fiber clears the 0 mark', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final container = ProviderContainer(
        overrides: [
          personalFoodsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);
      final off = _off(fat: null, fiber: null, ingredients: 'pork fat');
      container
          .read(scanFoodPrefillProvider.notifier)
          .put(ScanPrefill.fromOff(off));
      final key = PersonalFoodFormKey.scan();
      final sub = container.listen(
        personalFoodFormControllerProvider(key),
        (_, _) {},
      );
      addTearDown(sub.close);
      final form = await container.read(
        personalFoodFormControllerProvider(key).future,
      );
      // The new form already carries the OFF origin, so it shows the credit
      // before it is saved (round-2 minor).
      expect(OffOrigin.decode(form.newCreatedFrom), isNotNull);
      final filled = form.copyWith(
        fields: {...form.fields, PersonalFoodField.fat: '30'},
        touched: {PersonalFoodField.fat},
      );
      final origin = OffOrigin.decode(filled.validation.draft!.createdFrom)!;
      expect(origin.halal, {HalalFlag.pork});
      expect(origin.fiberAssumed, isTrue);
      final withFiber = filled.copyWith(
        fields: {...filled.fields, PersonalFoodField.fiber: '2'},
      );
      expect(
        OffOrigin.decode(withFiber.validation.draft!.createdFrom)!.fiberAssumed,
        isFalse,
      );
    });
  });

  group('review: atomic create + log', () {
    test('when the log write fails nothing is saved', () async {
      final h = PersonalHarness(failLog: true);
      addTearDown(h.db.close);
      final clock = ManualClock(DateTime.utc(2026, 10, 23, 12));
      final undo = UndoStack(revert: h.applier.revert, clock: clock);
      addTearDown(undo.dispose);
      final found =
          await (_Ports()..server = BarcodeApiFound(_off())).lookup().lookup(
            _ean,
          ) as BarcodeFound;
      final result = await LogFood(
        apply: h.applier.apply,
        undoStack: undo,
        clock: clock,
        ids: SequenceIdGenerator(),
      )(choice: found.choice, input: Quantity(1, 'serving'), date: today);
      expect(result, isA<FoodLogFailed>());
      expect(await PersonalFoodRepository(h.db).byBarcode(_ean), isNull);
      expect(
        await DiaryRepository(h.db).watchEntries(today, today).first,
        isEmpty,
      );
    });
  });

  group('A28a D10 pending scans (OF-02)', () {
    late ProviderContainer container;
    late ManualClock clock;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      clock = ManualClock(DateTime.utc(2026, 10, 23, 12));
      container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(clock),
          pendingScansStoreProvider.overrideWith(
            (ref) async => PendingScansStore(SharedPreferencesAsync()),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test(
      'an offline scan waits and is processed on the next trigger',
      () async {
        final scans = container.read(pendingScansProvider.notifier);
        await scans.add(_ean);
        await scans.add(_ean);
        expect(await container.read(pendingScansProvider.future), hasLength(1));

        final ports = _Ports()..server = const BarcodeApiUnavailable();
        await scans.process(ports.lookup());
        expect(
          (await container.read(pendingScansProvider.future)).single.state,
          PendingScanState.waiting,
        );

        ports.server = BarcodeApiFound(_off());
        await scans.process(ports.lookup());
        final ready = (await container.read(pendingScansProvider.future))
            .single;
        expect(ready.state, PendingScanState.ready);
        expect(ready.name, 'Synthetic halawa');

        // It survives a restart (device state in shared preferences).
        final store = await container.read(pendingScansStoreProvider.future);
        expect((await store.read()).single.state, PendingScanState.ready);
      },
    );

    test(
      'not found is kept as such; a code you added yourself is dropped',
      () async {
        final scans = container.read(pendingScansProvider.notifier);
        await scans.add(_ean);
        await scans.add('0$_upcA');
        final ports = _Ports();
        await scans.process(ports.lookup());
        expect(
          (await container.read(pendingScansProvider.future))
              .map((s) => s.state),
          [PendingScanState.notFound, PendingScanState.notFound],
        );
        await scans.remove(_ean);
        expect(await container.read(pendingScansProvider.future), hasLength(1));
      },
    );

    test('review fix 1: each local profile has its own list; a deleted '
        "profile's list goes with it", () async {
      final preferences = SharedPreferencesAsync();
      final profiles = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(clock),
          sharedPreferencesProvider.overrideWithValue(preferences),
          pendingScansNamespaceProvider.overrideWithValue('dev|test'),
        ],
      );
      addTearDown(profiles.dispose);
      final sub = profiles.listen(pendingScansProvider, (_, _) {});
      addTearDown(sub.close);
      void switchTo(String key) {
        profiles.read(profileGenerationProvider.notifier).bump();
        profiles.read(profileKeyProvider.notifier).select(key);
      }

      switchTo('a');
      await profiles.read(pendingScansProvider.notifier).add(_ean);
      switchTo('b');
      expect(await profiles.read(pendingScansProvider.future), isEmpty);
      switchTo('a');
      expect(
        (await profiles.read(pendingScansProvider.future)).single.code,
        _ean,
      );

      // Work started for profile a never lands in b.
      final scans = profiles.read(pendingScansProvider.notifier);
      final slow = _Ports()
        ..server = BarcodeApiFound(_off())
        ..hold = Completer<void>();
      final processing = scans.process(slow.lookup());
      await slow.asked.future;
      switchTo('b');
      await profiles.read(pendingScansProvider.future);
      slow.hold!.complete();
      await processing;
      expect(await profiles.read(pendingScansProvider.future), isEmpty);

      await PendingScansStore.deleteFor(preferences, 'dev|test', 'a');
      switchTo('a');
      expect(await profiles.read(pendingScansProvider.future), isEmpty);
    });

    test('review fix 1 (round 2): a lookup that finishes while the next '
        "profile's store is still loading never lands in it", () async {
      final preferences = SharedPreferencesAsync();
      final bLoading = Completer<void>();
      final profiles = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(clock),
          pendingScansStoreProvider.overrideWith((ref) async {
            ref.watch(profileGenerationProvider);
            final key = ref.watch(profileKeyProvider) ?? 'local';
            if (key == 'b') await bLoading.future;
            return PendingScansStore(preferences, key: 'pending|$key');
          }),
        ],
      );
      addTearDown(profiles.dispose);
      final sub = profiles.listen(pendingScansProvider, (_, _) {});
      addTearDown(sub.close);
      void switchTo(String key) {
        profiles.read(profileGenerationProvider.notifier).bump();
        profiles.read(profileKeyProvider.notifier).select(key);
      }

      // The same barcode waits in both profiles.
      final now = clock.nowUtc().millisecondsSinceEpoch;
      for (final key in ['a', 'b']) {
        await PendingScansStore(
          preferences,
          key: 'pending|$key',
        ).write([PendingScan(code: _ean, scannedAtMs: now)]);
      }
      switchTo('a');
      await profiles.read(pendingScansProvider.future);
      final slow = _Ports()
        ..server = BarcodeApiFound(_off())
        ..hold = Completer<void>();
      final processing = profiles
          .read(pendingScansProvider.notifier)
          .process(slow.lookup());
      await slow.asked.future;
      switchTo('b'); // b's store is still loading
      slow.hold!.complete();
      // The old lookup is done and waits for the list while b's store is
      // still loading; then b's store arrives.
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      bLoading.complete();
      await processing;
      final b = await profiles.read(pendingScansProvider.future);
      expect(b.single.state, PendingScanState.waiting);
      final stored = await PendingScansStore(
        preferences,
        key: 'pending|b',
      ).read();
      expect(stored.single.state, PendingScanState.waiting);
    });

    test('at most 20 scans, each kept 14 days', () async {
      final scans = container.read(pendingScansProvider.notifier);
      for (var i = 0; i < 22; i++) {
        await scans.add('$i');
      }
      final kept = await container.read(pendingScansProvider.future);
      expect(kept, hasLength(PendingScans.maxScans));
      expect(kept.first.code, '2');
      clock.advance(const Duration(days: 15));
      await scans.add('fresh');
      expect(
        (await container.read(pendingScansProvider.future)).map((s) => s.code),
        ['fresh'],
      );
    });
  });
}
