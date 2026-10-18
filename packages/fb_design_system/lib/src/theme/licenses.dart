import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

bool _registered = false;

/// Adds the SIL OFL 1.1 texts of the bundled fonts (Inter, Noto Sans Arabic)
/// to Flutter's licence page. Lazy: the files are read only when the licence
/// page opens, so this costs nothing on the startup path. Safe to call twice.
void registerFbFontLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in const [
      ('Inter', 'OFL-Inter.txt'),
      ('Noto Sans Arabic', 'OFL-NotoSansArabic.txt'),
    ]) {
      final text = await rootBundle.loadString(
        'packages/fb_design_system/assets/fonts/$file',
      );
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
