import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/today/application/today_slide.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Today's three summaries share one session-only selection across day pages.
class TodaySlideCard extends ConsumerWidget {
  /// Creates the component with localized labels and session state.
  const new({
    required this.date,
    required this.isToday,
    required this.totals,
    super.key,
  });

  /// Final height at normal text; every slide shares the resolved height.
  static const double baseHeight = 256;

  /// The viewed day.
  final LocalDate date;

  /// Whether this is the current day.
  final bool isToday;

  /// Stored nutrition totals for the viewed day.
  final Nutrients totals;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(todaySlideProvider);
    final l10n = context.l10n;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    // Resolve once, growing smoothly through 1.3/1.4 without a height cliff.
    final height = baseHeight + (400 - baseHeight) * (scale - 1);
    Widget content(Widget child) =>
        SingleChildScrollView(primary: false, child: child);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
      child: FbSlideCard(
        index: index,
        height: height,
        semanticLabel: l10n.todaySlideSemantics,
        onIndexChanged: ref.read(todaySlideProvider.notifier).select,
        slides: [
          FbSlide(
            label: l10n.todaySlideNutrition,
            builder: (_) => content(
              TodayNumbers(date: date, isToday: isToday, totals: totals),
            ),
          ),
          FbSlide(
            label: l10n.todaySlideWeight,
            builder: (_) => content(
              WeightSlide(date: date, isToday: isToday, selected: index == 1),
            ),
          ),
          FbSlide(
            label: l10n.todaySlideWorkout,
            builder: (_) => content(WorkoutSlide(date: date)),
          ),
        ],
      ),
    );
  }
}
