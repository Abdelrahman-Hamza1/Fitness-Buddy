import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/session_reachability_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';

void main() {
  for (final (url, status, signals) in [
    ('https://api.example.test/v1/config', 200, 1),
    ('https://api.example.test:443/v1/config', 204, 1),
    ('https://api.example.test/v1/items', 201, 1),
    ('http://api.example.test/v1/config', 200, 0),
    ('https://api.example.test:444/v1/config', 200, 0),
    ('https://other.example.test/v1/config', 200, 0),
    ('https://api.example.test/v1/config', 302, 0),
    ('https://api.example.test/v1/config', 401, 0),
    ('https://api.example.test/v1/config', 429, 0),
    ('https://api.example.test/v1/config', 503, 0),
  ]) {
    test('Rule:TD-053-api-origin reachability $url '
        'status $status signals=$signals', () async {
      var successes = 0;
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = FakeHttpAdapter(
          respond: json(null, status: status),
        )
        ..interceptors.add(
          SessionReachabilityInterceptor(
            apiBaseUrl: Uri.parse('https://api.example.test'),
            onSuccess: () => successes++,
          ),
        );
      addTearDown(dio.close);
      await dio.get<Object?>(url);
      expect(successes, signals);
    });
  }
}
