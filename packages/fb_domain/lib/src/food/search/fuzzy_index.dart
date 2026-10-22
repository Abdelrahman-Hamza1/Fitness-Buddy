import 'dart:typed_data';

import 'package:fb_domain/src/food/search/osa_distance.dart';

/// Bounded deletion-neighbourhood index over normalized words (FD-020).
/// Build off the search path; WP2 owns isolate scheduling and count telemetry.
final class FuzzyIndex {
  new _(this._words, this._eligible, this._deletes, this.distanceTwoEnabled);

  /// Builds with PA11's 12-rune truncation and hard deletion-key bound.
  /// Distance two is dropped above [maxWords] or beyond [maxDeletionKeys].
  factory build(
    Iterable<String> words, {
    int maxWords = 30000,
    int maxDeletionKeys = 400000,
  }) {
    if (maxWords < 0 || maxDeletionKeys < 0) {
      throw ArgumentError('negative bound');
    }
    final vocabulary = words.where((w) => w.isNotEmpty).toSet().toList()
      ..sort();
    final eligible = vocabulary.where((w) => w.runes.length >= 4).toList();
    _DeletionIndex? build({required bool two}) {
      final heads = <String, int>{};
      final wordIds = <int>[];
      final next = <int>[];
      for (var id = 0; id < eligible.length; id++) {
        final word = eligible[id];
        final key = _bounded(word);
        for (final deletion in _neighbours(
          key,
          two && key.runes.length >= 7 ? 2 : 1,
        )) {
          if (!heads.containsKey(deletion) && heads.length == maxDeletionKeys) {
            return null;
          }
          wordIds.add(id);
          next.add(heads[deletion] ?? 0);
          heads[deletion] = wordIds.length;
        }
      }
      return _DeletionIndex(
        heads,
        Uint32List.fromList(wordIds),
        Uint32List.fromList(next),
      );
    }

    var two = vocabulary.length <= maxWords;
    var deletes = build(two: two);
    if (deletes == null && two) {
      two = false;
      deletes = build(two: false);
    }
    // If even distance one exceeds the budget, disable fuzzy atomically.
    // Keeping a vocabulary-order prefix would silently bias retrieval.
    return FuzzyIndex._(vocabulary, eligible, deletes, two && deletes != null);
  }

  final List<String> _words;
  final List<String> _eligible;
  final _DeletionIndex? _deletes;

  /// Whether distance-two corrections fit the configured bounds.
  final bool distanceTwoEnabled;

  /// Retained deletion keys, for content-free budget measurements.
  int get deletionKeyCount => _deletes?.heads.length ?? 0;

  /// Whether a vocabulary word starts with [token], including short words.
  bool isWordPrefix(String token) {
    var low = 0;
    var high = _words.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (_words[middle].compareTo(token) < 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low < _words.length && _words[low].startsWith(token);
  }

  /// Nearest whole words, ordered by OSA distance, length difference, word.
  /// Known prefixes and tokens under four runes deliberately skip fuzzy.
  List<String> corrections(String token, {int limit = 5}) {
    if (limit <= 0 || token.runes.length < 4 || isWordPrefix(token)) return [];
    final key = _bounded(token);
    final max = distanceTwoEnabled && key.runes.length >= 7 ? 2 : 1;
    final possible = <String>{};
    for (final deletion in _neighbours(key, max)) {
      var link = _deletes?.heads[deletion] ?? 0;
      while (link != 0) {
        possible.add(_eligible[_deletes!.wordIds[link - 1]]);
        link = _deletes.next[link - 1];
      }
    }
    final distances = <String, int>{};
    for (final word in possible) {
      final other = _bounded(word);
      final allowed = max == 2 && other.runes.length >= 7 ? 2 : 1;
      final distance = osaDistance(key, other, allowed);
      if (distance <= allowed) distances[word] = distance;
    }
    final matches = distances.keys.toList()
      ..sort((a, b) {
        final distance = distances[a]!.compareTo(distances[b]!);
        if (distance != 0) return distance;
        final length = (a.runes.length - token.runes.length).abs().compareTo(
          (b.runes.length - token.runes.length).abs(),
        );
        return length != 0 ? length : a.compareTo(b);
      });
    return matches.take(limit).toList();
  }
}

String _bounded(String word) => String.fromCharCodes(word.runes.take(12));

Set<String> _neighbours(String word, int distance) {
  final all = {word};
  var frontier = {word};
  for (var depth = 0; depth < distance; depth++) {
    final next = <String>{};
    for (final current in frontier) {
      final runes = current.runes.toList();
      for (var i = 0; i < runes.length; i++) {
        next.add(
          String.fromCharCodes([...runes.take(i), ...runes.skip(i + 1)]),
        );
      }
    }
    all.addAll(next);
    frontier = next;
  }
  return all;
}

// Most deletion keys have only one word. Packed posting chains avoid a Set
// allocation per key, keeping PA11's retained-memory budget practical.
final class _DeletionIndex {
  const new(this.heads, this.wordIds, this.next);

  final Map<String, int> heads;
  final Uint32List wordIds;
  final Uint32List next;
}
