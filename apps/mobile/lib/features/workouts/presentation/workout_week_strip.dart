import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The current week on the Workouts tab (A37 D19, WO-024, D-089): "This
/// week · 2 workouts" over the seven days, trained days filled, today
/// outlined. Planned days are named only for a screen reader; past planned
/// days without a session look like any other day: never a "missed" day.
class WorkoutWeekStrip extends ConsumerWidget {
  /// The week containing [today].
  const new({required this.today, super.key});

  /// Today.
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(workoutWeekProvider(today)).value;
    if (week == null) return const SizedBox(height: FbSpace.s7 * 2);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.E(locale);
    final full = DateFormat.MMMEd(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.workoutsThisWeek, style: FbType.title)),
            Text(
              l10n.workoutsWeekCount(week.sessionCount),
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        Row(
          children: [
            for (final day in week.days)
              Expanded(
                child: _Day(
                  key: ValueKey('workouts-week-$day'),
                  label: weekday.format(DateTime(day.year, day.month, day.day)),
                  number: '${day.day}',
                  isToday: day == today,
                  trained: week.trained.contains(day),
                  semantics: switch ((
                    week.trained.contains(day),
                    week.planned[day],
                  )) {
                    (true, _) => l10n.workoutsWeekTrained(
                      full.format(DateTime(day.year, day.month, day.day)),
                    ),
                    (false, final name?) => l10n.workoutsWeekPlanned(
                      full.format(DateTime(day.year, day.month, day.day)),
                      name,
                    ),
                    _ => null,
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A day's circle: 34 dp, filled when trained, outlined when today.
const double _dayCircle = 34;

class _Day extends StatelessWidget {
  const new({
    required this.label,
    required this.number,
    required this.isToday,
    required this.trained,
    required this.semantics,
    super.key,
  });

  final String label;
  final String number;
  final bool isToday;
  final bool trained;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = switch ((trained, isToday)) {
      (true, _) => scheme.onPrimary,
      (false, true) => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
    return Semantics(
      label: semantics,
      excludeSemantics: semantics != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: FbSpace.s1,
        children: [
          Text(
            label,
            style: FbType.caption.copyWith(color: scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
          Container(
            width: _dayCircle,
            height: _dayCircle,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: trained ? scheme.primary : null,
              border: Border.all(
                color: trained || isToday
                    ? scheme.primary
                    : scheme.outlineVariant,
                width: isToday ? 2 : 1,
              ),
            ),
            padding: const EdgeInsetsDirectional.all(FbSpace.s1),
            // Large text grows up to the circle, never past it.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                number,
                style: FbType.label.copyWith(color: colour),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
