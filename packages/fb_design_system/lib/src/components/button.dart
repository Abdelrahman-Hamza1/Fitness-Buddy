import 'package:material_ui/material_ui.dart';

enum _FbButtonKind { primary, secondary, text, destructive }

/// A button (UX-021). [FbButton.primary] is filled and dominant: one per
/// screen or sheet. [FbButton.secondary] is outlined, [FbButton.text] is plain.
/// [FbButton.destructive] is the filled button of an action that can't be
/// undone (delete, remove): the muted error-container tone, never brand ink.
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

  /// The filled button of an irreversible action (A65 m12): it reads as
  /// "careful", not as the screen's main path.
  const new destructive({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
    super.key,
  }) : _kind = _FbButtonKind.destructive;

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
    final button = switch (_kind) {
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
      _FbButtonKind.destructive => _destructive(context, text, leading),
    };
    final sized = expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
    return busy ? Semantics(liveRegion: true, child: sized) : sized;
  }

  Widget _destructive(BuildContext context, Widget text, Widget? leading) {
    final scheme = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      // The palette checks error on errorContainer for contrast (AA).
      backgroundColor: scheme.errorContainer,
      foregroundColor: scheme.error,
    );
    return leading == null
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: leading,
            label: text,
          );
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
