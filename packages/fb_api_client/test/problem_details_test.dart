import 'package:fb_api_client/fb_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('ProblemDetails:', () {
    test('ProblemDetails decodes a problem+json body and ignores extension '
        'members', () {
      final problem = ProblemDetails.fromJson({
        'type': '/errors/validation-failed',
        'title': 'One or more fields are invalid.',
        'status': 400,
        'detail': 'See errors.',
        'instance': '/v1/config',
        'traceId': '4bf92f3577b34da6a3ce929d0e0e4736',
        // Extension members (RFC 9457 §3.2): not in the schema, ignored.
        'errors': {
          'text': ['required'],
        },
        'requestId': '0HN7:00000001',
      });

      expect(
        problem,
        const ProblemDetails(
          type: '/errors/validation-failed',
          title: 'One or more fields are invalid.',
          status: 400,
          detail: 'See errors.',
          instance: '/v1/config',
          traceId: '4bf92f3577b34da6a3ce929d0e0e4736',
        ),
      );
    });

    test('detail, instance and traceId are optional members', () {
      final problem = ProblemDetails.fromJson({
        'type': 'about:blank',
        'title': 'Not Found',
        'status': 404,
      });

      expect(problem.detail, isNull);
      expect(problem.instance, isNull);
      expect(problem.traceId, isNull);
    });
  });
}
