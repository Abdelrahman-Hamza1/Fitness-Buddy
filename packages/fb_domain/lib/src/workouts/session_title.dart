import 'package:fb_domain/src/workouts/muscle.dart';

/// What a session is called on screen (WO-010, A37 D10). Computed at
/// display, never stored; the app maps each case to an ARB string.
sealed class SessionTitle {
  const new _();
}

/// The session's own name ("Push"): it always wins.
final class NamedTitle extends SessionTitle {
  /// Named [name].
  const new(this.name) : super._();

  /// The name. User content: never logged.
  final String name;

  @override
  bool operator ==(Object other) => other is NamedTitle && other.name == name;

  @override
  int get hashCode => Object.hash(NamedTitle, name);

  @override
  String toString() => 'NamedTitle';
}

/// Named from its main muscle groups: one ("Chest") or two in order
/// ("Chest & triceps").
final class MuscleGroupsTitle extends SessionTitle {
  /// Named from [groups] (one or two).
  new(Iterable<MuscleGroup> groups)
    : groups = List.unmodifiable(groups),
      super._() {
    if (this.groups.isEmpty || this.groups.length > 2) {
      throw ArgumentError.value(this.groups, 'groups', 'one or two');
    }
  }

  /// The groups, most trained first.
  final List<MuscleGroup> groups;

  @override
  bool operator ==(Object other) =>
      other is MuscleGroupsTitle &&
      other.groups.length == groups.length &&
      other.groups.first == groups.first &&
      other.groups.last == groups.last;

  @override
  int get hashCode => Object.hash(MuscleGroupsTitle, Object.hashAll(groups));

  @override
  String toString() => 'MuscleGroupsTitle(${groups.map((g) => g.name)})';
}

/// Many groups, none dominant: "Full body".
final class FullBodyTitle extends SessionTitle {
  /// The full-body title.
  const new() : super._();

  @override
  bool operator ==(Object other) => other is FullBodyTitle;

  @override
  int get hashCode => (FullBodyTitle).hashCode;

  @override
  String toString() => 'FullBodyTitle';
}

/// Only cardio: "Cardio".
final class CardioTitle extends SessionTitle {
  /// The cardio title.
  const new() : super._();

  @override
  bool operator ==(Object other) => other is CardioTitle;

  @override
  int get hashCode => (CardioTitle).hashCode;

  @override
  String toString() => 'CardioTitle';
}

/// Nothing to name it from: "Workout".
final class UntitledTitle extends SessionTitle {
  /// The fallback title.
  const new() : super._();

  @override
  bool operator ==(Object other) => other is UntitledTitle;

  @override
  int get hashCode => (UntitledTitle).hashCode;

  @override
  String toString() => 'UntitledTitle';
}

/// One exercise as naming sees it: its main muscle (`null` when it has
/// none, or the exercise is unknown), whether it's cardio (its type logs
/// duration and distance), and how many sets it has.
typedef NamingExercise = ({Muscle? primary, bool isCardio, int sets});

/// Names sessions from their muscles (WO-010, D-085, A37 D10).
abstract final class SessionNaming {
  /// The share of sets above which one group names the session alone.
  static const double dominantShare = 0.7;

  /// The share of sets the top two groups must reach, with four or more
  /// groups, to avoid "Full body".
  static const double topTwoShare = 0.6;

  /// The title of a session called [name] (`null` or blank: none) with
  /// [exercises] in order.
  ///
  /// An explicit name wins. Otherwise the main muscle groups of the
  /// strength exercises are ranked by set count (ties: first appearance;
  /// exercises without a main muscle are ignored): a group with at least
  /// 70 % of the sets names it alone; four or more groups whose top two
  /// have less than 60 % give "Full body"; else the top two. Cardio is
  /// ignored beside strength; only cardio gives "Cardio"; nothing gives
  /// "Workout".
  static SessionTitle titleOf(String? name, List<NamingExercise> exercises) {
    if (name != null && name.trim().isNotEmpty) return NamedTitle(name.trim());
    final setsByGroup = <MuscleGroup, int>{};
    var cardio = false;
    for (final exercise in exercises) {
      if (exercise.sets <= 0) continue;
      if (exercise.isCardio) {
        cardio = true;
        continue;
      }
      final group = exercise.primary?.group;
      if (group == null) continue;
      setsByGroup[group] = (setsByGroup[group] ?? 0) + exercise.sets;
    }
    if (setsByGroup.isEmpty) {
      return cardio ? const CardioTitle() : const UntitledTitle();
    }
    // A map keeps insertion order: ties go to the group that appeared first.
    final order = setsByGroup.keys.toList();
    final ranked = setsByGroup.entries.toList()
      ..sort((a, b) {
        final bySets = b.value.compareTo(a.value);
        return bySets != 0
            ? bySets
            : order.indexOf(a.key).compareTo(order.indexOf(b.key));
      });
    final total = ranked.fold(0, (sum, e) => sum + e.value);
    if (ranked.first.value >= dominantShare * total) {
      return MuscleGroupsTitle([ranked.first.key]);
    }
    final topTwo = ranked[0].value + ranked[1].value;
    if (ranked.length >= 4 && topTwo < topTwoShare * total) {
      return const FullBodyTitle();
    }
    return MuscleGroupsTitle([ranked[0].key, ranked[1].key]);
  }
}
