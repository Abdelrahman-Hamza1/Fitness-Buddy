// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/catalog_food.dart';
import '../models/catalog_pack.dart';
import '../models/catalog_search_page.dart';

part 'catalog_client.g.dart';

@RestApi()
abstract class CatalogClient {
  factory CatalogClient(Dio dio, {String? baseUrl}) = _CatalogClient;

  /// Search published catalog foods.
  ///
  /// Any authenticated account, including guests. Limit 1–50. Cursor is opaque and bound to the normalized query and current release; invalid, stale or mismatched cursors return 400. Empty normalized queries return no results. Results are deduplicated before pagination: verified basics, then reference variants; exact, prefix, token, substring and typo matches within each group, stable ID breaks ties. Personal results are merged on the phone (A24).
  @GET('/v1/foods/search')
  Future<CatalogSearchPage> searchFoods({
    @Query('query') required String query,
    @Query('limit') required int limit,
    @Query('cursor') String? cursor,
  });

  /// Get a catalog food by stable ID.
  ///
  /// Get a catalog food by stable ID. Any authenticated account, including guests.
  @GET('/v1/foods/{id}')
  Future<CatalogFood> getFood({@Path('id') required String id});

  /// Get the latest published offline pack.
  ///
  /// URL is relative to this API origin and requires the same bearer token and client headers. Verify SHA256 and byte size before installing. Retired published versions remain downloadable.
  @GET('/v1/catalog/packs/latest')
  Future<CatalogPack> getLatestCatalogPack();

  /// Download an immutable offline pack.
  ///
  /// Download an immutable offline pack. Any authenticated account, including guests.
  @GET('/v1/catalog/packs/{version}')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> downloadCatalogPack({
    @Path('version') required int version,
  });
}
