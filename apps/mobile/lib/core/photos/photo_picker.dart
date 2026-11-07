import 'dart:convert';
import 'dart:io';

import 'package:fb_mobile/core/photos/jpeg_check.dart';
import 'package:fb_mobile/core/photos/photo_cache.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_picker.g.dart';

/// Where a photo comes from.
enum PhotoSource {
  /// Take one now.
  camera,

  /// Pick one from the gallery.
  gallery,
}

/// What picking a photo gave (A69 D6). Holds the photo: never logged.
sealed class PhotoPick {
  const new _();
}

/// A JPEG the contract accepts, as base64 (no `data:` prefix).
final class PhotoReady extends PhotoPick {
  /// The photo.
  const new(this.base64) : super._();

  /// Base64 JPEG, ≤ 1024 px, ≤ 400 000 characters.
  final String base64;

  @override
  String toString() => 'PhotoReady';
}

/// The user closed the picker.
final class PhotoCancelled extends PhotoPick {
  /// Cancelled.
  const new() : super._();
}

/// The picture can't be used (not a JPEG after resizing, or too big).
final class PhotoUnusable extends PhotoPick {
  /// Unusable.
  const new() : super._();
}

/// The camera or gallery couldn't open (permission, no camera).
final class PhotoUnavailable extends PhotoPick {
  /// Unavailable.
  const new() : super._();
}

/// Picks a meal or label photo, resized on the device to 1024 px and JPEG
/// quality 80, stripped of its metadata (EXIF: GPS, camera owner, serial)
/// and checked against the contract ([JpegCheck]). The photo stays in
/// memory: each file the picker hands over is listed as owned
/// ([OwnedPhotoFiles]), deleted right after reading (success, refusal or
/// failure), and a leftover is deleted on the next [sweep]; it is never
/// written to the database, logged or reported.
///
/// Known residue (security audit 2026-11-07, Android, image_picker_android
/// 0.8.13+25): for a gallery pick the plugin first copies the original,
/// EXIF included, to `<cache>/<random UUID>/<name>` (`FileUtils
/// .getPathFromUri`), then hands back only the resized copy
/// (`<cache>/<name>`); it never deletes that original (only a camera
/// original is deleted after scaling; `deleteOnExit` is unreliable on
/// Android). The UUID path never reaches Dart, so there is no owned path
/// to delete: finding it would take a pattern search of the cache, which
/// [OwnedPhotoFiles] rules out. Picking without resizing (to own the
/// original) would need a Dart JPEG encoder, a new dependency. The copy
/// stays in the app's private cache until Android clears it. Backlogged.
class PhotoPicker {
  /// Over the platform's image picker.
  const new();

  /// A photo from [source].
  Future<PhotoPick> pick(PhotoSource source) async {
    final owned = await _owned();
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: JpegCheck.maxSide.toDouble(),
        maxHeight: JpegCheck.maxSide.toDouble(),
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null) return const PhotoCancelled();
      await owned?.own(file.path);
      final bytes = await file.readAsBytes();
      final clean = JpegCheck.stripMetadata(bytes);
      if (clean == null || JpegCheck.accept(clean) == null) {
        return const PhotoUnusable();
      }
      return PhotoReady(base64Encode(clean));
      // Permission refused, no camera, an unreadable file: the platform's
      // exception text may name files; only the outcome leaves here.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return const PhotoUnavailable();
    } finally {
      if (file != null) await owned?.release(file.path);
    }
  }

  /// Deletes the picture files this app was handed and didn't delete yet
  /// (a kill mid-read): called on the first Buddy bar open, off the
  /// startup path.
  Future<void> sweep() async {
    await (await _owned())?.sweep();
  }

  /// [sweep] once per process (the first Buddy bar open).
  Future<void> sweepOnce() => _swept;

  static Future<OwnedPhotoFiles?> _owned() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return OwnedPhotoFiles(File('${dir.path}/photo_picker_files.json'));
      // No support directory (tests, a platform without one).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'PhotoPicker';
}

/// The one sweep of this process (lazy: it runs on first use).
final Future<void> _swept = const PhotoPicker().sweep();

/// The app's photo picker; tests override it.
@Riverpod(keepAlive: true)
PhotoPicker photoPicker(Ref ref) => const PhotoPicker();
