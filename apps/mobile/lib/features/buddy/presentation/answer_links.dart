import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The screens a Buddy answer links to (AI-112): one chip each; a tap
/// closes the Buddy sheet and opens the screen (a diary day opens Today on
/// that date).
class AnswerLinks extends ConsumerWidget {
  /// Chips for [links].
  const new({required this.links, super.key});

  /// The links, in order.
  final List<QueryLink> links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Wrap(
      spacing: FbSpace.s2,
      runSpacing: FbSpace.s2,
      children: [
        for (final link in links)
          FbQuickAddChip(
            icon: switch (link.screen) {
              QueryLinkScreen.diary => FbIcons.diary,
              QueryLinkScreen.weightGraph => FbIcons.weight,
              QueryLinkScreen.progress => FbIcons.chart,
              QueryLinkScreen.exercise ||
              QueryLinkScreen.workout => FbIcons.workout,
            },
            label: switch (link.screen) {
              QueryLinkScreen.diary => l10n.buddyLinkDiary,
              QueryLinkScreen.weightGraph => l10n.buddyLinkWeightGraph,
              QueryLinkScreen.progress => l10n.buddyLinkProgress,
              QueryLinkScreen.exercise => l10n.buddyLinkExercise,
              QueryLinkScreen.workout => l10n.buddyLinkWorkout,
            },
            onTap: () => _open(context, ref, link),
          ),
      ],
    );
  }

  static void _open(BuildContext context, WidgetRef ref, QueryLink link) {
    final navigator = ref.read(appNavigatorProvider);
    Navigator.of(context).pop();
    switch (link.screen) {
      case QueryLinkScreen.diary:
        ref.read(todayControllerProvider.notifier).goTo(link.date!);
        navigator.go(const TodayRoute());
      case QueryLinkScreen.weightGraph:
        navigator.push(const WeightGraphRoute());
      case QueryLinkScreen.progress:
        navigator.go(const ProgressRoute());
      case QueryLinkScreen.exercise:
        navigator.push(ProgressExerciseRoute(link.exerciseRef!));
      case QueryLinkScreen.workout:
        navigator.push(WorkoutSessionRoute(id: link.workoutId!));
    }
  }
}
