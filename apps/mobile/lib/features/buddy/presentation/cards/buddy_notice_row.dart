import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart' show FoodNames;
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/record_proposal_card.dart'
    show memoryValueText;
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// An offer to remember a repeated answer (AI-065) or a weighing tip
/// (AI-084) under a logged card. Remember saves the default with an Undo;
/// nothing is remembered without the tap.
class BuddyNoticeRow extends ConsumerWidget {
  /// The notice [notice] of turn [turnId].
  const new({required this.turnId, required this.notice, super.key});

  /// The turn.
  final String turnId;

  /// The notice.
  final BuddyNotice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final thread = ref.read(buddyThreadControllerProvider.notifier);
    final food = watchFoodNameInline(ref, FoodNames(notice.subject));
    switch (notice.kind) {
      case BuddyNoticeKind.weigh:
        return FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.buddyNoticeWeigh(food),
          actionLabel: l10n.buddyNoticeNo,
          onAction: () => thread.dismissNotice(turnId, notice.id),
        );
      case BuddyNoticeKind.remember:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            Text(
              l10n.buddyNoticeRemember(
                food,
                memoryValueText(notice.value ?? ''),
              ),
              style: FbType.body,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: FbSpace.s2,
              children: [
                FbButton.text(
                  label: l10n.buddyNoticeNo,
                  onPressed: () => thread.dismissNotice(turnId, notice.id),
                ),
                FbButton.primary(
                  label: l10n.buddyNoticeYes,
                  onPressed: () => unawaited(_remember(context, ref)),
                ),
              ],
            ),
          ],
        );
    }
  }

  Future<void> _remember(BuildContext context, WidgetRef ref) async {
    final message = context.l10n.buddyNoticeRemembered;
    final entry = await ref
        .read(buddyThreadControllerProvider.notifier)
        .rememberNotice(turnId, notice.id);
    if (entry != null && context.mounted) {
      showUndoFeedback(context, message: message, undoEntryId: entry);
    }
  }
}
