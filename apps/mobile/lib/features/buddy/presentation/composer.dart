import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/presentation/utf16_length_formatter.dart';
import 'package:material_ui/material_ui.dart';

/// Buddy's composer (A22 D7, D14): food search first (the manual path stays
/// two taps and works offline), then the text field capped at 1,000 UTF-16
/// units, then Send.
class BuddyComposer extends StatelessWidget {
  /// The composer over [controller] and [focusNode].
  const new({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onSearch,
    this.onPhoto,
    this.photoAttached = false,
    this.onRemovePhoto,
    super.key,
  });

  /// Attaches a meal photo (AI-011); null hides the button.
  final VoidCallback? onPhoto;

  /// A photo is attached to the next message.
  final bool photoAttached;

  /// Removes the attached photo.
  final VoidCallback? onRemovePhoto;

  /// The text.
  final TextEditingController controller;

  /// The field's focus, kept after Send (UX-023).
  final FocusNode focusNode;

  /// Sends the text; null while a send is in flight.
  final VoidCallback? onSend;

  /// Closes the sheet and opens food search.
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FbComposer(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      hint: l10n.buddyComposerHint,
      sendTooltip: l10n.buddySend,
      onSend: onSend,
      inputFormatters: [Utf16LengthLimitingFormatter(ChatText.composerLimit)],
      sendWithoutText: photoAttached,
      attachment: photoAttached
          ? FbTargetChip(
              key: const ValueKey('buddy-photo-attached'),
              label: l10n.buddyPhotoAttached,
              clearTooltip: l10n.buddyPhotoRemove,
              onClear: onRemovePhoto ?? () {},
            )
          : null,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FbIconButton(
            icon: FbIcons.search,
            tooltip: l10n.buddySearchFoods,
            onPressed: onSearch,
          ),
          if (onPhoto != null)
            FbIconButton(
              key: const ValueKey('buddy-photo'),
              icon: FbIcons.camera,
              tooltip: l10n.buddyAddPhoto,
              onPressed: onPhoto,
            ),
        ],
      ),
    );
  }
}
