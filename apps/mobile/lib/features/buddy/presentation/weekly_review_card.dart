import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/weekly/weekly_review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Buddy's weekly review on top of a weekly summary (IN-001, AI-130–132,
/// A68 D6): the stored review of the week; for the just-finished week
/// ([writes]) it's written once when missing, while the local summary
/// below shows at once. Nothing shows for a week without a review.
class WeeklyReviewCard extends ConsumerWidget {
  /// The review of the week from [weekStart] with its [summary] (null while
  /// it loads); [fromKcal]/[toKcal] is this week's pending check-in.
  const new({
    required this.weekStart,
    required this.summary,
    required this.writes,
    this.fromKcal,
    this.toKcal,
    super.key,
  });

  /// The week's first day.
  final LocalDate weekStart;

  /// The week's aggregates, or null while loading.
  final WeeklySummary? summary;

  /// Whether a missing review may be written now (the week just ended).
  final bool writes;

  /// This week's check-in: the current base target…
  final double? fromKcal;

  /// …and the proposed one.
  final double? toKcal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stored = ref.watch(weeklyReviewProvider(weekStart));
    final writing = ref.watch(weeklyReviewWriterProvider(weekStart));
    final summary = this.summary;
    void write({bool retry = false}) {
      if (summary == null) return;
      unawaited(
        ref
            .read(weeklyReviewWriterProvider(weekStart).notifier)
            .write(summary, fromKcal: fromKcal, toKcal: toKcal, retry: retry),
      );
    }

    final text = stored.value;
    if (text != null) {
      return FbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FbSpace.s2,
          children: [
            Row(
              spacing: FbSpace.s2,
              children: [
                const FbBuddyAvatar(size: 24),
                Expanded(
                  child: Text(l10n.weeklyReviewTitle, style: FbType.label),
                ),
              ],
            ),
            Text(text, style: FbType.body),
          ],
        ),
      );
    }
    if (!writes || summary == null || summary.isEmpty || !stored.hasValue) {
      return const SizedBox.shrink();
    }
    switch (writing) {
      case WeeklyReviewWriting.idle:
        WidgetsBinding.instance.addPostFrameCallback((_) => write());
        return const SizedBox.shrink();
      case WeeklyReviewWriting.written:
        return const SizedBox.shrink();
      case WeeklyReviewWriting.writing:
        return FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.weeklyReviewWriting,
        );
      case WeeklyReviewWriting.failed:
        return FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.weeklyReviewFailed,
          actionLabel: l10n.commonTryAgain,
          onAction: () => write(retry: true),
        );
    }
  }
}
