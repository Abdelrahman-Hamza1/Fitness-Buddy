import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/errors/pii_scrubber.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'error_reporting.g.dart';

/// Starts Sentry; `SentryFlutter.init` in the app, a fake in tests.
typedef SentryStarter = Future<void> Function(
  FlutterOptionsConfiguration configure,
);

/// Crash and error reporting with Sentry (S06 plan D12, A5).
///
/// Started after the first frame (UX-001), and only when the flavor has a
/// DSN: an empty DSN means no reporting at all. Errors before the start are
/// not reported (accepted, research "S06 — Flutter package set").
final class ErrorReporting {
  /// Creates the reporter for [config]; [start] runs the SDK.
  new({
    required this.config,
    required this._packageInfo,
    this._start = SentryFlutter.init,
  });

  /// The release name's package part: the Dart package, the same in every
  /// flavor (the Android application id differs per flavor).
  static const releasePackage = 'fb_mobile';

  /// The flavor configuration with the DSN.
  final AppConfig config;

  final Future<PackageInfo> Function() _packageInfo;
  final SentryStarter _start;

  /// Starts reporting, unless the DSN is empty. Returns whether it started.
  Future<bool> start() async {
    if (config.sentryDsn.isEmpty) return false;
    final info = await _packageInfo();
    await _start(
      (options) => configure(
        options,
        dsn: config.sentryDsn,
        environment: config.flavor.name,
        release: '$releasePackage@${info.version}+${info.buildNumber}',
      ),
    );
    return true;
  }

  /// Sets the privacy-first [options] (S06 plan D12, A5).
  static void configure(
    SentryFlutterOptions options, {
    required String dsn,
    required String environment,
    required String release,
  }) {
    options
      ..dsn = dsn
      ..environment = environment
      ..release = release
      // Privacy: no PII, no screenshots or widget trees (they show user
      // content), no request bodies, no breadcrumbs that carry text.
      ..sendDefaultPii = false
      ..attachScreenshot = false
      ..attachViewHierarchy = false
      ..maxRequestBodySize = MaxRequestBodySize.never
      ..enableUserInteractionBreadcrumbs = false
      ..enablePrintBreadcrumbs = false
      ..enableAutoNativeBreadcrumbs = false
      ..beforeSend = PiiScrubber.scrubEvent
      ..beforeBreadcrumb = PiiScrubber.scrubBreadcrumb
      // Sentry logs and metrics are always on in this SDK version: drop
      // every one, so nothing the app or a package logs is sent.
      ..beforeSendLog = dropLog
      ..beforeSendMetric = dropMetric
      // Performance tracing is tuned in A11.
      ..tracesSampleRate = 0;
    // Session replay records the screen, i.e. user content: never.
    options.replay
      ..sessionSampleRate = 0
      ..onErrorSampleRate = 0;
  }

  /// `beforeSendLog`: drops every Sentry log.
  static SentryLog? dropLog(SentryLog log, Hint hint) => null;

  /// `beforeSendMetric`: drops every Sentry metric.
  static SentryMetric? dropMetric(SentryMetric metric, Hint hint) => null;
}

/// The app's [ErrorReporting]; `AppBootstrap` starts it after the first
/// frame.
@Riverpod(keepAlive: true)
ErrorReporting errorReporting(Ref ref) => ErrorReporting(
  config: ref.watch(appConfigProvider),
  packageInfo: () => ref.read(packageInfoProvider.future),
);
