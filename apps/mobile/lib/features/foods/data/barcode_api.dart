import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart' as api;
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'barcode_api.g.dart';

/// Open Food Facts data as the server returned it (B10a D2). ODbL: the app
/// shows "© Open Food Facts contributors" wherever it displays it. Nutrients
/// are per 100 g, or per 100 ml when [perMl]; null = not published.
final class OffProduct {
  /// Creates the product.
  const new({
    required this.code,
    required this.isOff,
    required this.complete,
    required this.perMl,
    this.name,
    this.nameAr,
    this.brand,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.servingQuantity,
    this.servingLabel,
    this.ingredients,
    this.labels = const [],
    this.checkLabel = false,
  });

  /// The normalized barcode.
  final String code;

  /// The data comes from Open Food Facts (attribution needed).
  final bool isOff;

  /// All five core nutrients are published.
  final bool complete;

  /// Values are per 100 ml.
  final bool perMl;

  /// The product name (English when OFF has one).
  final String? name;

  /// The Arabic name.
  final String? nameAr;

  /// The first brand.
  final String? brand;

  /// kcal per 100.
  final double? kcal;

  /// Protein g per 100.
  final double? protein;

  /// Carbohydrates g per 100.
  final double? carbs;

  /// Fat g per 100.
  final double? fat;

  /// Fiber g per 100.
  final double? fiber;

  /// One serving on the basis unit.
  final double? servingQuantity;

  /// OFF's serving text, e.g. "30 g".
  final String? servingLabel;

  /// The ingredient list.
  final String? ingredients;

  /// OFF label and ingredient-analysis tags (`en:halal`, `en:vegan`…).
  final List<String> labels;

  /// The server's sanity checks passed but something looks off (B22): the
  /// scan screen says to compare the numbers with the label.
  final bool checkLabel;
}

/// How the server lookup ended.
sealed class BarcodeApiResult {
  const new();
}

/// The server knows the product.
final class BarcodeApiFound extends BarcodeApiResult {
  /// Creates the result.
  const new(this.product);

  /// The product.
  final OffProduct product;
}

/// No product is known for the code (404).
final class BarcodeApiNotFound extends BarcodeApiResult {
  /// Creates the result.
  const new();
}

/// The lookup couldn't run now: offline, timeout, no session, rate limited
/// or the server/OFF unavailable. Worth trying again later.
final class BarcodeApiUnavailable extends BarcodeApiResult {
  /// Creates the result.
  const new();
}

/// `GET /v1/foods/barcode/{code}` over the generated client. Never throws;
/// nothing is logged (a barcode says what the user eats).
final class BarcodeApi {
  /// Looks up through [client].
  const new(this.client);

  /// The generated catalog client.
  final api.CatalogClient client;

  /// The server's answer for the normalized [code].
  Future<BarcodeApiResult> lookup(String code) async {
    try {
      final p = await client.getFoodByBarcode(code: code);
      return BarcodeApiFound(
        OffProduct(
          code: p.code,
          isOff: p.source == 'off',
          complete: p.complete,
          perMl: p.basis == 'ml',
          name: p.name,
          nameAr: p.nameAr,
          brand: p.brand,
          kcal: p.per100.kcal,
          protein: p.per100.proteinG,
          carbs: p.per100.carbsG,
          fat: p.per100.fatG,
          fiber: p.per100.fiberG,
          servingQuantity: p.servingQuantity,
          servingLabel: p.servingLabel,
          ingredients: p.ingredientsText,
          labels: p.labels,
          checkLabel: p.checkLabel,
        ),
      );
    } on DioException catch (error) {
      return error.response?.statusCode == 404
          ? const BarcodeApiNotFound()
          : const BarcodeApiUnavailable();
    } on Object {
      return const BarcodeApiUnavailable();
    }
  }
}

/// The barcode client over the app's API.
@riverpod
BarcodeApi barcodeApi(Ref ref) => BarcodeApi(ref.watch(fbApiProvider).catalog);
