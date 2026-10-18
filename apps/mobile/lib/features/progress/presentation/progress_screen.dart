import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The Progress tab (UX-010). An empty state until charts and summaries land
/// (IN-*).
class ProgressScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProgress)),
      body: FbEmptyState(
        icon: FbIcons.progress,
        title: l10n.progressEmptyTitle,
        message: l10n.progressPlaceholder,
      ),
    );
  }
}
