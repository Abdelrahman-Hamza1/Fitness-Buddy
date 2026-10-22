import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Today tab (UX-010). An empty state until the diary lands (HM-*, DY-*),
/// with the way into the add-food search (A07; A08 adds "+" per slot).
/// No title bar: the date header of the diary takes its place (backlog #35).
class TodayScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: FbEmptyState(
          icon: FbIcons.today,
          title: l10n.todayEmptyTitle,
          message: l10n.todayPlaceholder,
          action: FbButton.primary(
            label: l10n.todayAddFood,
            icon: FbIcons.add,
            onPressed: () =>
                ref.read(appNavigatorProvider).push(const FoodSearchRoute()),
          ),
        ),
      ),
    );
  }
}
