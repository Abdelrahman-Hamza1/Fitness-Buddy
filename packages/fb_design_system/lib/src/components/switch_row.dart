import 'package:material_ui/material_ui.dart';

/// A row with a [title], an optional [subtitle] and a switch at the end
/// (a setting that is on or off, like "Halal food").
///
/// The whole row is the touch target and one toggle for a screen reader,
/// which hears the title, the subtitle and whether it is on. The switch sits
/// at the end of the row and mirrors in right-to-left layouts. A null
/// [onChanged] disables the row.
class FbSwitchRow extends StatelessWidget {
  /// Creates a row.
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  /// The main text.
  final String title;

  /// A second, muted line.
  final String? subtitle;

  /// Whether the setting is on.
  final bool value;

  /// Called with the new value on a tap. Null disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}
