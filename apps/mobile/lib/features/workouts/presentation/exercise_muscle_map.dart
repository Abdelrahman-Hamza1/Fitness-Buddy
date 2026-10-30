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
class ExerciseMuscleMap extends StatelessWidget {
  /// Creates the map, [height] dp tall.
  const new({
    required this.primary,
    required this.secondaries,
    this.height = 160,
    super.key,
  });

  /// The main muscle, or `null` ("no primary muscle").
  final Muscle? primary;

  /// The secondary muscles.
  final List<Muscle> secondaries;

  /// The height of the bodies.
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = this.primary;
    final others = [
      for (final m in secondaries)
        if (m != primary) m,
    ];
    final names = others.map(l10n.muscle).join(', ');
    final label = switch ((primary, others.isEmpty)) {
      (final Muscle p, true) => l10n.workoutMuscleMapMain(l10n.muscle(p)),
      (final Muscle p, false) => l10n.workoutMuscleMapMainSecondary(
        l10n.muscle(p),
        names,
      ),
      (null, true) => l10n.workoutMuscleMapNone,
      (null, false) => l10n.workoutMuscleMapNoneSecondary(names),
    };
    return FbMuscleMap(
      primary: {if (primary != null) bodyRegionOf(primary)},
      secondary: {for (final m in others) bodyRegionOf(m)},
      semanticLabel: label,
      height: height,
    );
  }
}
