import 'dart:async';

import 'package:dio/dio.dart';

/// A network that takes requests and never answers them until [failAll].
final class HangingNetwork {
  final List<(Completer<ResponseBody>, RequestOptions)> waiting = [];
  int answered = 0;

  Future<ResponseBody> respond(RequestOptions request) {
    final completer = Completer<ResponseBody>();
    waiting.add((completer, request));
    return completer.future;
  }

  /// Ends every waiting request with a connection error.
  void failAll() {
    for (final (completer, request) in waiting) {
      if (completer.isCompleted) continue;
      answered++;
      completer.completeError(
        DioException.connectionError(requestOptions: request, reason: 'off'),
      );
    }
  }
}
