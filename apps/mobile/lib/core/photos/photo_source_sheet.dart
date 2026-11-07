import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/photos/photo_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Asks camera or gallery, picks with the app's [PhotoPicker] and says
/// plainly when a picture can't be used (A69 D6). `null` when nothing was
/// picked; the photo is never stored or logged.
Future<String?> pickPhoto(
  BuildContext context,
  WidgetRef ref, {
  required String title,
}) async {
  final l10n = context.l10n;
  final source = await showFbActionSheet<PhotoSource>(
    context,
    title: title,
    actions: [
      FbAction(
        value: PhotoSource.camera,
        label: l10n.photoTake,
        icon: FbIcons.camera,
        key: const ValueKey('photo-camera'),
      ),
      FbAction(
        value: PhotoSource.gallery,
        label: l10n.photoChoose,
        icon: FbIcons.gallery,
        key: const ValueKey('photo-gallery'),
      ),
    ],
  );
  if (source == null) return null;
  final picked = await ref.read(photoPickerProvider).pick(source);
  if (!context.mounted) return null;
  switch (picked) {
    case PhotoReady(:final base64):
      return base64;
    case PhotoCancelled():
      return null;
    case PhotoUnusable():
      showFbSnackBar(context, l10n.photoUnusable);
      return null;
    case PhotoUnavailable():
      showFbSnackBar(context, l10n.photoUnavailable);
      return null;
  }
}
