import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/today/presentation/today_glance_line.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:material_ui/material_ui.dart';

/// Today's top (HM-001–003, HM-005, D-093, A57 D2): the calories card with
/// the day's numbers, then the slim weight | workout line under it. No
/// slides and no inner pager, so a swipe that starts on the card changes
/// the day (HM-009).
class TodaySummaryCard extends StatelessWidget {
  /// Creates the top of [date]'s page for the day's [intake].
  const new({
    required this.date,
    required this.isToday,
    required this.intake,
    super.key,
  });

  /// The viewed day.
  final LocalDate date;

  /// Whether [date] is today.
  final bool isToday;

  /// The sum of the day's stored snapshots, knowledge-aware (A62).
  final IntakeTotals intake;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      FbSpace.s4,
      FbSpace.s2,
      FbSpace.s4,
      FbDensity.cardGap,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s1,
      children: [
        FbCard(
          key: const ValueKey('today-summary-card'),
          child: TodayNumbers(date: date, isToday: isToday, intake: intake),
        ),
        TodayGlanceLine(date: date, isToday: isToday),
      ],
    ),
  );
}
