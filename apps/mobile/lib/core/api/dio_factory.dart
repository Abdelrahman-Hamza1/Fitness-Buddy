import 'package:dio/dio.dart';

/// Timeouts of API requests (S06 plan D8). Buddy requests will override the
/// receive timeout per request.
abstract final class ApiTimeouts {
  /// Opening the connection.
  static const connect = Duration(seconds: 10);

  /// Sending the request body.
  static const send = Duration(seconds: 15);

  /// Waiting for the response.
  static const receive = Duration(seconds: 15);
}

/// A [Dio] for the Fitness Buddy API at [baseUrl], sending through
/// [adapter] (the platform's HTTP client; a fake in tests).
///
/// API only: its interceptors add the client headers (with the install's
/// device id) and react to the API's 426. Calls to any other host get
/// their own client, never this one.
///
/// Never follows redirects: the API contract has none, and dart:io would
/// copy the client headers (the device id) to the redirect target.
///
/// No logging interceptor: request and response bodies can carry user
/// content (CLAUDE.md rule 6).
Dio createApiDio({
  required Uri baseUrl,
  required HttpClientAdapter adapter,
  required List<Interceptor> interceptors,
}) =>
    Dio(
        BaseOptions(
          baseUrl: baseUrl.toString(),
          connectTimeout: ApiTimeouts.connect,
          sendTimeout: ApiTimeouts.send,
          receiveTimeout: ApiTimeouts.receive,
          followRedirects: false,
        ),
      )
      ..httpClientAdapter = adapter
      ..interceptors.addAll(interceptors);
