import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The Workouts tab (UX-010). An empty state until workouts land (WO-*).
class WorkoutsScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabWorkouts)),
      body: FbEmptyState(
        // FbIcons has no workouts icon yet.
        icon: FbIcons.empty,
        title: l10n.workoutsEmptyTitle,
        message: l10n.workoutsPlaceholder,
      ),
    );
  }
}
