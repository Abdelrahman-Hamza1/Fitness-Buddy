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

/// Adds the SIL OFL 1.1 texts of the bundled fonts ([fbFontLicenses]) to
/// Flutter's licence page. Lazy: the files are read only when the licence
/// page opens, so this costs nothing on the startup path. Safe to call twice.
void registerFbFontLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in fbFontLicenses) {
      final text = await rootBundle.loadString(
        'packages/fb_design_system/assets/fonts/$file',
      );
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
