import 'package:fb_domain/src/food/search/name_matcher.dart';
import 'package:fb_domain/src/workouts/muscle.dart';

/// An exercise as the picker searches it (WO-001, A37 D12): built-in or
/// custom, with caller-normalized name keys (display name first, then
/// every alias).
final class SearchableExercise {
  /// Exercise [id] with normalized [keys].
  new({
    required this.id,
    required Iterable<String> keys,
    required this.group,
    required this.isCardio,
  }) : keys = List.unmodifiable(keys);

  /// A catalog ID or a custom exercise's UUID.
  final String id;

  /// Normalized name and alias keys. User content for custom exercises:
  /// never logged.
  final List<String> keys;

  /// The main muscle's group, or `null` when it has none.
  final MuscleGroup? group;

  /// Whether its type is cardio (duration and distance).
  final bool isCardio;

  @override
  String toString() => 'SearchableExercise($id)';
}

/// A picker chip (A37 D12): every exercise, one muscle group, or cardio.
sealed class ExerciseFilter {
  const new _();

  /// No filter: every exercise, including those without a main muscle.
  static const ExerciseFilter all = AllExercises._();

  /// Cardio exercises (a type, not a muscle).
  static const ExerciseFilter cardio = CardioExercises._();

  /// Exercises whose main muscle is in [group].
  static ExerciseFilter group(MuscleGroup group) => GroupExercises._(group);

  /// Whether [exercise] passes.
  bool accepts(SearchableExercise exercise);
}

/// See [ExerciseFilter.all].
final class AllExercises extends ExerciseFilter {
  const new _() : super._();

  @override
  bool accepts(SearchableExercise exercise) => true;
}

/// See [ExerciseFilter.cardio].
final class CardioExercises extends ExerciseFilter {
  const new _() : super._();

  @override
  bool accepts(SearchableExercise exercise) => exercise.isCardio;
}

/// See [ExerciseFilter.group].
final class GroupExercises extends ExerciseFilter {
  const new _(this.group) : super._();

  /// The muscle group.
  final MuscleGroup group;

  @override
  bool accepts(SearchableExercise exercise) => exercise.group == group;

  @override
  bool operator ==(Object other) =>
      other is GroupExercises && other.group == group;

  @override
  int get hashCode => Object.hash(GroupExercises, group);
}

/// In-memory exercise search for the picker (WO-001, A37 D12): about 300
/// names, so no index. Keys are normalized by the caller (`fb_text`).
abstract final class ExerciseSearch {
  /// The [candidates] that pass [filter] and match [queryKey] (a normalized
  /// query, split into words on spaces), best first: a name or alias that
  /// starts with the query, then one whose words start with every token,
  /// then a substring. Ties keep the candidates' order. An empty query
  /// returns every candidate that passes [filter], in order.
  static List<SearchableExercise> search(
    String queryKey,
    Iterable<SearchableExercise> candidates, {
    ExerciseFilter filter = ExerciseFilter.all,
  }) {
    final passing = candidates.where(filter.accepts);
    final key = queryKey.trim();
    if (key.isEmpty) return passing.toList();
    final tokens = key.split(' ').where((t) => t.isNotEmpty).toList();
    final ranked = <(SearchableExercise, int, int)>[];
    var order = 0;
    for (final exercise in passing) {
      final rank = _rank(key, tokens, exercise.keys);
      if (rank != null) ranked.add((exercise, rank, order));
      order++;
    }
    ranked.sort((a, b) {
      final byRank = b.$2.compareTo(a.$2);
      return byRank != 0 ? byRank : a.$3.compareTo(b.$3);
    });
    return [for (final r in ranked) r.$1];
  }

  /// 3 prefix (or exact), 2 word prefixes, 1 substring, `null` no match.
  static int? _rank(String key, List<String> tokens, List<String> names) {
    int? best;
    for (final name in names) {
      final rank = switch (NameMatcher.match(key, tokens, name)) {
        MatchStrength.exact || MatchStrength.prefix => 3,
        MatchStrength.words || MatchStrength.fuzzy => 2,
        MatchStrength.substring => 1,
        MatchStrength.partial || null => null,
      };
      if (rank != null && (best == null || rank > best)) best = rank;
    }
    return best;
  }
}
