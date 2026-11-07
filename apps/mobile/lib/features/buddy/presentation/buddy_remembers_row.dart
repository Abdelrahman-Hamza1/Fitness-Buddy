import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/buddy_summary_view.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Buddy remembers" in Me › Your data (AI-165, A66 D13): the summary of
/// older chat, shown and clearable. The full screen comes with A67.
class BuddyRemembersRow extends ConsumerWidget {
  /// The row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(buddySummaryTextProvider).value;
    return FbListRow(
      title: l10n.buddyRemembersTitle,
      subtitle: summary ?? l10n.buddyRemembersEmpty,
      trailingAction: summary == null
          ? null
          : FbButton.text(
              label: l10n.buddyRemembersClear,
              onPressed: () => unawaited(_clear(context, ref)),
            ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showFbSheet<bool>(
      context,
      title: l10n.buddyRemembersTitle,
      builder: (context) => Text(l10n.buddyRemembersClearBody),
      actionsBuilder: (context) => Row(
        children: [
          Expanded(
            child: FbButton.secondary(
              label: l10n.buddyCancel,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: FbSpace.s3),
          Expanded(
            child: FbButton.destructive(
              label: l10n.buddyRemembersClear,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(buddyThreadControllerProvider.notifier).clearSummary();
  }
}
