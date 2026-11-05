import 'package:fb_design_system/src/components/digits.dart';
import 'package:fb_design_system/src/components/supporting_line.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A one-time code entry shown as [length] boxes (A51 sign-in): one real,
/// invisible text field under the boxes takes the typing, the keyboard's
/// code suggestion and a paste, so pasting "481 920" fills all six boxes.
/// Only digits are kept; Arabic-Indic and Persian digits become ASCII ones
/// (A57 A60). [onCompleted] runs once the last digit is in.
///
/// The box being typed is outlined in the brand colour while focused; with
/// an [errorText] every box gets the error outline and the message shows in
/// the reserved line below ([supportingLines] tall whatever it shows, so
/// nothing moves; UX-045). For a screen reader it is one text field named
/// [label] with the digits as its value. Boxes are at least 48 dp tall and
/// lay out start-to-end in the text direction of the digits (always left to
/// right, as codes are read).
class FbCodeBoxes extends StatefulWidget {
  /// Creates the entry over [controller].
  const new({
    required this.controller,
    required this.label,
    this.length = 6,
    this.onCompleted,
    this.errorText,
    this.supportingText,
    this.supportingLines = 1,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  /// The digits typed so far.
  final TextEditingController controller;

  /// What a screen reader calls the field ("6-digit code").
  final String label;

  /// The number of digits.
  final int length;

  /// Called with the code when all [length] digits are in.
  final ValueChanged<String>? onCompleted;

  /// A message under the boxes, or null.
  final String? errorText;

  /// A hint in the reserved line while there is no error.
  final String? supportingText;

  /// How many lines the reserved line takes (0 = none).
  final int supportingLines;

  /// Focus the field when it appears.
  final bool autofocus;

  /// Whether typing is allowed.
  final bool enabled;

  @override
  State<FbCodeBoxes> createState() => _FbCodeBoxesState();
}

class _FbCodeBoxesState extends State<FbCodeBoxes> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _changed(String text) {
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        const _AsciiDigitsFormatter(),
        LengthLimitingTextInputFormatter(widget.length),
      ],
      onChanged: _changed,
      showCursor: false,
      // Transparent text over the boxes: the boxes show the digits.
      style: FbType.numeric(FbType.headline)
          .copyWith(color: const Color(0x00000000)),
      cursorColor: const Color(0x00000000),
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        counterText: '',
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: const TextStyle(color: Color(0x00000000), fontSize: 1),
        contentPadding: EdgeInsetsDirectional.zero,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _focus.requestFocus : null,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                ExcludeSemantics(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([widget.controller, _focus]),
                    builder: (context, _) => _Boxes(
                      digits: widget.controller.text,
                      length: widget.length,
                      focused: _focus.hasFocus,
                      error: error != null,
                    ),
                  ),
                ),
                Positioned.fill(child: Center(child: field)),
              ],
            ),
          ),
        ),
        FbSupportingLine(
          text: widget.supportingText,
          errorText: error,
          lines: widget.supportingLines,
          horizontalPadding: 0,
        ),
      ],
    );
  }
}

/// Keeps only digits, turning Arabic-Indic and Persian ones into ASCII.
class _AsciiDigitsFormatter extends TextInputFormatter {
  const new();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String keep(String text) => String.fromCharCodes(
      normalizeDigits(text).codeUnits.where((u) => u >= 0x30 && u <= 0x39),
    );
    final text = keep(newValue.text);
    if (text == newValue.text) return newValue;
    final before = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: keep(newValue.text.substring(0, before)).length,
      ),
    );
  }
}

class _Boxes extends StatelessWidget {
  const new({
    required this.digits,
    required this.length,
    required this.focused,
    required this.error,
  });

  final String digits;
  final int length;
  final bool focused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      spacing: FbSpace.s2,
      children: [
        for (var i = 0; i < length; i++)
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: FbRadius.mdAll,
                  border: Border.all(
                    color: error
                        ? scheme.error
                        : focused && i == digits.length.clamp(0, length - 1)
                        ? scheme.primary
                        : scheme.outline,
                    width:
                        error ||
                            (focused && i == digits.length.clamp(0, length - 1))
                        ? 2
                        : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: FbSpace.s2,
                  ),
                  child: Text(
                    i < digits.length ? digits[i] : '',
                    textAlign: TextAlign.center,
                    style: FbType.numeric(FbType.headline)
                        .copyWith(color: scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
