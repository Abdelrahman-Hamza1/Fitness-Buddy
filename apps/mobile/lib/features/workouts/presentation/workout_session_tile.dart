import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:material_ui/material_ui.dart';

/// One session in a list (WO-040): a small map of its muscles (D-089), its
/// title (D10), counts and a plain PR marker (WO-042), with an optional
/// [trailing] action (Repeat).
class WorkoutSessionTile extends StatelessWidget {
  /// The tile of [summary].
  const new({
    required this.summary,
    required this.onTap,
    this.subtitlePrefix,
    this.trailing,
    super.key,
  });

  /// The session.
  final SessionSummary summary;

  /// Opens it.
  final VoidCallback onTap;

  /// Text before the counts (the day, on the Workouts tab).
  final String? subtitlePrefix;

  /// An action at the end.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Large text needs the row's width for the words: the map steps back.
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= _mapMaxScale;
    return FbListRow(
      leading: roomy
          ? ExerciseMuscleMap.union(
              summary.muscles,
              height: ExerciseMuscleMap.rowHeight,
            )
          : null,
      title: l10n.sessionTitle(summary.title),
      subtitle: [
        ?subtitlePrefix,
        l10n.workoutSessionSummary(summary.exerciseCount, summary.setCount),
        if (summary.prCount > 0) l10n.workoutPrCount(summary.prCount),
      ].join(' · '),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Above this text scale a session row shows no map.
const double _mapMaxScale = 1.3;
