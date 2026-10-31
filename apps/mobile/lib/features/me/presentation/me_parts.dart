import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A group of Me rows (A51): an optional section header, then the rows in
/// one card; nothing when there are no rows.
class MeGroup extends StatelessWidget {
  /// Creates the group.
  const new({required this.children, this.title, super.key});

  /// The header, or null.
  final String? title;

  /// The rows.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final title?) FbSectionHeader(title: title),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// A Me row that opens [route]: an icon, the title, the current value or
/// what is inside as its subtitle, and a chevron. [go] switches to the
/// route's own tab instead of pushing it in Me.
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
    trailing: const Icon(FbIcons.next),
    onTap: () {
      final navigator = ref.read(appNavigatorProvider);
      go ? navigator.go(route) : navigator.push(route);
    },
  );
}

/// A Me subpage: an app bar with [title] and the [children] in one
/// scrolling column.
class MePage extends StatelessWidget {
  /// Creates the page.
  const new({required this.title, required this.children, super.key});

  /// The page's title.
  final String title;

  /// Its groups.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        FbSpace.s2,
        FbSpace.s4,
        FbSpace.s5,
      ),
      children: children,
    ),
  );
}
