import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The Workouts tab (UX-010). A placeholder until workouts land (WO-*).
class WorkoutsScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabWorkouts)),
      body: Center(
        child: Padding(
          // S07 replaces this with a design-system spacing token.
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
          child: Text(l10n.workoutsPlaceholder, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
