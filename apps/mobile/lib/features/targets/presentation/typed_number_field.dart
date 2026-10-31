import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

/// A number field of the targets forms over [FbNumberField] (A13b WP5). It
/// keeps the text as typed (the draft owns it: [text] in, [onChanged] out)
/// and shows [errorText] only once it helps: after the user typed here and
/// left the field, or when [showError] asks (a refused Next or Save). So a
/// half-typed "19" isn't called out of range while the year is typed.
class TypedNumberField extends StatefulWidget {
  /// Creates the field.
  const new({
    required this.text,
    required this.onChanged,
    required this.label,
    this.unit,
    this.errorText,
    this.showError = false,
    this.maxDecimals = 1,
    this.semanticLabel,
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
    super.key,
  });

  /// The text the draft holds.
  final String text;

  /// Called with every edit.
  final ValueChanged<String> onChanged;

  /// The (already translated) label.
  final String label;

  /// The (already translated) unit after the number.
  final String? unit;

  /// Why the text can't be used, or null.
  final String? errorText;

  /// Show [errorText] even before the user left the field.
  final bool showError;

  /// The most decimals the field accepts.
  final int maxDecimals;

  /// What a screen reader reads instead of [label].
  final String? semanticLabel;

  /// The keyboard's action button.
  final TextInputAction textInputAction;

  /// Whether the field takes focus when it appears.
  final bool autofocus;

  @override
  State<TypedNumberField> createState() => _TypedNumberFieldState();
}

class _TypedNumberFieldState extends State<TypedNumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );
  final FocusNode _focus = FocusNode();
  bool _edited = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (!_focus.hasFocus && _edited && !_left) setState(() => _left = true);
  }

  @override
  void didUpdateWidget(TypedNumberField old) {
    super.didUpdateWidget(old);
    // The draft changed from outside (a unit switch, a prefill): show it.
    if (widget.text != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_focusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FbNumberField(
    controller: _controller,
    focusNode: _focus,
    label: widget.label,
    unit: widget.unit,
    maxDecimals: widget.maxDecimals,
    semanticLabel: widget.semanticLabel,
    textInputAction: widget.textInputAction,
    autofocus: widget.autofocus,
    errorText: widget.showError || _left ? widget.errorText : null,
    onChanged: (text) {
      _edited = true;
      widget.onChanged(text);
    },
  );
}
