import 'package:material_ui/material_ui.dart';

/// A list row: title, optional subtitle, leading and trailing widgets
/// (HM-007). Tappable when [onTap] is set.
class FbListRow extends StatelessWidget {
  /// Creates a row.
  const new({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// The main text.
  final String title;

  /// A second, muted line.
  final String? subtitle;

  /// At the start of the row.
  final Widget? leading;

  /// At the end of the row.
  final Widget? trailing;

  /// Makes the row tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    leading: leading,
    trailing: trailing,
    onTap: onTap,
  );
}
