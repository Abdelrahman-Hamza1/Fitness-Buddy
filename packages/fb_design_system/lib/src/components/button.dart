import 'package:material_ui/material_ui.dart';

enum _FbButtonKind { primary, secondary, text }

/// A button (UX-021). [FbButton.primary] is filled and dominant: one per
/// screen or sheet. [FbButton.secondary] is outlined, [FbButton.text] is plain.
///
/// A null [onPressed] disables it.
class FbButton extends StatelessWidget {
  /// The filled, dominant button.
  const new primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  }) : _kind = _FbButtonKind.primary;

  /// The outlined button.
  const new secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  }) : _kind = _FbButtonKind.secondary;

  /// The plain text button.
  const new text({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  }) : _kind = _FbButtonKind.text;

  /// The (already translated) label.
  final String label;

  /// Called on tap. Null disables the button.
  final VoidCallback? onPressed;

  /// An optional leading icon (from `FbIcons`).
  final IconData? icon;

  /// Fill the available width.
  final bool expand;

  final _FbButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    final leading = icon == null ? null : Icon(icon, size: 20);
    final Widget button = switch (_kind) {
      _FbButtonKind.primary =>
        leading == null
            ? FilledButton(onPressed: onPressed, child: text)
            : FilledButton.icon(
                onPressed: onPressed,
                icon: leading,
                label: text,
              ),
      _FbButtonKind.secondary =>
        leading == null
            ? OutlinedButton(onPressed: onPressed, child: text)
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: leading,
                label: text,
              ),
      _FbButtonKind.text =>
        leading == null
            ? TextButton(onPressed: onPressed, child: text)
            : TextButton.icon(onPressed: onPressed, icon: leading, label: text),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
