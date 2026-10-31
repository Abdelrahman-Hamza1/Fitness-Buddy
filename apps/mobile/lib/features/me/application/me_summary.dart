import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'me_summary.g.dart';

/// What Me's targets summary shows (A51): today's calorie and protein
/// targets and the goal in effect. Content-free [toString].
final class MeTargetsSummary {
  /// The summary.
  const new({required this.kcal, this.proteinGrams, this.goal});

  /// Today's calorie target.
  final double kcal;

  /// Today's protein target, or null without one.
  final double? proteinGrams;

  /// The goal in effect today, or null in a gap.
  final GoalType? goal;

  @override
  String toString() => 'MeTargetsSummary';
}

/// Today's targets for Me, or null before setup (or with no version in
/// effect today). Follows every targets change.
@riverpod
Future<MeTargetsSummary?> meTargetsSummary(Ref ref) async {
  final today = ref.watch(targetsTodayProvider);
  final dataFuture = ref.watch(targetsDataProvider.future);
  final day = await ref.watch(dayTargetsProvider(today).future);
  if (day == null) return null;
  final data = await dataFuture;
  final phase = TargetsTimeline.phaseOn([
    for (final p in data.phases) p.value,
  ], today);
  return MeTargetsSummary(
    kcal: day.day.kcal,
    proteinGrams: day.day.macros.proteinGrams,
    goal: phase?.type,
  );
}
