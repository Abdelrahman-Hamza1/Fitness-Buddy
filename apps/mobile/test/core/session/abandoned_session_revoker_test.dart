import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/test_phone.dart';

void main() {
  test('AC-003 A33 an abandoned session is revoked with its own bearer on '
      'the auth transport, not the app session', () async {
    final phone = TestPhone();
    final auth = FakeHttpAdapter(respond: json(null, status: 204));
    final container = ProviderContainer(
      overrides: [
        ...phone.overrides(),
        authHttpClientAdapterProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);

    await container.read(abandonedSessionRevokerProvider)(
      'synthetic-abandoned-access',
    );

    final request = auth.requests.single;
    expect(request.path, '/v1/auth/logout');
    expect(
      request.headers['Authorization'],
      'Bearer synthetic-abandoned-access',
    );
    expect(phone.adapter.requests, isEmpty, reason: 'not the app API client');
  });
}
