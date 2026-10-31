import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:material_ui/material_ui.dart';

/// The body-map region of [muscle] (WO-007, A37 D2). Shoulders are the
/// deltoids, drawn on both views; regions on both views light up on both.
FbBodyRegion bodyRegionOf(Muscle muscle) => switch (muscle) {
  Muscle.chest => FbBodyRegion.chest,
  Muscle.shoulders => FbBodyRegion.deltoids,
  Muscle.biceps => FbBodyRegion.biceps,
  Muscle.triceps => FbBodyRegion.triceps,
  Muscle.forearms => FbBodyRegion.forearms,
  Muscle.traps => FbBodyRegion.trapezius,
  Muscle.upperBack => FbBodyRegion.upperBack,
  Muscle.lowerBack => FbBodyRegion.lowerBack,
  Muscle.abs => FbBodyRegion.abs,
  Muscle.obliques => FbBodyRegion.obliques,
  Muscle.quadriceps => FbBodyRegion.quadriceps,
  Muscle.hamstrings => FbBodyRegion.hamstrings,
  Muscle.glutes => FbBodyRegion.glutes,
  Muscle.calves => FbBodyRegion.calves,
  Muscle.adductors => FbBodyRegion.adductors,
};

/// An exercise's muscle map (WO-007): [primary] dark, [secondaries]
/// lighter, the neutral body when there's no primary muscle (A37 D2). Its
/// screen-reader label names the muscles in words.
///
/// [ExerciseMuscleMap.union] shows several exercises together (a session,
/// a workout day; A52 D4).
class ExerciseMuscleMap extends StatelessWidget {
  /// Creates the map of one exercise, [height] dp tall.
  new({
    required Muscle? primary,
    required List<Muscle> secondaries,
    this.height = 160,
    super.key,
  }) : primaries = [?primary],
       secondaries = [
         for (final m in secondaries)
           if (m != primary) m,
       ];

  /// Creates the map of several exercises' [muscles], [height] dp tall.
  new union(MuscleUnion muscles, {this.height = 160, super.key})
    : primaries = muscles.primary,
      secondaries = muscles.secondary;

  /// A list row's map (picker, plan day rows).
  static const double rowHeight = 44;

  /// An exercise card's map in the log form (≈56 dp, D-089).
  static const double cardHeight = 56;

  /// The main muscles (none: "no primary muscle").
  final List<Muscle> primaries;

  /// The secondary muscles, never in [primaries].
  final List<Muscle> secondaries;

  /// The height of the bodies.
  final double height;

  /// The main muscle of a one-exercise map, or `null`.
  Muscle? get primary => primaries.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = secondaries.map(l10n.muscle).join(', ');
    final mains = primaries.map(l10n.muscle).join(', ');
    final label = switch ((primaries.length, secondaries.isEmpty)) {
      (0, true) => l10n.workoutMuscleMapNone,
      (0, false) => l10n.workoutMuscleMapNoneSecondary(names),
      (1, true) => l10n.workoutMuscleMapMain(mains),
      (1, false) => l10n.workoutMuscleMapMainSecondary(mains, names),
      (_, true) => l10n.workoutMuscleMapMains(mains),
      (_, false) => l10n.workoutMuscleMapMainsSecondary(mains, names),
    };
    return FbMuscleMap(
      primary: {for (final m in primaries) bodyRegionOf(m)},
      secondary: {for (final m in secondaries) bodyRegionOf(m)},
      semanticLabel: label,
      height: height,
    );
  }
}
