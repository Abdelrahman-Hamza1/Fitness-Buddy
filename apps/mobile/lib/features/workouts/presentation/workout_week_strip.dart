import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The current week on the Workouts tab (A37 D19, WO-024): a filled dot on
/// days with a session; with a weekly plan, today and later planned days
/// show the template's initial, muted (A37c). Past planned days without a
/// session look like any other day: never a "missed" day.
class WorkoutWeekStrip extends ConsumerWidget {
  /// The week containing [today].
  const new({required this.today, super.key});

  /// Today.
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(workoutWeekProvider(today)).value;
    if (week == null) return const SizedBox(height: FbSpace.s7);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.E(locale);
    final full = DateFormat.MMMEd(locale);
    return Row(
      children: [
        for (final day in week.days)
          Expanded(
            child: _Day(
              key: ValueKey('workouts-week-$day'),
              label: weekday.format(DateTime(day.year, day.month, day.day)),
              number: '${day.day}',
              isToday: day == today,
              trained: week.trained.contains(day),
              planned: week.planned[day],
              semantics: switch ((
                week.trained.contains(day),
                week.planned[day],
              )) {
                (true, _) => context.l10n.workoutsWeekTrained(
                  full.format(DateTime(day.year, day.month, day.day)),
                ),
                (false, final name?) => context.l10n.workoutsWeekPlanned(
                  full.format(DateTime(day.year, day.month, day.day)),
                  name,
                ),
                _ => null,
              },
              theme: theme,
            ),
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const new({
    required this.label,
    required this.number,
    required this.isToday,
    required this.trained,
    required this.planned,
    required this.semantics,
    required this.theme,
    super.key,
  });

  final String label;
  final String number;
  final bool isToday;
  final bool trained;

  /// The planned template's name (today and later only), or `null`.
  final String? planned;
  final String? semantics;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final emphasis = isToday ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      label: semantics,
      excludeSemantics: semantics != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: emphasis),
          ),
          Text(
            number,
            style: theme.textTheme.titleSmall?.copyWith(color: emphasis),
          ),
          const SizedBox(height: FbSpace.s1),
          if (!trained && planned != null)
            // The plan hint: the template's initial, muted.
            Text(
              String.fromCharCode(planned!.runes.first).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            SizedBox.square(
              dimension: FbSpace.s2,
              child: trained
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
