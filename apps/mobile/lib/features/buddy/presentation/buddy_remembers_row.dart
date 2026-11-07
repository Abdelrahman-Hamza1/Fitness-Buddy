import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/buddy/application/buddy_summary_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Buddy remembers" in Me › Your data (AI-082, AI-165): opens the screen
/// with everything Buddy remembers and the summary of older chat.
class BuddyRemembersRow extends ConsumerWidget {
  /// The row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(buddySummaryTextProvider).value;
    return FbListRow(
      title: l10n.buddyRemembersTitle,
      subtitle: summary ?? l10n.buddyRemembersOpen,
      trailing: const Icon(FbIcons.next),
      onTap: () =>
          ref.read(appNavigatorProvider).push(const BuddyRemembersRoute()),
    );
  }
}
