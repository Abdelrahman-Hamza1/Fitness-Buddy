import 'package:fb_mobile/core/errors/pii_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Text that stands for user content: it must never reach Sentry.
const _secret = 'chicken shawarma 250 g, 82.4 kg';

SentryEvent _event() => SentryEvent(
  message: SentryMessage(
    'Saving failed',
    template: 'Saving %s failed',
    params: [_secret],
  ),
  exceptions: [
    SentryException(
      type: 'FormatException',
      value: 'Invalid input: $_secret',
      stackTrace: SentryStackTrace(
        frames: [SentryStackFrame(function: 'parse', lineNo: 12)],
      ),
      mechanism: Mechanism(
        type: 'FlutterError',
        description: _secret,
        data: {'value': _secret},
      ),
    ),
  ],
  user: SentryUser(id: 'device-id', username: _secret),
  request: SentryRequest(url: 'https://api.test/v1/x?q=$_secret'),
  serverName: 'Sam’s phone',
  tags: {'flavor': 'dev'},
  contexts: Contexts(
    device: SentryDevice(name: 'Sam’s phone', model: 'SM-A556B'),
    operatingSystem: SentryOperatingSystem(name: 'Android', version: '16'),
    app: SentryApp(name: 'Fitness Buddy', version: '0.1.0'),
  )..['flutter_error_details'] = {'information': 'Text("$_secret")'},
  breadcrumbs: [
    Breadcrumb(message: _secret, category: 'ui.click', data: {'t': _secret}),
    Breadcrumb(
      category: 'navigation',
      type: 'navigation',
      data: {
        'state': 'didPush',
        'from': '/today',
        'to': '/me',
        'to_arguments': {'note': _secret},
      },
    ),
  ],
  // Deprecated but still sent, so the scrubber must drop it.
  // ignore: deprecated_member_use
  extra: {'note': _secret},
);

void main() {
  group('PiiScrubber drops user, request, extra, breadcrumb data and '
      'exception values; keeps type and stack', () {
    test('scrubEvent', () {
      final event = PiiScrubber.scrubEvent(_event(), Hint());

      expect(event.user, isNull);
      expect(event.request, isNull);
      expect(event.serverName, isNull);
      // Deprecated but still sent (see above).
      // ignore: deprecated_member_use
      expect(event.extra, isNull);
      expect(event.message?.params, isNull);

      final exception = event.exceptions!.single;
      expect(exception.type, 'FormatException');
      expect(exception.value, PiiScrubber.scrubbed);
      expect(exception.stackTrace!.frames.single.function, 'parse');
      expect(exception.mechanism!.type, 'FlutterError');
      expect(exception.mechanism!.description, isNull);
      expect(exception.mechanism!.data, isEmpty);

      expect(event.contexts.device!.name, isNull);
      expect(event.contexts.device!.model, 'SM-A556B');
      expect(event.contexts.operatingSystem!.version, '16');
      expect(event.contexts.app!.version, '0.1.0');
      expect(event.contexts.keys, isNot(contains('flutter_error_details')));
      expect(event.tags, {'flavor': 'dev'});

      final [click, navigation] = event.breadcrumbs!;
      expect(click.category, 'ui.click');
      expect(click.message, isNull);
      expect(click.data, isNull);
      expect(navigation.data, {
        'state': 'didPush',
        'from': '/today',
        'to': '/me',
      });

      // Belt and braces: the secret appears nowhere in what is sent.
      expect(event.toJson().toString(), isNot(contains('shawarma')));
      expect(event.toJson().toString(), isNot(contains('Sam’s')));
    });

    test('kept contexts lose per-install ids and unknown fields', () {
      // As the native SDK (LoadContextsIntegration) fills them on Android.
      final contexts = Contexts.fromJson({
        'device': {
          'name': 'Sam’s phone',
          'model': 'SM-A556B',
          'id': 'native-device-id-1234',
          'device_unique_identifier': 'unique-id-5678',
          'boot_time': '2026-10-01T08:00:00.000Z',
          'some_new_field': 'unknown-device-9',
        },
        'app': {
          'app_version': '0.1.0',
          'device_app_hash': 'app-hash-abcd',
          'permissions': {'camera': 'granted'},
          'some_new_field': 'unknown-app-9',
        },
        'os': {'name': 'Android', 'version': '16', 'extra': 'unknown-os-9'},
        'runtime': {'name': 'Dart', 'version': '3.13', 'x': 'unknown-rt-9'},
        'culture': {'timezone': 'Asia/Amman', 'x': 'unknown-culture-9'},
        'gpu': {'name': 'Mali', 'id': 7, 'x': 'unknown-gpu-9'},
        'trace': {
          'trace_id': '0123456789abcdef0123456789abcdef',
          'span_id': '0123456789abcdef',
          'op': 'default',
          'description': _secret,
          'data': {'note': _secret},
          'x': 'unknown-trace-9',
        },
        'flutter_error_details': {'information': _secret},
      });
      final event = PiiScrubber.scrubEvent(
        SentryEvent(contexts: contexts),
        Hint(),
      );
      final json = event.toJson()['contexts'].toString();

      for (final gone in [
        'Sam’s',
        'native-device-id-1234',
        'unique-id-5678',
        'device_unique_identifier',
        'app-hash-abcd',
        'device_app_hash',
        'boot_time',
        'camera',
        'unknown-',
        'shawarma',
        'flutter_error_details',
      ]) {
        expect(json, isNot(contains(gone)), reason: gone);
      }
      expect(event.contexts.device!.model, 'SM-A556B');
      expect(event.contexts.app!.version, '0.1.0');
      expect(event.contexts.operatingSystem!.version, '16');
      expect(event.contexts.runtimes.single.name, 'Dart');
      expect(event.contexts.culture!.timezone, 'Asia/Amman');
      expect(event.contexts.gpu!.name, 'Mali');
      expect(
        event.contexts.trace!.traceId.toString(),
        '0123456789abcdef0123456789abcdef',
      );
      expect(event.contexts.keys.toSet(), PiiScrubber.keptContexts);
    });

    test('scrubBreadcrumb keeps the category, type and level only', () {
      final crumb = PiiScrubber.scrubBreadcrumb(
        Breadcrumb(
          message: _secret,
          category: 'console',
          type: 'debug',
          level: SentryLevel.warning,
          data: {'line': _secret},
        ),
        Hint(),
      )!;

      expect(crumb.message, isNull);
      expect(crumb.data, isNull);
      expect(crumb.category, 'console');
      expect(crumb.type, 'debug');
      expect(crumb.level, SentryLevel.warning);
      expect(PiiScrubber.scrubBreadcrumb(null, Hint()), isNull);
    });

    test('navigation breadcrumbs keep route names only, as strings', () {
      final crumb = PiiScrubber.scrubBreadcrumb(
        Breadcrumb(
          category: 'navigation',
          data: {
            'state': 'didReplace',
            'from': null,
            'to': '/progress',
            'from_arguments': _secret,
            'to_arguments': {'x': _secret},
          },
        ),
        Hint(),
      )!;

      expect(crumb.data, {'state': 'didReplace', 'to': '/progress'});
    });
  });
}
