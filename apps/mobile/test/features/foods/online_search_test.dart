import 'dart:async';

import 'package:fb_api_client/fb_api_client.dart' as api;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/catalog/online_food_search.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'food_search_test.dart' show fixtureService, ready, riceId;

api.CatalogFood apiFood(
  String id, {
  String nameEn = 'Quinoa, cooked',
  String? nameAr = 'كينوا مطبوخة',
  String source = 'usda',
  String state = 'cooked',
  String kind = 'basic',
}) => api.CatalogFood(
  kind: kind,
  source: source,
  sourceRef: null,
  nameEn: nameEn,
  nameAr: nameAr,
  state: state,
  verified: true,
  catalogVersion: 9,
  nutrients: const api.CatalogNutrients(
    kcal: 120,
    proteinG: 4.4,
    carbsG: 21.3,
    fatG: 1.9,
    fiberG: 2.8,
  ),
  ranges: null,
  extras: null,
  densityGPerMl: null,
  yieldGroup: null,
  servings: const [
    api.CatalogServing(
      unitCode: 'cup',
      g: 185,
      ml: null,
      rangeLo: 170,
      rangeHi: 200,
      source: 'usda',
    ),
  ],
  catalogKey: id,
);

final class FakeCatalogClient implements api.CatalogClient {
  new(this.answer);

  /// Returns the page for a query, or throws.
  FutureOr<api.CatalogSearchPage> Function(String query) answer;
  final queries = <String>[];

