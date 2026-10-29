/// Test support for packages that render the design system's text in
/// widget or golden tests. Not part of the app's public surface.
library;

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';

/// The font families the design system's text styles name, with their asset
/// files in `assets/fonts/`.
const Map<String, String> _fonts = {
  'Inter': 'InterVariable.ttf',
  'Nunito': 'NunitoVariable.ttf',
  'NotoSansArabic': 'NotoSansArabicVariable.ttf',
};

/// Loads Inter, Nunito and Noto Sans Arabic under the family names that
/// `TextStyle(fontFamily: 'Inter', package: 'fb_design_system')` resolves to
/// (`packages/fb_design_system/Inter`), so tests measure text with the real
/// font metrics instead of the test font (A02 D19).
///
/// alchemist's own font loading registers the unprefixed names only. Call this
/// from `flutter_test_config.dart`, before the tests run.
Future<void> loadFbTestFonts() async {
  for (final MapEntry(key: family, value: file) in _fonts.entries) {
    final loader = FontLoader('packages/fb_design_system/$family')
      ..addFont(_load(file));
    await loader.load();
  }
}

/// The asset is under `packages/fb_design_system/…` when another package
/// runs the tests, and under its plain path in this package's own tests.
Future<ByteData> _load(String file) async {
  try {
    return await rootBundle.load(
      'packages/fb_design_system/assets/fonts/$file',
    );
    // The bundle throws a FlutterError for a missing key.
    // ignore: avoid_catching_errors
  } on FlutterError {
    return await rootBundle.load('assets/fonts/$file');
  }
}
