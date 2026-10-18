import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Starts the app. Run with `--dart-define-from-file=config/<flavor>.json`.
///
/// Nothing before the first frame touches the network or storage (UX-001):
/// the config is compiled in.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lazy: the font licences are read only when the licence page opens.
  registerFbFontLicenses();
  final container = ProviderContainer(
    overrides: appOverrides(AppConfig.fromEnvironment()),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
}
