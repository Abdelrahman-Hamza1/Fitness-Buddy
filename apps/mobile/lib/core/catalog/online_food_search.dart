import 'package:fb_api_client/fb_api_client.dart' as api;
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/catalog/catalog_api_mapping.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'online_food_search.g.dart';

/// Whether search may use the server catalog (A24 D1). On in the app; test
/// phones switch it off so their exact request logs and timers stay as is.
@Riverpod(keepAlive: true)
bool onlineFoodSearchEnabled(Ref ref) => true;

/// Monotonic time for the online leg's waits and retry deadlines (A24 D1).
/// Tests substitute virtual time, so no real timers run.
abstract interface class OnlineSearchTime {
  /// Time since an arbitrary fixed start (monotonic).
  Duration get elapsed;

  /// Completes after [delay].
  Future<void> wait(Duration delay);
}

/// Real monotonic time: a running stopwatch and `Future.delayed`.
final class StopwatchOnlineSearchTime implements OnlineSearchTime {
  final _watch = Stopwatch()..start();

  @override
  Duration get elapsed => _watch.elapsed;

  @override
  Future<void> wait(Duration delay) => Future<void>.delayed(delay);
}

/// The online leg's time source.
@Riverpod(keepAlive: true)
OnlineSearchTime onlineSearchTime(Ref ref) => StopwatchOnlineSearchTime();

/// Foods seen in online results during this app run (A24 D4).
@Riverpod(keepAlive: true)
OnlineFoodCache onlineFoodCache(Ref ref) => OnlineFoodCache();

/// Online leg of food search over the generated client (A24 D1).
@riverpod
OnlineFoodSearch onlineFoodSearch(Ref ref) => OnlineFoodSearch(
  ref.watch(fbApiProvider).catalog,
  ref.watch(onlineFoodCacheProvider),
);

/// Online full catalog search (FD-020, A24 D1): the server catalog through
/// the generated client. Purely additive to the offline search.
///
/// Never throws: offline, no session, timeouts and server errors all read as
/// `null` ("failed, may retry"), distinct from an empty answer. Nothing is
/// logged or reported, because the query is user content and a failed online
/// leg is normal (offline-first).
final class OnlineFoodSearch {
  /// Searches through [client] and remembers results in [cache].
  const new(this.client, this.cache);

  /// Generated catalog client.
  final api.CatalogClient client;

  /// Keeps the foods of recent results so the sheet can open them.
  final OnlineFoodCache cache;

  /// Results per request.
  static const limit = 20;

  /// The server's foods for [query] in its order, mapped to app foods, or
  /// `null` when the request failed.
  Future<List<CatalogFood>?> search(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final page = await client.searchFoods(query: query, limit: limit);
      final foods = [for (final item in page.items) ?catalogFoodFromApi(item)];
      cache.addAll(foods);
      return foods;
    } on Object {
      return null;
    }
  }
}

/// In-memory, bounded memory of foods seen in online results (A24 D4), so an
/// online-only food can open in the amount sheet. Not persisted: a logged
/// entry keeps its own snapshot.
final class OnlineFoodCache {
  /// A cache holding at most [capacity] foods (oldest dropped first).
  new({this.capacity = 200});

  /// Maximum number of foods kept.
  final int capacity;

  final _foods = <String, CatalogFood>{};

  /// Remembers [foods], refreshing their position.
  void addAll(Iterable<CatalogFood> foods) {
    for (final food in foods) {
      _foods
        ..remove(food.id)
        ..[food.id] = food;
    }
    while (_foods.length > capacity) {
      _foods.remove(_foods.keys.first);
    }
  }

  /// The remembered food with [id], if any.
  CatalogFood? operator [](String id) => _foods[id];
}
