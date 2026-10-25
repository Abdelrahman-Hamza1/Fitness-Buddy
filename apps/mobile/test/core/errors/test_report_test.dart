import 'dart:async';
import 'dart:convert';

import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/errors/pii_scrubber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// Exercise the pinned SDK's actual framework handler without native init.
import 'package:sentry_flutter/src/exception/flutter_error_integration.dart';

final class _Sink extends Transport {
  new(this.options);
  final SentryOptions options;
  final envelopes = <String>[];
  final received = Completer<void>();

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelopes.add(
      utf8.decode(
        await envelope
            .envelopeStream(options)
            .expand((bytes) => bytes)
            .toList(),
      ),
    );
    if (envelopes.length == 2) received.complete();
    return envelope.header.eventId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PR-11 sendTestReport sends a scrubbed handled event and a scrubbed '
      'unhandled one; inert with an empty DSN', () async {
    final options = SentryFlutterOptions();
    final sink = _Sink(options);
    final previous = FlutterError.onError;
    // Prevent Flutter's test framework from treating the intentional error as
    // a test failure; the real Sentry handler wraps this no-op.
    FlutterError.onError = (_) {};
    addTearDown(() async {
      await Sentry.close();
      FlutterError.onError = previous;
    });
    await Sentry.init((configured) {
      ErrorReporting.configure(
        options,
        dsn: 'https://k@o1.ingest.de.sentry.io/1',
        environment: 'test',
        release: 'test',
      );
      configured.integrations.forEach(configured.removeIntegration);
      options
        ..addIntegration(FlutterErrorIntegration())
        ..transport = sink;
      // SDK exposes custom options for tests, avoiding all native integrations.
      // ignore: invalid_use_of_internal_member
    }, options: options);

    ErrorReporting reporter(String dsn) => ErrorReporting(
      config: AppConfig(
        flavor: AppFlavor.dev,
        apiBaseUrl: Uri.parse('http://127.0.0.1'),
        sentryDsn: dsn,
      ),
      packageInfo: () async => PackageInfo(
        appName: 'test',
        packageName: 'test',
        version: '1',
        buildNumber: '1',
      ),
    );
    await reporter('').sendTestReport();
    expect(sink.envelopes, isEmpty);
    await reporter(options.dsn!).sendTestReport();
    await sink.received.future.timeout(const Duration(seconds: 5));
    final combined = sink.envelopes.join();
    expect(combined, isNot(contains(ErrorReporting.testReportCanary)));
    expect(combined, contains('"handled":true'));
    expect(combined, contains('"handled":false'));
    expect(combined, contains('[scrubbed]'));
  });

  test('PR-11 scrubber: canary food text in exception value, message params, '
      'breadcrumb, contexts, non-allow-listed tags, and a FlutterErrorDetails '
      'with the canary in context/informationCollector → absent from the '
      'serialized envelope', () async {
    const canary = ErrorReporting.testReportCanary;
    final options = SentryFlutterOptions();
    ErrorReporting.configure(
      options,
      dsn: 'https://k@o1.ingest.de.sentry.io/1',
      environment: 'test',
      release: 'test',
    );
    final sink = _Sink(options);
    options.transport = sink;
    final hub = Hub(options);
    addTearDown(hub.close);
    final details = FlutterErrorDetails(
      exception: TestErrorReport(),
      context: ErrorDescription(canary),
      informationCollector: () => [ErrorDescription(canary)],
    );
    await hub.captureEvent(
      SentryEvent(
        message: SentryMessage(canary, template: canary, params: [canary]),
        exceptions: [SentryException(type: 'TestErrorReport', value: canary)],
        breadcrumbs: [
          Breadcrumb(message: canary, data: {'food': canary}),
        ],
        tags: {'nativeTag': canary, 'flavor': canary},
        contexts: Contexts()
          ..['flutter_error_details'] = {
            'context': details.context!.toDescription(),
            'information': details.informationCollector!().join(),
          },
      ),
    );
    expect(sink.envelopes, hasLength(1));
    expect(sink.envelopes.single, isNot(contains(canary)));
    expect(
      PiiScrubber.scrubEvent(
        SentryEvent(tags: {'flavor': 'prod', 'nativeTag': canary}),
        Hint(),
      ).tags,
      {'flavor': 'prod'},
    );
  });
}
