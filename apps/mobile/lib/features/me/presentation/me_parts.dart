import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/ui/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A group of Me rows (A51): the shared settings group (A65 M4).
typedef MeGroup = FbRowGroup;

/// A Me row that opens [route]: an icon, the title, the current value or
/// what is inside as its subtitle, and a chevron. [go] switches to the
/// route's own tab instead of pushing it in Me; its row ends in an
/// "other tab" arrow instead of the chevron (A65 m6).
class MeLink extends ConsumerWidget {
  /// Creates the row.
  const new({
    required this.title,
    required this.route,
    this.subtitle,
    this.icon,
    this.go = false,
    super.key,
  });

  /// The row's name.
  final String title;

  /// Its current value or contents.
  final String? subtitle;

  /// A decorative icon (from `FbIcons`).
  final IconData? icon;

  /// Where it goes.
  final AppRoute route;

  /// Go to the route's tab (a Workouts screen) instead of pushing it here.
  final bool go;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FbListRow(
    title: title,
    subtitle: subtitle,
    leading: icon == null
        ? null
        : Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    trailing: Icon(go ? FbIcons.otherTab : FbIcons.next),
    onTap: () {
      final navigator = ref.read(appNavigatorProvider);
      go ? navigator.go(route) : navigator.push(route);
    },
  );
}

/// A Me subpage: the shared settings page layout (A65 M4).
typedef MePage = SettingsPage;
