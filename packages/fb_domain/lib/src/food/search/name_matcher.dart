import 'package:fb_domain/src/food/search/fuzzy_index.dart';

/// Match strength in increasing order (FD-020/021).
enum MatchStrength {
  /// Some query tokens did not match.
  partial,

  /// At least one token only matched within a word.
  substring,

  /// Every token matched, with at least one whole-word typo.
  fuzzy,

  /// Every token is a word prefix.
  words,

  /// The whole name starts with the query.
  prefix,

  /// The whole name equals the query.
  exact;

  /// Good matches always precede weak matches, regardless of tier.
  bool get isGood => index >= words.index;
}

/// Matches already-normalized keys; normalization belongs to the caller.
abstract final class NameMatcher {
  /// Best strength for the whole query against one name, or null for no hit.
  /// Supply query-scoped [corrections] to reuse fuzzy work across candidates;
  /// [fuzzyIndex] is a convenience for matching a single name.
  static MatchStrength? match(
    String queryKey,
    List<String> tokens,
    String nameKey, {
    FuzzyIndex? fuzzyIndex,
    Map<String, List<String>>? corrections,
  }) {
    if (queryKey.isEmpty || nameKey.isEmpty || tokens.isEmpty) return null;
    if (nameKey == queryKey) return MatchStrength.exact;
    if (nameKey.startsWith(queryKey)) return MatchStrength.prefix;
    final words = nameKey.split(' ');
    var strength = MatchStrength.words;
    var hits = 0;
    for (final token in tokens) {
      MatchStrength? tokenStrength;
      if (words.any((w) => w.startsWith(token))) {
        tokenStrength = MatchStrength.words;
      } else if ((corrections?[token] ??
              fuzzyIndex?.corrections(token) ??
              const <String>[])
          .any(words.contains)) {
        tokenStrength = MatchStrength.fuzzy;
      } else if (nameKey.contains(token)) {
        tokenStrength = MatchStrength.substring;
      }
      if (tokenStrength == null) {
        strength = MatchStrength.partial;
      } else {
        hits++;
        if (tokenStrength.index < strength.index) strength = tokenStrength;
      }
    }
    return hits == 0 ? null : strength;
  }
}
