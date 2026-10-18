import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The four-tab shell: Today, Progress, Workouts, Me (UX-010).
///
/// Router-agnostic: the router passes the selected tab, the tab callback and
/// the current tab's content ([child]). The tab order here is the router's
/// branch order (`AppRouter`).
class AppShell extends StatelessWidget {
  /// Creates the shell.
  const new({
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
    super.key,
  });

  /// Index of the selected tab: 0 Today, 1 Progress, 2 Workouts, 3 Me.
  final int currentIndex;

  /// Called with the index of the tab the user tapped.
  final ValueChanged<int> onTabSelected;

  /// The selected tab's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(FbIcons.navToday),
            selectedIcon: const Icon(FbIcons.navTodaySelected),
            label: l10n.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(FbIcons.navProgress),
            selectedIcon: const Icon(FbIcons.navProgressSelected),
            label: l10n.tabProgress,
          ),
          NavigationDestination(
            icon: const Icon(FbIcons.navWorkouts),
            selectedIcon: const Icon(FbIcons.navWorkoutsSelected),
            label: l10n.tabWorkouts,
          ),
          NavigationDestination(
            icon: const Icon(FbIcons.navMe),
            selectedIcon: const Icon(FbIcons.navMeSelected),
            label: l10n.tabMe,
          ),
        ],
      ),
    );
  }
}
