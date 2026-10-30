import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/presentation/calories_section.dart';
import 'package:fb_mobile/features/progress/presentation/goal_progress_card.dart';
import 'package:fb_mobile/features/progress/presentation/macros_section.dart';
import 'package:fb_mobile/features/progress/presentation/progress_period_bar.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/progress/presentation/progress_week_header.dart';
import 'package:fb_mobile/features/progress/presentation/weight_section.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Progress tab (UX-010, IN-002–IN-009, SC-5): opens on this week. An
/// ordered list of sections (A16 D13): the current-week card → the period
/// selector → calories (+ the selected bar's details) → macros → weight →
/// goal progress → Measurements → exercise progress (A37c) → [A38: the
/// expenditure chart]. Later steps add one entry. Local data only: no
/// spinner beyond skeleton cards, errors inline with Try again (UX-050–052).
/// No streaks, scores or micronutrients (IN-020, IN-021).
class ProgressScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the background the day (or the zone) may have changed.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = ref.watch(progressViewProvider);
    const gap = SizedBox(height: FbDensity.cardGap);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProgress)),
      // A re-tap of the tab scrolls this list to the top (A45 D13).
      body: ScrollToTopOnTabReselect(
        tab: AppTab.progress,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            FbSpace.s4,
            FbSpace.s2,
            FbSpace.s4,
            FbSpace.s5,
          ),
          children: [
            const ProgressWeekHeader(),
            gap,
            ...switch (view) {
              AsyncData(:final value) => [
                ProgressPeriodBar(view: value),
                gap,
                CaloriesSection(view: value),
                gap,
                MacrosSection(view: value),
              ],
              AsyncError() => [
                FbInlineBanner(
                  kind: FbInlineBannerKind.error,
                  message: l10n.progressLoadFailed,
                  actionLabel: l10n.weightGraphTryAgain,
                  onAction: () => retryProgress(ref),
                ),
              ],
              _ => const [
                FbSkeleton.card(height: 104),
                gap,
                FbSkeleton.card(height: 240),
              ],
            },
            gap,
            const WeightSection(),
            gap,
            const GoalProgressCard(),
            gap,
            FbCard(
              padding: EdgeInsetsDirectional.zero,
              child: FbListRow(
                key: const ValueKey('progress-measurements'),
                leading: const Icon(FbIcons.progress),
                title: l10n.measurementsTitle,
                trailing: const Icon(FbIcons.next),
                onTap: () => ref
                    .read(appNavigatorProvider)
                    .push(const MeasurementsRoute()),
              ),
            ),
            gap,
            // Exercise progress (IN-006, A37 D13): every exercise's page.
            FbCard(
              padding: EdgeInsetsDirectional.zero,
              child: FbListRow(
                key: const ValueKey('progress-exercises'),
                leading: const Icon(FbIcons.navWorkouts),
                title: l10n.progressExercises,
                trailing: const Icon(FbIcons.next),
                onTap: () => ref
                    .read(appNavigatorProvider)
                    .push(const ProgressExercisesRoute()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
