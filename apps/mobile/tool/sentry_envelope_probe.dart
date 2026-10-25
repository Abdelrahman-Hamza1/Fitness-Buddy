import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/main.dart' as app;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Local emulator only: runs the real app/SDK, then exercises About's API.
Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  if (config.flavor != AppFlavor.dev ||
      config.sentryDsn != 'http://k@127.0.0.1:8765/1') {
    throw StateError('Probe requires the documented local dev sink');
  }
  app.main();
  for (var attempt = 0; attempt < 120 && !Sentry.isEnabled; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  if (!Sentry.isEnabled) throw StateError('Probe SDK did not start');
  await ErrorReporting(
    config: config,
    packageInfo: PackageInfo.fromPlatform,
  ).sendTestReport();
  // FlutterErrorIntegration captures asynchronously after reportError returns.
  await Future<void>.delayed(const Duration(seconds: 3));
}
