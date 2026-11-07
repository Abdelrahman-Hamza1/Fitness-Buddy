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
    this.onVoice,
    this.fromVoice = false,
    this.autofocus = true,
    super.key,
  });

  /// Focus the field (the keyboard) when it first shows; off when Buddy
  /// opens straight into listening (A70 D8).
  final bool autofocus;

  /// Opens the listening panel (AI-014, A70); null hides the button.
  final VoidCallback? onVoice;

  /// The text came from the voice: the hint says to check it before
  /// sending (it is never sent by itself).
  final bool fromVoice;

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
      autofocus: autofocus,
      hint: l10n.buddyComposerHint,
      sendTooltip: l10n.buddySend,
      onSend: onSend,
      inputFormatters: [Utf16LengthLimitingFormatter(ChatText.composerLimit)],
      sendWithoutText: photoAttached,
      attachment: _attachment(context),
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
          if (onVoice != null)
            FbIconButton(
              key: const ValueKey('buddy-voice'),
              icon: FbIcons.mic,
              tooltip: l10n.buddyVoice,
              onPressed: onVoice,
            ),
        ],
      ),
    );
  }

  Widget? _attachment(BuildContext context) {
    final l10n = context.l10n;
    final photo = photoAttached
        ? FbTargetChip(
            key: const ValueKey('buddy-photo-attached'),
            label: l10n.buddyPhotoAttached,
            clearTooltip: l10n.buddyPhotoRemove,
            onClear: onRemovePhoto ?? () {},
          )
        : null;
    final hint = fromVoice
        ? Text(
            l10n.buddyVoiceHint,
            key: const ValueKey('buddy-voice-hint'),
            style: FbType.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        : null;
    if (photo == null || hint == null) return photo ?? hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s1,
      children: [photo, hint],
    );
  }
}
