import 'package:fb_mobile/features/body/body.dart' show weightTrendProvider;
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/application/ramadan_comparison_provider.dart';
import 'package:fb_mobile/features/progress/application/weekly_summary_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/workouts/workouts.dart'
    show trainingShiftProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

/// "Try again" on any Progress section (UX-052, A16 review round 2): the
/// tab's providers don't retry on their own, so a failure stays cached in
/// whichever one failed. Invalidating only the section's own provider would
/// re-read the failed upstream value, so every provider the sections derive
/// from is refreshed together, down to the weigh-ins' trend, the goal
/// history, the training plan's shift and the targets' intake reads (#220).
void retryProgress(WidgetRef ref) => <ProviderOrFamily>[
  progressLogsProvider,
  progressDaysProvider,
  progressEarliestDateProvider,
  progressViewProvider,
  weeklySummaryProvider,
  weightGraphProvider,
  goalProgressCardProvider,
  progressWeightProvider,
  ramadanComparisonProvider,
  weightTrendProvider,
  trainingShiftProvider,
  ...progressStreamProviders,
  ...targetsRetryProviders,
].forEach(ref.invalidate);
