import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/errors/pii_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Plain `test` only: SentryFlutter.init under `testWidgets` hangs (fake
// async; research "S06 — Flutter package set").

AppConfig _config(String dsn) => AppConfig(
  flavor: AppFlavor.staging,
  apiBaseUrl: Uri.parse('https://api.example.test'),
  sentryDsn: dsn,
);

Future<PackageInfo> _info() async => PackageInfo(
  appName: 'Fitness Buddy',
  packageName: 'io.example.fitnessbuddy.staging',
  version: '0.1.0',
  buildNumber: '42',
);

void main() {
  test('Sentry is not initialised when the DSN is empty', () async {
    var started = false;
    var packageInfoRead = false;
    final reporting = ErrorReporting(
      config: _config(''),
      packageInfo: () {
        packageInfoRead = true;
        return _info();
      },
      start: (_) async => started = true,
    );

    expect(await reporting.start(), isFalse);
    expect(started, isFalse);
    expect(packageInfoRead, isFalse);
    expect(Sentry.isEnabled, isFalse);
  });

  test('with a DSN, Sentry starts with the privacy-first options', () async {
    final options = SentryFlutterOptions();
    final reporting = ErrorReporting(
      config: _config('https://key@sentry.example.test/1'),
      packageInfo: _info,
      start: (configure) async {
        await configure(options);
      },
    );

    expect(await reporting.start(), isTrue);

    expect(options.dsn, 'https://key@sentry.example.test/1');
    expect(options.environment, 'staging');
    // The Dart package name, the same in every flavor.
    expect(options.release, 'fb_mobile@0.1.0+42');
    expect(options.sendDefaultPii, isFalse);
    expect(options.attachScreenshot, isFalse);
    expect(options.attachViewHierarchy, isFalse);
    expect(options.maxRequestBodySize, MaxRequestBodySize.never);
    expect(options.enableUserInteractionBreadcrumbs, isFalse);
    expect(options.enablePrintBreadcrumbs, isFalse);
    expect(options.enableAutoNativeBreadcrumbs, isFalse);
    expect(options.tracesSampleRate, 0);
    expect(options.beforeSend, PiiScrubber.scrubEvent);
    expect(options.beforeBreadcrumb, PiiScrubber.scrubBreadcrumb);
    // No session replay, no Sentry logs or metrics.
    expect(options.replay.sessionSampleRate, 0);
    expect(options.replay.onErrorSampleRate, 0);
    expect(options.beforeSendLog, ErrorReporting.dropLog);
    expect(options.beforeSendMetric, ErrorReporting.dropMetric);
  });
}
