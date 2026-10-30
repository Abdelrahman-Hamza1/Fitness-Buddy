import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Progress tab (UX-010). Until the Progress layout (A16): a Weight row
/// that opens the weight graph (UX-013), over an empty state.
class ProgressScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProgress)),
      body: ListView(
        children: [
          FbListRow(
            leading: const Icon(FbIcons.chart),
            title: l10n.weightGraphTitle,
            trailing: const Icon(FbIcons.next),
            onTap: () =>
                ref.read(appNavigatorProvider).push(const WeightGraphRoute()),
          ),
          FbEmptyState(
            icon: FbIcons.progress,
            title: l10n.progressEmptyTitle,
            message: l10n.progressPlaceholder,
          ),
        ],
      ),
    );
  }
}
