import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/failure_mapper.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:fb_mobile/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

final _request = RequestOptions(path: '/v1/anything');

/// A `badResponse` error with [status], [body] and [headers].
DioException _response(
  int status, {
  Object? body,
  Map<String, List<String>> headers = const {},
}) => DioException.badResponse(
  statusCode: status,
  requestOptions: _request,
  response: Response<Object?>(
    requestOptions: _request,
    statusCode: status,
    data: body,
    headers: Headers.fromMap(headers),
  ),
);

/// A problem details body.
Map<String, Object?> _problem(
  String type,
  int status, [
  Map<String, Object?> extensions = const {},
]) => {'type': type, 'title': 'Test', 'status': status, ...extensions};

/// The rows of the "Error type catalogue" table in contracts/README.md:
/// type → status.
Map<String, int> _readmeCatalogue() {
  final readme = File('../../contracts/README.md').readAsLinesSync();
  final start = readme.indexWhere((l) => l.startsWith('### Error type '));
  expect(start, isNot(-1), reason: 'catalogue heading not found');
  final row = RegExp(r'^\| `(/errors/[a-z0-9-]+)` \| (\d{3}) \|');
  return {
    for (final line
        in readme.skip(start + 1).takeWhile((l) => !l.startsWith('#')))
      if (row.firstMatch(line) case final m?) m.group(1)!: int.parse(m[2]!),
  };
}

