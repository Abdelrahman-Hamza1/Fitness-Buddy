import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// The one layout of a settings page (A51, A65 M4): an app bar with
/// [title] and the [children] (usually `FbRowGroup`s) in one scrolling
/// column with the Me tab's insets. Me's subpages, Notifications, Ramadan,
/// About and Profile & goal all use it, so they read as one design.
class SettingsPage extends StatelessWidget {
  /// Creates the page.
  const new({required this.title, required this.children, super.key});

  /// The insets of a settings page's list (the Me tab uses the same).
  static const EdgeInsetsDirectional padding = EdgeInsetsDirectional.fromSTEB(
    FbSpace.s4,
    FbSpace.s2,
    FbSpace.s4,
    FbSpace.s6,
  );

  /// The page's title.
  final String title;

  /// Its groups.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: padding, children: children),
  );
}

/// The gap between two groups of a settings page.
const Widget settingsGroupGap = SizedBox(height: FbSpace.s3);
