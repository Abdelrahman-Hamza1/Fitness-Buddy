import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:test/test.dart';

import 'helpers/fake_adapter.dart';

void main() {
  group('Account client:', () {
    test('getConfig calls GET /v1/config without header params and decodes '
        'ClientConfig maps', () async {
      final adapter = FakeAdapter(
        body: {
          'minimumAppVersion': '1.2.3',
          'featureFlags': {'buddy': true, 'barcode': false},
          'thresholds': {'aiConfidenceMin': 0.8, 'maxItems': 12},
        },
      );

      // getConfig() takes no arguments: the client headers are skipped
      // parameters, set later by a dio interceptor.
      final config = await FbApi(fakeDio(adapter)).account.getConfig();

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), 'https://api.test/v1/config');
      for (final header in clientHeaders) {
        expect(request.headers.keys, isNot(contains(header)));
      }
      expect(config.minimumAppVersion, '1.2.3');
      expect(config.featureFlags, {'buddy': true, 'barcode': false});
      // `number` + `format: double`: an integer on the wire is still a double.
      expect(config.thresholds['maxItems'], isA<double>());
      expect(config.thresholds, {'aiConfidenceMin': 0.8, 'maxItems': 12.0});
    });

    test("ClientConfig decodes the server's default (empty maps) and "
        'round-trips', () {
      final json = {
        'minimumAppVersion': '0.1.0',
        'featureFlags': <String, Object?>{},
        'thresholds': <String, Object?>{},
      };

      final config = ClientConfig.fromJson(json);

      expect(config.featureFlags, isEmpty);
      expect(config.thresholds, isEmpty);
      expect(config.toJson(), json);
      expect(ClientConfig.fromJson(config.toJson()), config);
    });

    test('a 500 problem+json response surfaces as a DioException with a '
        'ProblemDetails body', () async {
      final adapter = FakeAdapter(
        statusCode: 500,
        contentType: 'application/problem+json',
        body: {
          'type': 'https://tools.ietf.org/html/rfc9110#section-15.6.1',
          'title': 'An error occurred while processing your request.',
          'status': 500,
          'traceId': '00-abc-def-01',
        },
      );

      DioException? error;
      try {
        await FbApi(fakeDio(adapter)).account.getConfig();
      } on DioException catch (e) {
        error = e;
      }

      expect(error?.type, DioExceptionType.badResponse);
      // dio decodes `application/problem+json` as JSON (a `+json` type).
      final data = error!.response!.data as Map<String, Object?>;
      final problem = ProblemDetails.fromJson(data);
      expect(problem.status, 500);
      expect(problem.detail, isNull);
    });
  });
}
