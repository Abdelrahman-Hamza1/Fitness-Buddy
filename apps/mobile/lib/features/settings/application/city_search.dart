import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/catalog/catalog_providers.dart';
import 'package:fb_text/fb_text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'city_search.g.dart';

/// Search result retains catalog metadata, without formatting UI text.
final class CityResult {
  /// Creates one result.
  const new(this.city);

  /// Matched city.
  final CatalogCity city;
}

/// One loaded, normalized city list per open picker.
final class CitySearch {
  /// Normalize once, never for each keystroke.
  new(List<CatalogCity> cities)
    : _cities = {for (final c in cities) c.id: c},
      _candidates = [
        for (final c in cities)
          CityCandidate(
            id: c.id,
            keyEn: normalizeKey(c.nameEn),
            keyAr: normalizeKey(c.nameAr ?? ''),
            countryCode: c.countryCode,
            population: c.population,
            nameEn: c.nameEn,
          ),
      ];
  final Map<String, CatalogCity> _cities;
  final List<CityCandidate> _candidates;

  /// Whether the pack has no cities at all.
  bool get isEmpty => _cities.isEmpty;

  /// Non-empty text uses deterministic offline name matching.
  List<CityResult> query(String text) {
    final key = normalizeKey(text);
    return _results(CityRanker.rank(key, key.split(' '), _candidates));
  }

  /// Empty-query choices with the current city first.
  List<CityResult> suggestions(String? currentId) =>
      _results(CityRanker.suggestions(_candidates, currentId: currentId));
  List<CityResult> _results(List<CityCandidate> cities) => [
    for (final c in cities) CityResult(_cities[c.id]!),
  ];
}

/// Auto-disposed when the picker closes; one catalog read per session.
// UX-051 presents the error immediately; the picker owns explicit retry.
@Riverpod(retry: _noAutomaticRetry)
Future<CitySearch> citySearch(Ref ref) async =>
    CitySearch(await ref.watch(offlineCatalogProvider).cities());

Duration? _noAutomaticRetry(int retryCount, Object error) => null;
