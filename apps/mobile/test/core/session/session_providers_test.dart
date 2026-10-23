import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/test_phone.dart';
import 'session_fakes.dart';

void main() {
  test(
    'UX-001 watch state and build service are lazy and token-free',
    () async {
      final f = Fixture();
      final container = ProviderContainer(
        overrides: [
          secureSessionStoreProvider.overrideWithValue(f.store),
          authTransportProvider.overrideWithValue(f.auth),
          sessionClockProvider.overrideWithValue(f.clock),
        ],
      );
      addTearDown(container.dispose);
      final states = <String>[];
      container.listen(
        sessionStateProvider,
        (_, next) => states.add(next.toString()),
        fireImmediately: true,
      );
      expect(container.read(sessionStateProvider).status, SessionStatus.none);
      final service = container.read(sessionServiceProvider);
      expect(f.secrets.reads, 0);
      expect(f.auth.creates, 0);
      await service.startAfterFirstFrame();
      await container.pump();
      expect(
        container.read(sessionStateProvider).status,
        SessionStatus.anonymous,
      );
      expect(states.join(), isNot(contains('synthetic')));
    },
  );
  test(
    'AC-001 provider auth transport rotates without interceptor recursion',
    () async {
      final f = Fixture();
      final phone = TestPhone(
        config: AppConfig(
          flavor: AppFlavor.dev,
          apiBaseUrl: Uri.parse('https://api.example.test'),
          sentryDsn: '',
        ),
      );
      final auth = FakeHttpAdapter(
        respond: (r) => json(
          tokens(suffix: r.path == '/v1/auth/anonymous' ? '1' : '2').toJson(),
        )(r),
      );
      phone.adapter.respond = (r) => json(
        null,
        status: r.headers['Authorization'] == 'Bearer synthetic-access-1'
            ? 401
            : 200,
      )(r);
      final container = ProviderContainer.test(
        overrides: [
          ...phone.overrides(),
          secureSessionStoreProvider.overrideWithValue(f.store),
          sessionClockProvider.overrideWithValue(f.clock),
          authHttpClientAdapterProvider.overrideWithValue(auth),
        ],
      );
      final dio = container.read(dioProvider);
      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
      await container.read(sessionServiceProvider).startAfterFirstFrame();
      await dio.get<void>('/v1/me');
      expect(auth.requests.map((r) => r.path), [
        '/v1/auth/anonymous',
        '/v1/auth/refresh',
      ]);
      for (final request in auth.requests) {
        expect(request.followRedirects, isFalse);
        expect(
          request.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('authorization')),
        );
        expect(request.headers['X-App-Version'], phone.appVersion);
        expect(
          request.headers['X-Device-Id'],
          phone.adapter.requests.first.headers['X-Device-Id'],
        );
      }
      expect(phone.adapter.requests, hasLength(2));
    },
  );
}
