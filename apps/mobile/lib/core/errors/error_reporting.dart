import 'dart:async';

import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/errors/pii_scrubber.dart';
import 'package:flutter/foundation.dart';
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

  /// Reports only the runtime type of [error] (no message, path or stack
  /// content), when reporting has started. For failures that are absorbed.
  void reportKind(Object error) {
    if (config.sentryDsn.isEmpty) return;
    unawaited(
      Sentry.captureEvent(
        SentryEvent(
          exceptions: [
            SentryException(
              type: error.runtimeType.toString(),
              value: null,
              mechanism: Mechanism(type: 'absorbed', handled: true),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends synthetic handled and framework-unhandled errors (A11 D17).
  /// The second path runs on a later event-loop turn, through the installed
  /// FlutterError handler, exercising the SDK's details processing.
  Future<void> sendTestReport() async {
    if (config.sentryDsn.isEmpty) return;
    await Sentry.captureException(
      ThrowableMechanism(
        Mechanism(type: 'handled', handled: true),
        TestErrorReport(),
      ),
    );
    await Future<void>(() {
      try {
        throw TestErrorReport();
      } on TestErrorReport catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            context: ErrorDescription(testReportCanary),
            informationCollector: () => [ErrorDescription(testReportCanary)],
          ),
        );
      }
    });
  }

  /// Synthetic food text: must be absent from every captured envelope.
  static const testReportCanary = 'FB_A11_CANARY_shawarma_250g';

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
      // A11: errors only in R1; no release health. Performance spans and
      // on-device measurements are deferred to A42 (09 §5).
      ..enableAutoSessionTracking = false
      ..enableNativeCrashHandling = false
      ..anrEnabled = false
      ..enableNdkScopeSync = false
      ..enableScopeSync = false
      // Dart envelopes still use the native transport (A11 WP0).
      ..autoInitializeNativeSdk = true
      ..sendClientReports = false
      ..debug = false
      ..tracesSampleRate = null;
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

/// Synthetic exception for the About test report; no real user data.
final class TestErrorReport implements Exception {
  /// Creates the fixed synthetic error.
  // Distinct objects: SDK deduplication drops a repeated identical throwable.
  new();

  @override
  String toString() => ErrorReporting.testReportCanary;
}

/// The app's [ErrorReporting]; `AppBootstrap` starts it after the first
/// frame.
@Riverpod(keepAlive: true)
ErrorReporting errorReporting(Ref ref) => ErrorReporting(
  config: ref.watch(appConfigProvider),
  packageInfo: () => ref.read(packageInfoProvider.future),
);
