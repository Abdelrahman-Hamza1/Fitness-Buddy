import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// The local pita every search for `pita` finds in the bundled pack.
const localPitaId = 'usda:pita_white';

/// A synthetic server-only food (not in the pack) the fake returns.
const onlinePitaId = 'usda:pita_online_only_it';

/// Its English name, distinct from every pack name (no name dedup).
const onlinePitaName = 'Pita chips, baked (server)';

/// An in-app fake of the server catalog search (A24): `GET /v1/foods/search`
/// answers the local pita again (a duplicate by catalog ID that the app must
/// drop) and one server-only food. Everything else fails like no connection
/// (including the pack check), so the rest of the app stays offline.
/// Nothing leaves the device.
final class CatalogFakeAdapter implements HttpClientAdapter {
  /// The search queries seen (synthetic only).
  final List<String> searched = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/v1/foods/search') {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline (online search IT)',
      );
    }
    final query = '${options.queryParameters['query']}';
    searched.add(query);
    final items = query.contains('pita')
        ? [
            _food(localPitaId, 'Pita bread, white', 'خبز عربي أبيض'),
            _food(onlinePitaId, onlinePitaName, null),
          ]
        : const <Map<String, Object?>>[];
    return ResponseBody.fromString(
      jsonEncode({'items': items, 'nextCursor': null}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _food(String id, String en, String? ar) => {
  'catalogKey': id,
  'kind': 'basic',
  'source': 'usda',
  'sourceRef': null,
  'nameEn': en,
  'nameAr': ar,
  'state': 'as_sold',
  'verified': true,
  'catalogVersion': 99,
  'nutrients': {
    'kcal': 275,
    'proteinG': 9.1,
    'carbsG': 55.7,
    'fatG': 1.2,
    'fiberG': 2.2,
  },
  'ranges': null,
  'extras': null,
  'densityGPerMl': null,
  'yieldGroup': null,
  'servings': [
    {
      'unitCode': 'piece',
      'g': 60,
      'ml': null,
      'rangeLo': null,
      'rangeHi': null,
      'source': 'usda',
    },
  ],
};
