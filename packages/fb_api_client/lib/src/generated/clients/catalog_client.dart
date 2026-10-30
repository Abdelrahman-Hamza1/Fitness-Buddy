// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/barcode_product.dart';
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

  /// Look up a packaged food by barcode.
  ///
  /// Any authenticated account, including guests. The code is a GTIN-8, -12, -13 or -14 with a valid check digit (UPC-E is expanded by the app); anything else returns 400. GTIN-12 and zero-padded GTIN-14 are answered under their 13-digit form. The answer comes from the server's licence-isolated Open Food Facts cache (30 days for products, 1 day for unknown codes) or one rate-limited Open Food Facts read; an expired product is served for up to 7 more days while Open Food Facts is unavailable. 404: unknown code. 429: this account's upstream lookups are spent for now. 503 (with Retry-After): Open Food Facts can't be asked right now; retry later. When source is "off", show "© Open Food Facts contributors" with the data (ODbL). complete is true only when all five core nutrients are present; nutrients are per 100 g (basis "g") or per 100 ml (basis "ml"), kcal derived from kJ when only kJ is published. Values are Open Food Facts data, never model output.
  @GET('/v1/foods/barcode/{code}')
  Future<BarcodeProduct> getFoodByBarcode({@Path('code') required String code});

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
