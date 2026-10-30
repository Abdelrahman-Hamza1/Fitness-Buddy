import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Try again" on any Progress section (UX-052, A16 review round 2): the
/// tab's providers don't retry on their own, so a failure stays cached in
/// whichever one failed. Invalidating only the section's own provider would
/// re-read the failed upstream value, so every derived provider the
/// sections share is refreshed together; the stored data streams beneath
/// them are untouched.
void retryProgress(WidgetRef ref) => ref
  ..invalidate(progressLogsProvider)
  ..invalidate(progressDaysProvider)
  ..invalidate(progressEarliestDateProvider)
  ..invalidate(progressViewProvider)
  ..invalidate(dayTargetsProvider)
  ..invalidate(weekGlanceProvider)
  ..invalidate(weightGraphProvider)
  ..invalidate(goalProgressCardProvider)
  ..invalidate(progressWeightProvider);
