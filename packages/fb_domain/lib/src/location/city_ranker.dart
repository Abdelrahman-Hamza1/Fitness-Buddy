import 'package:fb_domain/src/food/search/name_matcher.dart';

/// A city with caller-normalized English and Arabic names.
final class CityCandidate {
  /// Creates an offline search candidate.
  const new({
    required this.id,
    required this.keyEn,
    required this.keyAr,
    required this.countryCode,
    required this.population,
    required this.nameEn,
  });

  /// Stable catalog identity.
  final String id;

  /// Normalized English name.
  final String keyEn;

  /// Normalized Arabic name (empty when absent).
  final String keyAr;

  /// ISO country code.
  final String countryCode;

  /// Population; zero remains searchable.
  final int population;

  /// English name for deterministic ties.
  final String nameEn;
}

/// LC-033: name strength, region, population, then stable lexical ties.
abstract final class CityRanker {
  /// Searches pre-normalized names without fuzzy matching.
  static List<CityCandidate> rank(
    String key,
    List<String> tokens,
    Iterable<CityCandidate> candidates, {
    int limit = 50,
    List<String> region = const ['PS', 'JO'],
  }) {
    if (key.isEmpty || limit <= 0) return [];
    final matches = <(CityCandidate, int)>[];
    for (final city in candidates) {
      final en = NameMatcher.match(key, tokens, city.keyEn);
      final ar = NameMatcher.match(key, tokens, city.keyAr);
      final strength = (en?.index ?? -1) > (ar?.index ?? -1) ? en : ar;
      if (strength != null && strength.isGood) {
        matches.add((city, strength.index));
      }
    }
    matches.sort((a, b) {
      final strength = b.$2.compareTo(a.$2);
      return strength != 0 ? strength : _compare(a.$1, b.$1, region);
    });
    return matches.take(limit).map((m) => m.$1).toList();
  }

  /// Current city, then the largest 20 PS and 10 JO choices without repeats.
  static List<CityCandidate> suggestions(
    Iterable<CityCandidate> candidates, {
    String? currentId,
  }) {
    final cities = candidates.toList();
    final current = cities.where((c) => c.id == currentId);
    final ps = cities.where((c) => c.countryCode == 'PS').toList()
      ..sort((a, b) => _compare(a, b, const []));
    final jo = cities.where((c) => c.countryCode == 'JO').toList()
      ..sort((a, b) => _compare(a, b, const []));
    final seen = <String>{};
    return [
      for (final city in [...current, ...ps.take(20), ...jo.take(10)])
        if (seen.add(city.id)) city,
    ];
  }

  static int _compare(CityCandidate a, CityCandidate b, List<String> region) {
    int priority(String code) {
      final i = region.indexOf(code);
      return i < 0 ? region.length : i;
    }

    final country = priority(a.countryCode).compareTo(priority(b.countryCode));
    if (country != 0) return country;
    final population = b.population.compareTo(a.population);
    if (population != 0) return population;
    final name = a.nameEn.compareTo(b.nameEn);
    return name != 0 ? name : a.id.compareTo(b.id);
  }
}
