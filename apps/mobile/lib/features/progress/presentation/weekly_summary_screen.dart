import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:fb_mobile/features/progress/application/weekly_summary_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:fb_mobile/features/progress/presentation/weekly_summary_card.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Past weekly summaries (IN-001 "any past week", A39a D2): one week at a
/// time with ‹ › between weeks, from the first week with data (workouts
/// included) to this week. Opened from the Progress card's "Past weeks"
/// and by the "weekly summary ready" notification (NT-004, NT-024), at
/// [start]'s week. The week shown is the route's: ‹ › go to the next
/// week's location, so a link always shows its week, even to a screen
/// already open (A40 review 4). Last week's and this week's summary carry
/// this week's check-in, the target proposal NT-004 announces (review 8).
class WeeklySummaryScreen extends ConsumerWidget {
  /// The screen at the week containing [start].
  const new({required this.start, super.key});

  /// A day of the week shown (normally its first day).
  final LocalDate start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(currentWeekStartProvider).value;
    final weekStart = ref.watch(weekStartProvider).value ?? DayOfWeek.saturday;
    final earliest = ref.watch(summaryEarliestDateProvider).value;
    Widget body;
    if (current == null) {
      body = const FbSkeleton.card();
    } else {
      final calendar = WeekCalendar(weekStart: weekStart);
      final asked = calendar.weekStartOf(start);
      // A link to a future week shows this week.
      final shown = asked.isAfter(current) ? current : asked;
      final first = calendar.weekStartOf(earliest ?? current);
      void open(LocalDate week) =>
          ref.read(appNavigatorProvider).go(WeeklySummaryRoute(start: week));
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Row(
            children: [
              FbIconButton(
                key: const ValueKey('weekly-summary-previous'),
                icon: FbIcons.previous,
                tooltip: l10n.progressPeriodPrevious,
                onPressed: shown.isAfter(first)
                    ? () => open(shown.plusDays(-7))
                    : null,
              ),
              Expanded(
                child: Text(
                  dayRange(l10n, shown, shown.plusDays(6)),
                  textAlign: TextAlign.center,
                  style: FbType.title,
                ),
              ),
              FbIconButton(
                key: const ValueKey('weekly-summary-next'),
                icon: FbIcons.next,
                tooltip: l10n.progressPeriodNext,
                onPressed: shown.isBefore(current)
                    ? () => open(shown.plusDays(7))
                    : null,
              ),
            ],
          ),
          WeeklySummaryBlock(weekStart: shown, current: shown == current),
          // This week's check-in reviews the weeks up to last week.
          if (!shown.isBefore(current.plusDays(-7))) const CheckInCard(),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklySummaryTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          FbSpace.s4,
          FbSpace.s2,
          FbSpace.s4,
          FbSpace.s5,
        ),
        children: [body],
      ),
    );
  }
}
