import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The selected bar's details (A16 D11): the date, eaten / target kcal, the
/// macros and how the day counts; a day offers Mark day incomplete or
/// Count this day again (DY-004), a direct action with Undo. A weekly or
/// monthly bar says how many days it averages.
class ProgressDayDetails extends ConsumerWidget {
  /// Creates the details of [bucket].
  const new({required this.bucket, super.key});

  /// The selected bar.
  final ProgressBucket bucket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final eaten = bucket.avgEaten;
    final target = bucket.avgTargetKcal;
    final status = bucket.status;
    final daily = bucket.size == ProgressBucketSize.day;
    return Container(
      key: const ValueKey('progress-day-details'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: FbRadius.mdAll,
      ),
      padding: const EdgeInsetsDirectional.all(FbSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s1,
        children: [
          Text(bucketName(l10n, bucket), style: FbType.label),
          if (eaten == null)
            Text(l10n.progressDetailsNothing, style: FbType.body)
          else ...[
            Text(
              target == null
                  ? l10n.progressDetailsKcalNoTarget(
                      kcalNumber(l10n, eaten.kcal),
                    )
                  : l10n.progressDetailsKcal(
                      kcalNumber(l10n, eaten.kcal),
                      kcalNumber(l10n, target),
                    ),
              style: FbType.title,
            ),
            Text(
              l10n.progressDetailsMacros(
                gramsNumber(l10n, eaten.protein),
                gramsNumber(l10n, eaten.carbs),
                gramsNumber(l10n, eaten.fat),
                gramsNumber(l10n, eaten.fiber),
              ),
              style: muted,
            ),
          ],
          if (!daily) ...[
            Text(l10n.progressDetailsAverage(bucket.countedDays), style: muted),
            if (bucket.uncountedDays > 0)
              Text(
                l10n.progressDetailsUncounted(bucket.uncountedDays),
                style: muted,
              ),
          ],
          if (status == DayStatus.incomplete)
            Text(l10n.progressDetailsNotCounted, style: muted),
          if (status == DayStatus.inProgress)
            Text(l10n.progressDetailsSoFar, style: muted),
          if (daily)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: status == DayStatus.incomplete
                  ? FbButton.secondary(
                      key: const ValueKey('progress-count-again'),
                      label: l10n.diaryCountAgain,
                      onPressed: () => markDayWithUndo(
                        context,
                        bucket.start,
                        incomplete: false,
                      ),
                    )
                  : FbButton.secondary(
                      key: const ValueKey('progress-mark-incomplete'),
                      label: l10n.diaryMarkIncomplete,
                      onPressed: () => markDayWithUndo(
                        context,
                        bucket.start,
                        incomplete: true,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
