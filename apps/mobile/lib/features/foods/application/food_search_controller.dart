import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/catalog/online_food_search.dart';
import 'package:fb_mobile/features/foods/application/food_search_service.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_text/fb_text.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_search_controller.g.dart';

/// Latest query and its non-stale results or failure.
final class FoodSearchState {
  /// Creates this structured value.
  const new({this.query = '', this.results, this.resultsFor, this.error});

  /// Latest requested query, including any typed quantity.
  final String query;

  /// Latest non-stale results, or null before the first search.
  final FoodSearchResults? results;

  /// The query [results] answer; differs from [query] while a newer search
  /// runs, so a screen can keep showing the rows it has under their own query.
  final String? resultsFor;

  /// Search failure for presentation to handle; never logged as content.
  final Object? error;

  /// Whether the query requests recent foods.
  bool get recent => query.trim().isEmpty;

  /// Whether a readable catalog pack is attached.
  bool get packReady => results?.packReady ?? false;
}

/// One running search + one replaceable pending request, without debounce.
///
/// After local results for a query are on screen, an online search for the
/// same query runs after [onlineDelay] and its new foods are appended (A24
/// D1/D2). Local results never wait for it; a failed online leg changes
/// nothing.
@riverpod
class FoodSearchController extends _$FoodSearchController {
  /// Quiet time before the online leg (network only; local is instant).
  static const onlineDelay = Duration(milliseconds: 300);

  /// Waits before each retry of a failed online leg (offline, no session,
  /// server error): bounded, then local only until the query changes.
  static const onlineRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
  ];

  String? _pending;
  Future<void>? _running;
  late FoodSearchService _service;
  bool _disposed = false;
  int _revision = 0;
  Future<void>? _onlineRun;
  String? _onlineQuery;
  List<CatalogFood> _onlineFoods = const [];
  // Retry budget of the normalized online query, kept across same-query
  // re-runs (history/pack refreshes) so they neither reset nor extend it.
  String? _budgetKey;
  int _attempts = 0;
  Duration? _nextAttemptAt;
  Future<List<CatalogFood>?>? _inFlight;

  /// Completes when both running and pending searches finish.
  Future<void> settle() => _running ?? Future.value();

  /// Completes when the latest online leg (with its retries) finishes.
  @visibleForTesting
  Future<void> settleOnline() => _onlineRun ?? Future.value();
  @override
  FoodSearchState build() {
    _disposed = false;
    _revision++;
    _pending = null;
    _service = ref.watch(foodSearchServiceProvider);
    _onlineQuery = null;
    _onlineFoods = const [];
    _budgetKey = null;
    _attempts = 0;
    _nextAttemptAt = null;
    _inFlight = null;
    final sub = _service.changes.listen((_) => setQuery(state.query));
    // Row previews use the unit system's default portion, so a change of the
    // setting re-runs the visible query.
    ref.listen(unitSystemProvider, (previous, next) {
      if (previous?.value != next.value) setQuery(state.query);
    });
    ref.onDispose(() {
      _disposed = true;
      unawaited(sub.cancel());
    });
    return const FoodSearchState();
  }

  /// Replaces pending text and discards stale in-flight results.
  void setQuery(String text) {
    if (_disposed) return;
    _revision++;
    _pending = text;
    state = FoodSearchState(
      query: text,
      results: state.results,
      resultsFor: state.resultsFor,
    );
    _running ??= _drain().whenComplete(() => _running = null);
  }

  Future<void> _drain() async {
    while (_pending != null) {
      final text = _pending!;
      _pending = null;
      final revision = _revision;
      try {
        final system = ref.read(unitSystemProvider).value ?? UnitSystem.metric;
        final result = await _service.search(text, system: system);
        if (!_disposed && revision == _revision) {
          final query = FoodSearchService.onlineQuery(text, result);
          state = FoodSearchState(
            query: text,
            // A re-run of the same query (history or pack change) keeps its
            // online rows without a new request.
            results: query == _onlineQuery
                ? _service.appendOnline(result, _onlineFoods, system: system)
                : result,
            resultsFor: text,
          );
          if (query != _onlineQuery) {
            _scheduleOnline(text, query, result, revision, system);
          }
        }
      } on Object catch (error) {
        if (!_disposed && revision == _revision) {
          state = FoodSearchState(
            query: text,
            error: error,
            results: state.results,
            resultsFor: state.resultsFor,
          );
        }
      }
    }
  }

  void _scheduleOnline(
    String text,
    String query,
    FoodSearchResults local,
    int revision,
    UnitSystem system,
  ) {
    if (query.trim().isEmpty) return;
    final OnlineFoodSearch online;
    final OnlineSearchTime time;
    try {
      // Decide synchronously, before any wait: the API stack is optional for
      // search (switched off, no config or a test scope without it means
      // local only, with nothing pending).
      if (!ref.read(onlineFoodSearchEnabledProvider)) return;
      online = ref.read(onlineFoodSearchProvider);
      time = ref.read(onlineSearchTimeProvider);
    } on Object {
      return;
    }
    _onlineRun = _runOnline(text, query, local, revision, system, online, time);
  }

  /// The online leg for one query: the first request [onlineDelay] after the
  /// local result, then on failure one retry after each of
  /// [onlineRetryDelays]. The attempt count and the next deadline belong to
  /// the normalized query, so a same-query re-run resumes the budget (waits
  /// only the rest of the current delay) instead of restarting it. Only a
  /// successful answer (empty included) is remembered; a newer query or
  /// re-run stops this run.
  Future<void> _runOnline(
    String text,
    String query,
    FoodSearchResults local,
    int revision,
    UnitSystem system,
    OnlineFoodSearch online,
    OnlineSearchTime time,
  ) async {
    bool stale() => _disposed || revision != _revision;
    final key = normalizeKey(query);
    if (key != _budgetKey) {
      _budgetKey = key;
      _attempts = 0;
      _nextAttemptAt = null;
      _inFlight = null;
    }
    while (_attempts <= onlineRetryDelays.length) {
      final due = _nextAttemptAt ??= time.elapsed + onlineDelay;
      final rest = due - time.elapsed;
      await time.wait(rest.isNegative ? Duration.zero : rest);
      if (stale()) return;
      // A re-run joins the request already in flight for this query instead
      // of sending (and counting) a second one.
      final Future<List<CatalogFood>?> request;
      if (_inFlight case final pending?) {
        request = pending;
      } else {
        _attempts++;
        request = _inFlight = online.search(query);
        unawaited(
          request.then((_) {
            if (identical(_inFlight, request)) _inFlight = null;
          }),
        );
      }
      final foods = await request;
      if (foods == null) {
        // The next deadline is set even if this run went stale meanwhile,
        // so the re-run that replaced it keeps the same budget.
        _nextAttemptAt = _attempts <= onlineRetryDelays.length
            ? time.elapsed + onlineRetryDelays[_attempts - 1]
            : null;
        if (stale()) return;
        continue;
      }
      _nextAttemptAt = null;
      if (stale()) return;
      _onlineQuery = query;
      _onlineFoods = foods;
      if (foods.isEmpty) return;
      state = FoodSearchState(
        query: text,
        results: _service.appendOnline(local, foods, system: system),
        resultsFor: text,
      );
      return;
    }
  }
}
