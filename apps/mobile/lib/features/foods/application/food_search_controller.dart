import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/application/food_search_service.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
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
@riverpod
class FoodSearchController extends _$FoodSearchController {
  String? _pending;
  Future<void>? _running;
  late FoodSearchService _service;
  bool _disposed = false;
  int _revision = 0;

  /// Completes when both running and pending searches finish.
  Future<void> settle() => _running ?? Future.value();
  @override
  FoodSearchState build() {
    _disposed = false;
    _revision++;
    _pending = null;
    _service = ref.watch(foodSearchServiceProvider);
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
        final result = await _service.search(
          text,
          system: ref.read(unitSystemProvider).value ?? UnitSystem.metric,
        );
        if (!_disposed && revision == _revision) {
          state = FoodSearchState(
            query: text,
            results: result,
            resultsFor: text,
          );
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
}
