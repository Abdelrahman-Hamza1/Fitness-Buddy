import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The workout half of Today's slim line (HM-006, D-093, A57 D4): the
/// day's logged session ("Push done", tap opens it), else today's planned
/// workout ("Push today", tap starts it), else "Log workout", which starts
/// a free session on the viewed day. Never a last session or a missed-plan
/// note. Loading and a read error keep the same height ([FbGlanceTile]);
/// the error's tap retries.
class WorkoutGlance extends ConsumerWidget {
  /// Creates the half for [date].
  const new({required this.date, super.key});

  /// The viewed day.
  final LocalDate date;

  static const ValueKey<String> _key = ValueKey('today-glance-workout');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(todayWorkoutProvider(date));
    final row = value.value;
    if (row == null) {
      if (value.hasError) {
        return FbGlanceTile(
          key: _key,
          icon: FbIcons.workout,
          text: l10n.todayGlanceUnavailable,
          muted: true,
          semanticLabel: l10n.todayGlanceWorkoutUnavailable,
          onTap: () => ref.invalidate(todayWorkoutProvider(date)),
        );
      }
      return const FbGlanceTile.loading(key: _key);
    }
    final navigator = ref.read(appNavigatorProvider);
    return switch (row) {
      TodayWorkoutLogged(:final summary) => FbGlanceTile(
        key: _key,
        icon: FbIcons.check,
        text: l10n.todayGlanceWorkoutDone(l10n.sessionTitle(summary.title)),
        semanticLabel: l10n.todayGlanceWorkoutDoneSemantics(
          l10n.sessionTitle(summary.title),
        ),
        onTap: () => navigator.push(TodayWorkoutSessionRoute(id: summary.id)),
      ),
      TodayWorkoutPlanned(:final template) => FbGlanceTile(
        key: _key,
        icon: FbIcons.workout,
        text: l10n.todayGlanceWorkoutPlanned(template.draft.name),
        semanticLabel: l10n.todayGlanceWorkoutPlannedSemantics(
          template.draft.name,
        ),
        onTap: () => navigator.push(
          TodayWorkoutLogRoute(date: date, template: template.ref.id),
        ),
      ),
      TodayWorkoutLast() || TodayWorkoutNone() => FbGlanceTile(
        key: _key,
        icon: FbIcons.workout,
        text: l10n.todayGlanceWorkoutLog,
        onTap: () => navigator.push(TodayWorkoutLogRoute(date: date)),
      ),
    };
  }
}
