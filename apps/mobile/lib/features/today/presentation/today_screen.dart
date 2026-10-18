import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The Today tab (UX-010). An empty state until the diary lands (HM-*, DY-*).
/// No title bar: the date header of the diary takes its place (backlog #35).
class TodayScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: FbEmptyState(
          icon: FbIcons.today,
          title: l10n.todayEmptyTitle,
          message: l10n.todayPlaceholder,
        ),
      ),
    );
  }
}
