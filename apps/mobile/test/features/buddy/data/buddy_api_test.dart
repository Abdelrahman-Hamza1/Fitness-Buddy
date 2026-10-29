import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/features/buddy/data/buddy_api.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    show message;
import '../../../core/session/session_fakes.dart';
import '../../../helpers/fake_http.dart';

const _requestId = '019a1b2c-0000-7000-8000-000000000001';

PreparedInterpret _request() => InterpretRequestBuilder.build(
  requestId: _requestId,
  text: '2 eggs',
  now: EntryTime(DateTime.utc(2026, 10, 29, 8), 180),
  slots: DefaultSlots.all,
  personalFoods: const [],
);

void main() {
  final adapter = FakeHttpAdapter();
  final dio = createApiDio(
    baseUrl: Uri.parse('https://api.test'),
    adapter: adapter,
    interceptors: [],
  );
  final api = BuddyApi(dio);
  setUp(adapter.requests.clear);

  // rule: A22 buddy-receive-timeout
  test('A22 interpret requests use a 45 second receive timeout', () async {
    adapter.respond = json(message());
    expect(await api.interpret(_request()), isA<BuddyInterpreted>());
    final request = adapter.requests.single;
    expect(request.receiveTimeout, const Duration(seconds: 45));
    expect(request.path, '/v1/buddy/interpret');
    expect(request.headers['Idempotency-Key'], _requestId);
    expect((request.data as Map<String, Object?>)['requestId'], _requestId);
    // Every other endpoint keeps 15 s, also on the same dio.
    adapter.respond = config('0.0.0');
    await FbApi(dio).account.getConfig();
    expect(adapter.requests.last.receiveTimeout, ApiTimeouts.receive);
    expect(dio.options.receiveTimeout, ApiTimeouts.receive);
    expect(BuddyApi.receiveTimeout, const Duration(seconds: 45));
  });

  // rule: A22 failure-classes
  test(
    'A22 interpret failures map to the closed send failure classes',
    () async {
      final cases = <(FakeResponder, BuddySendFailure)>[
        (offline, BuddySendFailure.offline),
        (timeout, BuddySendFailure.timeout),
        (json({'status': 500}, status: 500), BuddySendFailure.server),
        (json({'status': 502}, status: 502), BuddySendFailure.server),
        (json({'status': 503}, status: 503), BuddySendFailure.unavailable),
        (json({'status': 400}, status: 400), BuddySendFailure.rejected),
        (json({'status': 409}, status: 409), BuddySendFailure.rejected),
        (json({'status': 401}, status: 401), BuddySendFailure.rejected),
        (json({'status': 426}, status: 426), BuddySendFailure.rejected),
        (json({'status': 429}, status: 429), BuddySendFailure.rateLimited),
      ];
      for (final (responder, failure) in cases) {
        adapter.respond = responder;
        final result = await api.interpret(_request());
        expect(
          result,
          isA<BuddyInterpretFailed>().having(
            (r) => r.failure,
            'failure',
            failure,
          ),
        );
      }
      expect(
        [
          for (final f in BuddySendFailure.values)
            if (f.retryable) f,
        ],
        [
          BuddySendFailure.offline,
          BuddySendFailure.timeout,
          BuddySendFailure.server,
          BuddySendFailure.unavailable,
        ],
      );
    },
  );

  // rule: A22 raw-answer
  test('A22 the decoder gets the raw answer map, not a round-tripped '
      'model', () async {
    final body = {
      ...message([
        {
          ...(message()['intents']! as List<Object?>).single!
              as Map<String, Object?>,
          'dateHint': 'yesterday',
        },
        {
          'kind': 'workout',
          'language': 'english',
          'script': 'latin',
          'exercises': ['x'],
        },
      ]),
    };
    adapter.respond = json(body);
    final result = await api.interpret(_request()) as BuddyInterpreted;
    final intents = result.json['intents']! as List<Object?>;
    expect((intents[0]! as Map<String, Object?>)['dateHint'], 'yesterday');
    expect(intents[1], (body['intents']! as List<Object?>)[1]);
    expect(result.json, body);
  });

  // rule: A22 unusable-reply
  test('A22 a 200 that is not a contract-valid interpretation is unusable '
      'and content-free', () async {
    const canary = 'CANARY-A22-API';
    for (final body in <Object?>[
      {'promptVersion': canary},
      {'promptVersion': 'interpret-v1', 'model': 1, 'intents': canary},
      [canary],
    ]) {
      adapter.respond = json(body);
      final result = await api.interpret(_request());
      expect(result, isA<BuddyUnusableReply>());
      expect('$result', isNot(contains(canary)));
    }
    adapter.respond = json(message());
    final ok = await api.interpret(_request());
    expect('$ok', 'BuddyInterpreted(redacted)');
    expect((ok as BuddyInterpreted).json['promptVersion'], 'interpret-v1');
    expect('$api', 'BuddyApi');
    expect('${_request()}', 'PreparedInterpret($_requestId)');
    expect(
      '${const BuddyInterpretFailed(BuddySendFailure.offline)}',
      'BuddyInterpretFailed(offline)',
    );
  });

  // rule: A22 raw-answer-after-refresh
  test(
    'A22 an answer replayed after a 401 refresh is still read raw',
    () async {
      final f = Fixture();
      await f.service.startAfterFirstFrame();
      f.auth.rotate = (_) async => tokens(suffix: '2');
      final auth = FakeHttpAdapter(
        respond: (r) =>
            r.headers['Authorization'] == 'Bearer synthetic-access-2'
            ? json(message())(r)
            : json({'status': 401}, status: 401)(r),
      );
      final base = Uri.parse('https://api.test');
      final authed = createApiDio(
        baseUrl: base,
        adapter: auth,
        interceptors: [],
      );
      authed.interceptors.add(
        AuthInterceptor(
          apiBaseUrl: base,
          dio: authed,
          session: () => f.service,
        ),
      );
      addTearDown(() => authed.close(force: true));
      final result = await BuddyApi(authed).interpret(_request());
      expect(result, isA<BuddyInterpreted>());
      expect(
        (result as BuddyInterpreted).json['promptVersion'],
        'interpret-v1',
      );
      expect(f.auth.refreshes, 1);
      expect(auth.requests, hasLength(2));
      // The replay kept the Buddy timeout and the Idempotency-Key.
      expect(auth.requests.last.receiveTimeout, BuddyApi.receiveTimeout);
      expect(auth.requests.last.headers['Idempotency-Key'], _requestId);
    },
  );
}