void main() {
  group('FailureMapper maps each catalogue type', () {
    test('validation-failed → InvalidInput with the field errors', () {
      final failure = FailureMapper.fromDio(
        _response(
          400,
          body: _problem(ProblemTypes.validationFailed, 400, {
            'errors': {
              'name': ['Required.', 'Too long.'],
              'amount': ['Must be positive.', 7],
              'broken': 'not a list',
            },
          }),
        ),
      );

      expect(
        failure,
        isA<InvalidInputFailure>().having((f) => f.fieldErrors, 'fieldErrors', {
          'name': ['Required.', 'Too long.'],
          'amount': ['Must be positive.'],
        }),
      );
    });

    test('rate-limited → RateLimited with Retry-After', () {
      final failure = FailureMapper.fromDio(
        _response(
          429,
          body: _problem(ProblemTypes.rateLimited, 429),
          headers: {
            'retry-after': ['30'],
          },
        ),
      );

      expect(
        failure,
        isA<RateLimitedFailure>().having(
          (f) => f.retryAfter,
          'retryAfter',
          const Duration(seconds: 30),
        ),
      );
    });

    test('version-conflict → Conflict; upgrade-required → UpgradeRequired', () {
      expect(
        FailureMapper.fromDio(
          _response(412, body: _problem(ProblemTypes.versionConflict, 412)),
        ),
        isA<ConflictFailure>(),
      );
      expect(
        FailureMapper.fromDio(
          _response(426, body: _problem(ProblemTypes.upgradeRequired, 426)),
        ),
        isA<UpgradeRequiredFailure>(),
      );
    });

    test('the type wins over the status', () {
      expect(
        FailureMapper.fromDio(
          _response(400, body: _problem(ProblemTypes.upgradeRequired, 400)),
        ),
        isA<UpgradeRequiredFailure>(),
      );
    });

    test('a Retry-After that is not a number of seconds is ignored', () {
      for (final value in ['soon', '-5', 'Wed, 21 Oct 2026 07:28:00 GMT']) {
        final failure = FailureMapper.fromDio(
          _response(
            429,
            body: _problem(ProblemTypes.rateLimited, 429),
            headers: {
              'retry-after': [value],
            },
          ),
        );
        expect(
          (failure as RateLimitedFailure).retryAfter,
          isNull,
          reason: value,
        );
      }
    });
  });

  // Rule: 04 §4.2 errors (golden bodies in contracts/testdata/problems).
  group('golden problem bodies map to a Failure', () {
    final dir = Directory('../../contracts/testdata/problems');
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    );

    // Expected failure per catalogue type; a new golden file needs a row.
    final expected = <String, Matcher>{
      ProblemTypes.validationFailed: isA<InvalidInputFailure>().having(
        (f) => f.fieldErrors.keys.toSet(),
        'fieldErrors keys',
        {'name', 'items[0].qty'},
      ),
      ProblemTypes.upgradeRequired: isA<UpgradeRequiredFailure>(),
      ProblemTypes.rateLimited: isA<RateLimitedFailure>(),
      ProblemTypes.versionConflict: isA<ConflictFailure>(),
      ProblemTypes.unauthorized: isA<UnauthorizedFailure>(),
      ProblemTypes.forbidden: isA<ForbiddenFailure>(),
      ProblemTypes.identityConflict: isA<ConflictFailure>(),
    };

    test('the golden folder is found and covers every catalogue type', () {
      expect(files, isNotEmpty);
      final types = {
        for (final f in files)
          (jsonDecode(f.readAsStringSync()) as Map<String, Object?>)['type']!,
      };
      expect(types, ProblemTypes.all);
    });

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      test(name, () {
        final body =
            jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
        final type = body['type']! as String;
        final matcher = expected[type];
        if (matcher == null) {
          fail('$name: no expectation for type $type; add one');
        }
        final failure = FailureMapper.fromDio(
          _response(body['status']! as int, body: body),
        );
        expect(failure, matcher);
      });
    }
  });

  test('every type in the contracts/README.md catalogue has a ProblemTypes '
      'constant, and each maps like its status', () {
    final catalogue = _readmeCatalogue();

    expect(catalogue.keys.toSet(), ProblemTypes.all);
    for (final MapEntry(key: type, value: status) in catalogue.entries) {
      final byType = FailureMapper.fromDio(
        _response(status, body: _problem(type, status)),
      );
      final byStatus = FailureMapper.fromDio(_response(status));
      expect(byType, isNot(isA<UnexpectedFailure>()), reason: type);
      expect(byType.runtimeType, byStatus.runtimeType, reason: type);
    }
  });

  test(
    'status fallbacks 401/404/412/426/429/5xx (no or unknown problem type)',
    () {
      final expected = <int, Matcher>{
        400: isA<InvalidInputFailure>(),
        401: isA<UnauthorizedFailure>(),
        404: isA<NotFoundFailure>(),
        409: isA<ConflictFailure>(),
        412: isA<ConflictFailure>(),
        426: isA<UpgradeRequiredFailure>(),
        429: isA<RateLimitedFailure>(),
        500: isA<ServerFailure>().having((f) => f.status, 'status', 500),
        503: isA<ServerFailure>().having((f) => f.status, 'status', 503),
        403: isA<ForbiddenFailure>(),
        418: isA<UnexpectedFailure>(),
      };
      for (final MapEntry(key: status, value: matcher) in expected.entries) {
        // No body, and a framework problem with a type we don't map.
        expect(
          FailureMapper.fromDio(_response(status)),
          matcher,
          reason: '$status',
        );
        expect(
          FailureMapper.fromDio(
            _response(status, body: _problem('about:blank', status)),
          ),
          matcher,
          reason: '$status about:blank',
        );
      }
    },
  );

  test('connection error → Offline, timeouts → Timeout, non-JSON body → by '
      'status', () {
    expect(
      FailureMapper.fromDio(
        DioException.connectionError(requestOptions: _request, reason: 'x'),
      ),
      isA<OfflineFailure>(),
    );
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      expect(
        FailureMapper.fromDio(
          DioException(requestOptions: _request, type: type),
        ),
        isA<TimeoutFailure>(),
        reason: '$type',
      );
    }
    for (final type in [
      DioExceptionType.cancel,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ]) {
      expect(
        FailureMapper.fromDio(
          DioException(requestOptions: _request, type: type),
        ),
        isA<UnexpectedFailure>(),
        reason: '$type',
      );
    }
    expect(
      FailureMapper.fromDio(_response(502, body: '<html>Bad gateway</html>')),
      isA<ServerFailure>(),
    );
    // A problem-shaped body with wrong member types is mapped by status.
    expect(
      FailureMapper.fromDio(
        _response(404, body: {'type': 42, 'title': 'x', 'status': 404}),
      ),
      isA<NotFoundFailure>(),
    );
    // badResponse without a response (shouldn't happen).
    expect(
      FailureMapper.fromDio(
        DioException(
          requestOptions: _request,
          type: DioExceptionType.badResponse,
        ),
      ),
      isA<UnexpectedFailure>(),
    );
  });
}