  @override
  Future<api.CatalogSearchPage> searchFoods({
    required String query,
    required int limit,
    String? cursor,
  }) async {
    queries.add(query);
    return await answer(query);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Virtual monotonic time: waits complete at once (advancing the clock) and
/// are recorded; the wait at index [blockAt] holds until [gate] completes.
final class FakeSearchTime implements OnlineSearchTime {
  Duration now = Duration.zero;
  final waits = <Duration>[];
  int? blockAt;
  final gate = Completer<void>();

  @override
  Duration get elapsed => now;

  @override
  Future<void> wait(Duration delay) async {
    final index = waits.length;
    waits.add(delay);
    now += delay;
    if (index == blockAt) await gate.future;
  }
}

api.CatalogSearchPage page(List<api.CatalogFood> items) =>
    api.CatalogSearchPage(items: items, nextCursor: null);

void main() {
  group('catalogFoodFromApi', () {
    test('FD-020 maps an API catalog food to a catalog food', () {
      final food = catalogFoodFromApi(apiFood('usda:quinoa_cooked'))!;
      expect(food.id, 'usda:quinoa_cooked');
      expect(food.nameAr, 'كينوا مطبوخة');
      expect(food.state, FoodState.cooked);
      expect(food.basis, NutrientBasis.per100g);
      expect(food.badge, CatalogBadge.database);
      expect(food.packVersion, 9);
      expect(food.nutrients.kcal, 120);
      expect(food.servingUnits.single.code, 'cup');
      expect(food.servingUnits.single.amount, 185);
      expect(food.servingRanges['cup'], (170.0, 200.0));
      expect(food.dishId, isNull);
    });

    test('FD-020 a reference variant keeps its dish id', () {
      final food = catalogFoodFromApi(
        apiFood('ref:maqluba/chicken', source: 'reference', kind: 'variant'),
      )!;
      expect(food.kind, CatalogFoodKind.variant);
      expect(food.dishId, 'ref:maqluba');
      expect(food.badge, CatalogBadge.reference);
    });

    test('FD-020 drops unknown sources and states', () {
      expect(catalogFoodFromApi(apiFood('off:1', source: 'off')), isNull);
      expect(catalogFoodFromApi(apiFood('usda:x', state: 'odd')), isNull);
    });
  });

  group('OnlineFoodSearch', () {
    test('FD-020 offline or failing server reads as no results', () async {
      final search = OnlineFoodSearch(
        FakeCatalogClient((_) => throw StateError('offline')),
        OnlineFoodCache(),
      );
      expect(await search.search('quinoa'), isNull);
    });

    test('FD-020 results are cached for the sheet, bounded', () async {
      final cache = OnlineFoodCache(capacity: 1);
      final search = OnlineFoodSearch(
        FakeCatalogClient(
          (q) => page([apiFood('usda:$q'), apiFood('off:1', source: 'off')]),
        ),
        cache,
      );
      expect((await search.search('a'))!.map((f) => f.id), ['usda:a']);
      await search.search('b');
      expect(cache['usda:a'], isNull);
      expect(cache['usda:b']?.id, 'usda:b');
    });
  });

  group('appendOnline', () {
    test(
      'FD-020 FD-021 online results append after local without duplicates',
      () async {
        final service = fixtureService();
        await ready(service);
        final local = await service.search('rice');
        expect(local.rows.map((r) => r.choice.ref.id), contains(riceId));
        final merged = service.appendOnline(local, [
          catalogFoodFromApi(
            apiFood(riceId, nameEn: 'Rice, white, cooked (server)'),
          )!,
          catalogFoodFromApi(apiFood('usda:quinoa_cooked'))!,
        ]);
        expect(
          merged.rows.take(local.rows.length).map((r) => r.identity),
          local.rows.map((r) => r.identity),
        );
        expect(merged.rows.length, local.rows.length + 1);
        expect(merged.rows.last.choice.ref.id, 'usda:quinoa_cooked');
        expect(merged.onlineRows, 1);
        expect(
          merged.rows.map((r) => r.identity).toSet().length,
          merged.rows.length,
        );
      },
    );

    test(
      'FD-021 same name and state under another id is a duplicate',
      () async {
        final service = fixtureService();
        await ready(service);
        final local = await service.search('rice');
        final first = local.rows.first.choice.catalogFood!;
        final merged = service.appendOnline(local, [
          catalogFoodFromApi(
            apiFood(
              'usda:other_id',
              nameEn: first.nameEn,
              nameAr: first.nameAr,
              state: first.state.code,
            ),
          )!,
        ]);
        expect(merged.rows.length, local.rows.length);
        expect(merged.onlineRows, 0);
      },
    );
  });

  test('FD-020 an online-only food loads through the cache', () async {
    final service = fixtureService();
    await ready(service);
    final cache = OnlineFoodCache()
      ..addAll([catalogFoodFromApi(apiFood('usda:quinoa_cooked'))!]);
    final choice = await FoodChoiceLoader(
      service.repository,
      () => service.history,
      onlineFood: (id) => cache[id],
    ).load(FoodChoiceRef(FoodRef.catalog('usda:quinoa_cooked', version: '9')));
    expect(choice?.catalogFood?.id, 'usda:quinoa_cooked');
    expect(choice?.food.names.en, 'Quinoa, cooked');
  });

  group('FoodSearchController online leg', () {
    late FakeSearchTime time;
    List<Duration> waits() => time.waits;

    Future<(ProviderContainer, FakeCatalogClient)> start(
      FutureOr<api.CatalogSearchPage> Function(String) answer,
    ) async {
      final service = fixtureService();
      await ready(service);
      final client = FakeCatalogClient(answer);
      time = FakeSearchTime();
      final container = ProviderContainer(
        overrides: [
          foodSearchServiceProvider.overrideWithValue(service),
          onlineFoodSearchProvider.overrideWithValue(
            OnlineFoodSearch(client, OnlineFoodCache()),
          ),
          // No real timers: virtual time, every wait recorded.
          onlineSearchTimeProvider.overrideWithValue(time),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(foodSearchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      return (container, client);
    }

    Future<void> settle(ProviderContainer container) async {
      final controller = container.read(foodSearchControllerProvider.notifier);
      await controller.settle();
      await controller.settleOnline();
    }

    test('FD-020 local first, online rows appended when they arrive', () async {
      final (container, client) = await start(
        (_) => page([apiFood('usda:quinoa_cooked', nameEn: 'Rice quinoa')]),
      );
      container.read(foodSearchControllerProvider.notifier).setQuery('rice');
      await settle(container);
      final state = container.read(foodSearchControllerProvider);
      expect(state.error, isNull);
      expect(
        state.results!.rows.first.choice.ref.id,
        isNot('usda:quinoa_cooked'),
      );
      expect(state.results!.rows.last.choice.ref.id, 'usda:quinoa_cooked');
      expect(client.queries, ['rice']);
      expect(waits(), [FoodSearchController.onlineDelay]);
    });

    test('FD-020 offline: online failure keeps local results, no error, '
        'bounded retries', () async {
      final (container, client) = await start(
        (_) => throw StateError('offline'),
      );
      container.read(foodSearchControllerProvider.notifier).setQuery('rice');
      await settle(container);
      final state = container.read(foodSearchControllerProvider);
      expect(state.error, isNull);
      expect(state.results!.rows, isNotEmpty);
      expect(state.results!.onlineRows, 0);
      expect(
        client.queries,
        hasLength(FoodSearchController.onlineRetryDelays.length + 1),
      );
      expect(waits(), [
        FoodSearchController.onlineDelay,
        ...FoodSearchController.onlineRetryDelays,
      ]);
    });

    test('FD-020 offline, then online with the same text: online rows '
        'appear', () async {
      var calls = 0;
      final (container, client) = await start((_) {
        if (calls++ == 0) throw StateError('offline');
        return page([apiFood('usda:quinoa_cooked', nameEn: 'Rice quinoa')]);
      });
      container.read(foodSearchControllerProvider.notifier).setQuery('rice');
      await settle(container);
      final state = container.read(foodSearchControllerProvider);
      expect(client.queries, ['rice', 'rice']);
      expect(state.results!.rows.last.choice.ref.id, 'usda:quinoa_cooked');
      expect(state.results!.onlineRows, 1);
    });

    test(
      'FD-020 a successful empty answer is remembered, not retried',
      () async {
        final (container, client) = await start((_) => page([]));
        final controller = container.read(foodSearchControllerProvider.notifier)
          ..setQuery('rice');
        await settle(container);
        controller.setQuery('rice');
        await settle(container);
        expect(client.queries, ['rice']);
      },
    );

    test(
      'FD-020 a same-query refresh keeps the retry budget and deadline',
      () async {
        final (container, client) = await start(
          (_) => throw StateError('offline'),
        );
        // Hold the first retry wait (index 1), then refresh the same query.
        time.blockAt = 1;
        final controller = container.read(foodSearchControllerProvider.notifier)
          ..setQuery('rice');
        await controller.settle();
        await pumpEventQueue();
        expect(client.queries, ['rice']);
        expect(waits(), [
          FoodSearchController.onlineDelay,
          FoodSearchController.onlineRetryDelays[0],
        ]);
        final heldRun = controller.settleOnline();

        controller.setQuery('rice');
        await settle(container);
        time.gate.complete();
        await heldRun;

        // One budget for the query: the first request plus one per retry
        // delay, never restarted by the refresh.
        expect(
          client.queries,
          hasLength(FoodSearchController.onlineRetryDelays.length + 1),
        );
        // The refresh resumed at the held deadline (already reached), then
        // the remaining retry delays; no second initial delay.
        expect(waits(), [
          FoodSearchController.onlineDelay,
          FoodSearchController.onlineRetryDelays[0],
          Duration.zero,
          ...FoodSearchController.onlineRetryDelays.skip(1),
        ]);
      },
    );

    test('FD-020 stale online results are discarded', () async {
      final gate = Completer<api.CatalogSearchPage>();
      final (container, _) = await start(
        (q) => q == 'rice' ? gate.future : page([]),
      );
      final controller = container.read(foodSearchControllerProvider.notifier)
        ..setQuery('rice');
      await controller.settle();
      final staleRun = controller.settleOnline();
      controller.setQuery('pita');
      await settle(container);
      gate.complete(page([apiFood('usda:quinoa_cooked')]));
      await staleRun;
      final state = container.read(foodSearchControllerProvider);
      expect(state.query, 'pita');
      expect(
        state.results!.rows.map((r) => r.choice.ref.id),
        isNot(contains('usda:quinoa_cooked')),
      );
    });

    test('FD-020 no online request for recent foods', () async {
      final (container, client) = await start((_) => page([]));
      container.read(foodSearchControllerProvider.notifier).setQuery('  ');
      await settle(container);
      expect(client.queries, isEmpty);
    });
  });
}
