import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:test/test.dart';

void main() {
  test(
    'FD-023 generated pack client preserves arbitrary non-UTF8 bytes',
    () async {
      final bytes = <int>[
        ...'SQLite format 3'.codeUnits,
        0,
        255,
        128,
        192,
        254,
        0,
        10,
      ];
      final adapter = _BinaryAdapter(bytes);
      final dio = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid'))
        ..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final actual = await CatalogClient(dio).downloadCatalogPack(version: 1);
      expect(actual, orderedEquals(bytes));
      expect(adapter.requests.single.responseType, ResponseType.bytes);
      expect(adapter.requests.single.path, '/v1/catalog/packs/1');
    },
  );
}

final class _BinaryAdapter(final List<int> bytes) implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
