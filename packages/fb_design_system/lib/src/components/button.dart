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
    this.busy = false,
    super.key,
  }) : _kind = _FbButtonKind.primary;

  /// The outlined button.
  const new secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
    super.key,
  }) : _kind = _FbButtonKind.secondary;

  /// The plain text button.
  const new text({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
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

  /// Work started by this button is under way (A57 A79): a small progress
  /// glyph takes the icon's place, and the button is announced. Pair it
  /// with a null [onPressed] and a label that says what is happening; the
  /// button keeps its bounds.
  final bool busy;

  final _FbButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    final leading = busy
        ? const _BusyGlyph()
        : icon == null
        ? null
        : Icon(icon, size: 20);
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
    final sized = expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
    return busy ? Semantics(liveRegion: true, child: sized) : sized;
  }
}

/// A 20 dp progress ring; still (full) when the system asks for no
/// animations.
class _BusyGlyph extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 20,
    child: Padding(
      padding: const EdgeInsetsDirectional.all(2),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: MediaQuery.disableAnimationsOf(context) ? 1 : null,
        color: DefaultTextStyle.of(context).style.color,
      ),
    ),
  );
}
