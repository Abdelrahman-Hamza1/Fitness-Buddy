import 'package:fb_design_system/src/theme/licenses.dart';
import 'package:material_ui/material_ui.dart';

/// Opens Flutter's open-source licence page for the app, with the licences of
/// the bundled fonts added (see `registerFbFontLicenses`). The page is shown
/// on the root navigator, above the app shell, and its words come from the
/// app's Material localizations.
Future<void> showFbLicensePage(
  BuildContext context, {
  required String applicationName,
  required String applicationVersion,
}) {
  registerFbFontLicenses();
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LicensePage(
        applicationName: applicationName,
        applicationVersion: applicationVersion,
      ),
    ),
  );
}
