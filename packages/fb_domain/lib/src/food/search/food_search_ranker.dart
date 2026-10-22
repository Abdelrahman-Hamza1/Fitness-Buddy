import 'package:fb_domain/src/food/search/name_matcher.dart';
import 'package:fb_domain/src/food/search/search_candidate.dart';
import 'package:fb_domain/src/ids/hlc.dart';

/// Merge-then-rank search policy (FD-021, A07 PA3/PA5).
abstract final class FoodSearchRanker {
  /// Maximum displayed rows; weak matches only fill unused good-band slots.
  static const defaultLimit = 30;

  /// Transitive key merge, representative selection, then lexicographic rank:
  /// good before weak; good: tier then strength; weak: strength then tier;
  /// finally uses, recency, shorter representative name, stable identity.
  static List<T> rank<T>(
    Iterable<SearchCandidate<T>> candidates, {
    int limit = defaultLimit,
  }) {
    if (limit <= 0) return [];
    final rows = candidates.toList();
    final parents = List<int>.generate(rows.length, (i) => i);
    int find(int index) {
      var i = index;
      while (parents[i] != i) {
        parents[i] = parents[parents[i]];
        i = parents[i];
      }
      return i;
    }

    final owners = <String, int>{};
    for (var i = 0; i < rows.length; i++) {
      for (final key in rows[i].keys) {
        final owner = owners[key];
        if (owner != null) parents[find(i)] = find(owner);
        owners[key] = i;
      }
    }
    final groups = <int, List<SearchCandidate<T>>>{};
    for (var i = 0; i < rows.length; i++) {
      (groups[find(i)] ??= []).add(rows[i]);
    }
    final merged = <SearchCandidate<T>>[];
    for (final group in groups.values) {
      group.sort(_representative);
      final representative = group.first;
      var strength = MatchStrength.partial;
      var uses = 0;
      Hlc? latest;
      for (final member in group) {
        if (member.strength.index > strength.index) strength = member.strength;
        if (member.uses > uses) uses = member.uses;
        if (_recent(member.lastUsedHlc, latest) < 0) {
          latest = member.lastUsedHlc;
        }
      }
      merged.add(
        SearchCandidate(
          keys: group.expand((c) => c.keys),
          tier: representative.tier,
          strength: strength,
          uses: uses,
          lastUsedHlc: latest,
          nameLength: representative.nameLength,
          id: representative.id,
          payload: representative.payload,
        ),
      );
    }
    merged.sort(_rank);
    return merged.take(limit).map((c) => c.payload).toList();
  }
}

int _recent(Hlc? a, Hlc? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

int _representative<T>(SearchCandidate<T> a, SearchCandidate<T> b) {
  final comparisons = [
    a.tier.index.compareTo(b.tier.index),
    _recent(a.lastUsedHlc, b.lastUsedHlc),
    b.strength.index.compareTo(a.strength.index),
    (b.isDefaultVariant ? 1 : 0).compareTo(a.isDefaultVariant ? 1 : 0),
    a.id.compareTo(b.id),
  ];
  return comparisons.firstWhere((c) => c != 0, orElse: () => 0);
}

int _rank<T>(SearchCandidate<T> a, SearchCandidate<T> b) {
  final band = (b.strength.isGood ? 1 : 0).compareTo(a.strength.isGood ? 1 : 0);
  if (band != 0) return band;
  final tier = a.tier.index.compareTo(b.tier.index);
  final strength = b.strength.index.compareTo(a.strength.index);
  final comparisons = [
    if (a.strength.isGood) ...[tier, strength] else ...[strength, tier],
    b.uses.compareTo(a.uses),
    _recent(a.lastUsedHlc, b.lastUsedHlc),
    a.nameLength.compareTo(b.nameLength),
    a.id.compareTo(b.id),
  ];
  return comparisons.firstWhere((c) => c != 0, orElse: () => 0);
}
