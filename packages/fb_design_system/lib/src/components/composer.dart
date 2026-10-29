import 'package:fb_design_system/src/components/icon_button.dart';
import 'package:fb_design_system/src/components/input_bar.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The chat composer (A22 D14): an optional [leading] action, a 1–4 line
/// text field and a Send button. The keyboard's action key sends too and
/// the field keeps focus after sending (UX-023).
///
/// Send is disabled while the text is blank or [onSend] is null (a send in
/// flight). [inputFormatters] cap the text (the app's UTF-16 limit).
class FbComposer extends StatelessWidget {
  /// Creates the composer.
  const new({
    required this.controller,
    required this.hint,
    required this.sendTooltip,
    required this.onSend,
    this.focusNode,
    this.autofocus = false,
    this.inputFormatters = const [],
    this.leading,
    super.key,
  });

  /// The text.
  final TextEditingController controller;

  /// The hint while it's empty.
  final String hint;

  /// Tooltip and screen-reader label of Send.
  final String sendTooltip;

  /// Called with Send; null disables it.
  final VoidCallback? onSend;

  /// The field's focus.
  final FocusNode? focusNode;

  /// Focus the field when it first shows.
  final bool autofocus;

  /// Formatters applied to typed and pasted text.
  final List<TextInputFormatter> inputFormatters;

  /// An action before the field (an `FbIconButton`).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final send = value.text.trim().isEmpty ? null : onSend;
        return Material(
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FbRadius.lg),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          // As tall as the Today input bar it replaces in the sheet.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: FbInputBar.minHeight),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ?leading,
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: leading == null ? FbSpace.s4 : 0,
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: autofocus,
                      minLines: 1,
                      maxLines: 4,
                      inputFormatters: inputFormatters,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      style: FbType.body.copyWith(color: scheme.onSurface),
                      // Providing onEditingComplete keeps the focus after the
                      // keyboard's send key (UX-023).
                      onEditingComplete: () => send?.call(),
                      decoration:
                          InputDecoration.collapsed(
                            hintText: hint,
                            hintStyle: FbType.body.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ).copyWith(
                            contentPadding:
                                const EdgeInsetsDirectional.symmetric(
                                  vertical: FbSpace.s3,
                                ),
                          ),
                    ),
                  ),
                ),
                FbIconButton(
                  icon: FbIcons.send,
                  tooltip: sendTooltip,
                  onPressed: send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
