import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'session_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Rule:09.4-no-content-logging plugin zone provider '
      'and serialized sinks', () async {
    const canary = 'synthetic-private-user-text-and-token';
    final prints = <String>[];
    final flutterErrors = <String>[];
    final zoneErrors = <String>[];
    final observer = _Observer();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => flutterErrors.add(details.toString());
    addTearDown(() => FlutterError.onError = previous);
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Keep test setup and teardown registration at the operation boundary.
    // ignore: cascade_invocations
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
        code: 'unavailable',
        message: canary,
        details: canary,
      );
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final options = SentryFlutterOptions();
    ErrorReporting.configure(
      options,
      dsn: 'https://key@sentry.example.test/1',
      environment: 'test',
      release: 'fb_mobile@test',
    );
    final sink = _Sink(options);
    options.transport = sink;
    final hub = Hub(options);
    addTearDown(hub.close);
    final f = Fixture();
    final container = ProviderContainer.test(
      observers: [observer],
      overrides: [
        secureSessionStoreProvider.overrideWithValue(
          SecureSessionStore(
            flavor: 'dev',
            origin: Uri.parse('https://api.example.test'),
            storage: const PluginSessionSecretStorage(),
            durability: f.barrier,
          ),
        ),
        authTransportProvider.overrideWithValue(f.auth),
        sessionClockProvider.overrideWithValue(f.clock),
      ],
    );
    // Keep test setup and teardown registration at the operation boundary.
    // ignore: cascade_invocations
    container.listen(sessionStateProvider, (_, _) {});
    await runZoned(
      () async {
        final service = container.read(sessionServiceProvider);
        await expectLater(
          service.startAfterFirstFrame(),
          throwsA(isA<SessionFailure>()),
        );
        expect(service.state.readiness, SessionReadiness.unavailable);
        expect(f.auth.creates, 0);
        // Generated toString intentionally contains raw fields: it must be
        // scrubbed at reporting, never installed as provider state or printed.
        final generated = tokens(id: canary, suffix: canary);
        expect(generated.toString().contains(canary), isTrue);
        final error = DioException(
          requestOptions: RequestOptions(
            path: '/v1/me',
            headers: {'Authorization': canary},
            data: {'text': canary},
          ),
          error: generated,
          message: generated.toString(),
        );
        await hub.captureException(error);
        await hub.captureException(
          PlatformException(
            code: 'unavailable',
            message: canary,
            details: canary,
          ),
        );
        // Exercise Flutter and uncaught-zone paths with the production-safe
        // error that the plugin adapter/coordinator exposes, not raw platform data.
        try {
          await container.read(secureSessionStoreProvider).readActive();
        } on SessionStorageFailure catch (safe) {
          FlutterError.reportError(FlutterErrorDetails(exception: safe));
          Zone.current
              .fork(
                specification: ZoneSpecification(
                  handleUncaughtError: (_, _, _, error, _) =>
                      zoneErrors.add(error.toString()),
                ),
              )
              .handleUncaughtError(safe, StackTrace.current);
          await hub.captureException(safe);
        }
        await container.pump();
        final healthy = ProviderContainer.test(
          observers: [observer],
          overrides: [
            secureSessionStoreProvider.overrideWithValue(f.store),
            authTransportProvider.overrideWithValue(f.auth),
            sessionClockProvider.overrideWithValue(f.clock),
          ],
        )..listen(sessionStateProvider, (_, _) {});
        f.auth.create = () async => tokens(id: canary, suffix: canary);
        final lease = await healthy
            .read(sessionServiceProvider)
            .startAfterFirstFrame();
        expect(lease.toString().contains(canary), isFalse);
        await healthy.pump();
        expect(
          healthy.read(sessionStateProvider).toString().contains(canary),
          isFalse,
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => prints.add(line),
      ),
    );
    expect(flutterErrors, isNotEmpty);
    expect(zoneErrors, isNotEmpty);
    expect(observer.values, isNotEmpty);
    expect(sink.envelopes.length, 3);
    for (final output in [
      prints,
      flutterErrors,
      zoneErrors,
      observer.values,
      sink.envelopes,
    ]) {
      expect(output.join().contains(canary), isFalse);
    }
  });
}

final class _Observer extends ProviderObserver {
  final values = <String>[];
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      values.add('$value');
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => values.add('$newValue');
}

final class _Sink extends Transport {
  new(this.options);
  final SentryOptions options;
  final envelopes = <String>[];
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
    return envelope.header.eventId;
  }
}
