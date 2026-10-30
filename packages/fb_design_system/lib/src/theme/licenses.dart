import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

bool _registered = false;

/// The bundled fonts and their SIL OFL 1.1 texts in `assets/fonts/`.
const List<(String, String)> fbFontLicenses = [
  ('Inter', 'OFL-Inter.txt'),
  ('Nunito', 'OFL-Nunito.txt'),
  ('Noto Sans Arabic', 'OFL-NotoSansArabic.txt'),
];

/// Vendored artwork and its licence texts in `assets/licenses/` (sources:
/// `assets/licenses/SOURCES.md`): the muscle map's body outline (A37 D16).
const List<(String, String)> fbArtworkLicenses = [
  ('react-native-body-highlighter', 'MIT-react-native-body-highlighter.txt'),
];

/// Adds the licence texts of the bundled fonts ([fbFontLicenses]) and the
/// vendored artwork ([fbArtworkLicenses]) to Flutter's licence page. Lazy:
/// the files are read only when the licence page opens, so this costs
/// nothing on the startup path. Safe to call twice.
void registerFbLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in fbFontLicenses) {
      final text = await rootBundle.loadString(
        'packages/fb_design_system/assets/fonts/$file',
      );
      yield LicenseEntryWithLineBreaks([name], text);
    }
    for (final (name, file) in fbArtworkLicenses) {
      final text = await rootBundle.loadString(
        'packages/fb_design_system/assets/licenses/$file',
      );
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
