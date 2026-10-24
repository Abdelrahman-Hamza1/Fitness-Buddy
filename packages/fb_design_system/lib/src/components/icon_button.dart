import 'package:material_ui/material_ui.dart';

/// A tappable icon with a required [tooltip] (which is also its screen-reader
/// label), so no icon button is ever unlabelled (UX-040). Use it for app bar
/// actions such as rename or "more". Pass the icon from `FbIcons`.
class FbIconButton extends StatelessWidget {
  /// Creates the button; a null [onPressed] disables it.
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  /// The icon, from `FbIcons`.
  final IconData icon;

  /// The (already translated) tooltip and screen-reader label.
  final String tooltip;

  /// Called on tap; null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed);
}
