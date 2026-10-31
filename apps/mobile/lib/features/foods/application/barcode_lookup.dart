import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/barcode_coverage.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/data/barcode_api.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';

export 'package:fb_mobile/features/foods/data/barcode_api.dart' show OffProduct;

/// Where a scanned product's data came from.
enum ScannedSource {
  /// One of the user's own foods.
  personal,

  /// The offline pack.
  pack,

  /// Open Food Facts through the server (attribution required).
  openFoodFacts,
}

/// What the food sheet's product header shows for a scan (FD-030): brand,
/// per serving and per 100, the halal flags, the fiber note and the source.
final class ScannedProduct {
  /// Creates the header data.
  const new({
    required this.code,
    required this.source,
    this.brand,
    this.servingLabel,
    this.halal = const {},
    this.fiberMissing = false,
    this.fromOff = false,
    this.checkLabel = false,
  });

  /// The normalized barcode.
  final String code;

  /// Where the data came from.
  final ScannedSource source;

  /// The values are Open Food Facts data (a live OFF answer, or one of your
  /// foods saved from a scan): the header shows the ODbL credit.
  final bool fromOff;

  /// The brand, when known.
  final String? brand;

  /// OFF's serving text ("30 g"), when known.
  final String? servingLabel;

  /// Halal flags from the name, ingredients and tags (FD-081); shown only
  /// when the Halal setting is on.
  final Set<HalalFlag> halal;

  /// OFF has no fiber value: it's logged as 0 (A28a D9).
  final bool fiberMissing;

  /// The server flagged the numbers (B22): compare them with the label.
  final bool checkLabel;
}

/// How a typed code is read (review fix 4).
enum TypedReading {
  /// As typed: EAN-8, UPC-A, EAN-13 or GTIN-14.
  gtin,

  /// As a UPC-E code, expanded to UPC-A.
  upcE,
}

/// How a scan ended (A28a §1).
sealed class BarcodeOutcome {
  const new();
}

/// The code isn't a product barcode (bad check digit, wrong length).
final class BarcodeInvalid extends BarcodeOutcome {
  /// Creates the outcome.
  const new();
}

/// A product ready for the food sheet. [choice] is a saved food (personal or
/// pack) or a scanned one that's created when logged.
final class BarcodeFound extends BarcodeOutcome {
  /// Creates the outcome.
  const new(this.choice, this.product);

  /// What the food sheet loads and logs.
  final FoodChoice choice;

  /// The product header.
  final ScannedProduct product;
}

/// Open Food Facts knows the product but not enough to log it (no name, a
/// core value missing, or values that fail FD-012): "Add the missing
/// values" opens the form prefilled from [prefill].
final class BarcodeIncomplete extends BarcodeOutcome {
  /// Creates the outcome.
  const new(this.off, this.prefill, this.product);

  /// The OFF data.
  final OffProduct off;

  /// What the personal-food form starts with.
  final ScanPrefill prefill;

  /// The product header.
  final ScannedProduct product;
}

/// No product is known for [code]: "Add it yourself".
final class BarcodeNotFound extends BarcodeOutcome {
  /// Creates the outcome.
  const new(this.code);

  /// The normalized barcode.
  final String code;
}

/// The lookup couldn't run now (offline, server unavailable): the scan
/// waits (A28a D10).
final class BarcodeWaiting extends BarcodeOutcome {
  /// Creates the outcome.
  const new(this.code);

  /// The normalized barcode.
  final String code;
}

/// What "Add it yourself" / "Add the missing values" prefills (A28a D9):
/// the barcode always; name, brand, values and serving when OFF has them.
/// Private; handed over in memory, never in a route.
final class ScanPrefill {
  /// Creates the prefill.
  const new({
    required this.code,
    this.name,
    this.nameAr,
    this.brand,
    this.perMl = false,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.servingQuantity,
    this.halal,
  });

  /// The prefill for an unknown code.
  factory fromOff(OffProduct p) => ScanPrefill(
    code: p.code,
    name: _cap(p.name, PersonalFoodBounds.name),
    nameAr: _cap(p.nameAr, PersonalFoodBounds.name),
    brand: _cap(p.brand, PersonalFoodBounds.brand),
    perMl: p.perMl,
    kcal: p.kcal,
    protein: p.protein,
    carbs: p.carbs,
    fat: p.fat,
    fiber: p.fiber,
    servingQuantity: p.servingQuantity,
    halal: _halalOf(p),
  );

  /// The normalized barcode.
  final String code;

  /// Set when the prefill comes from Open Food Facts: the halal flags from
  /// its ingredients and tags, kept with the saved food (review fix 2).
  /// Null for a code typed by the user alone.
  final Set<HalalFlag>? halal;

  /// The name.
  final String? name;

  /// The Arabic name.
  final String? nameAr;

  /// The brand.
  final String? brand;

  /// Values are per 100 ml.
  final bool perMl;

  /// kcal per 100, when OFF has it.
  final double? kcal;

  /// Protein per 100, when OFF has it.
  final double? protein;

  /// Carbohydrates per 100, when OFF has it.
  final double? carbs;

  /// Fat per 100, when OFF has it.
  final double? fat;

  /// Fiber per 100, when OFF has it.
  final double? fiber;

  /// One serving on the basis unit.
  final double? servingQuantity;
}

Set<HalalFlag> _halalOf(OffProduct p) => HalalCheck.check(
  name: p.name,
  nameAr: p.nameAr,
  ingredients: p.ingredients,
  tags: p.labels,
);

/// The personal food a complete-enough OFF product becomes when logged
/// (A28a D8, D9), or null when it can't be logged as is: no name, kcal,
/// protein, carbs or fat missing, or a hard FD-012 sanity failure. Missing
/// fiber counts as 0. Code computes; nothing here is model output.
PersonalFoodDraft? draftFromOff(OffProduct p) {
  final name = _cap(p.name, PersonalFoodBounds.name);
  final kcal = p.kcal;
  final protein = p.protein;
  final carbs = p.carbs;
  final fat = p.fat;
  bool usable(double? v) => v != null && v.isFinite && v >= 0;
  if (name == null ||
      kcal == null ||
      protein == null ||
      carbs == null ||
      fat == null ||
      ![kcal, protein, carbs, fat].every(usable) ||
      (p.fiber != null && !usable(p.fiber)) ||
      !Gtin.isValid(p.code)) {
    return null;
  }
  double round(double v) => (v * 1000).round() / 1000;
  final serving = switch (p.servingQuantity) {
    final q?
        when q >= PersonalFoodBounds.minServing &&
            q <= PersonalFoodBounds.maxServing =>
      PersonalFoodServing('serving', round(q)),
    _ => null,
  };
  final draft = PersonalFoodDraft(
    names: FoodNames(name, ar: _cap(p.nameAr, PersonalFoodBounds.name)),
    per100: Nutrients(
      kcal: round(kcal),
      protein: round(protein),
      carbs: round(carbs),
      fat: round(fat),
      fiber: round(p.fiber ?? 0),
    ),
    basis: p.perMl ? NutrientBasis.per100ml : NutrientBasis.per100g,
    brand: _cap(p.brand, PersonalFoodBounds.brand),
    barcodes: [p.code],
    servings: [?serving],
    // Review fix 2: the OFF origin, the fiber assumption and the scan's halal
    // flags stay with the food, so later scans show them too.
    createdFrom: OffOrigin(
      fiberAssumed: p.fiber == null,
      halal: _halalOf(p),
    ).encode(),
  );
  return draft.validate() == null ? draft : null;
}

/// Trimmed, at most [max] UTF-16 units without splitting a pair, or null.
String? _cap(String? text, int max) {
  final t = text?.trim();
  if (t == null || t.isEmpty) return null;
  if (t.length <= max) return t;
  var end = max;
  final unit = t.codeUnitAt(end - 1);
  if (unit >= 0xd800 && unit <= 0xdbff) end--;
  return t.substring(0, end).trimRight();
}

/// The barcode chain on the phone (`07` §7, A28a §1): your foods by barcode
/// → the offline pack → the server. Counts each resolved lookup on the
/// device (TD-064). Never throws for a lookup failure.
final class BarcodeLookup {
  /// Creates the chain over its ports.
  new({
    required this.personalByBarcode,
    required this.packByBarcode,
    required this.server,
    required this.newId,
    required this.count,
  });

  /// Step 1: a live personal food with this barcode.
  final Future<PersonalFood?> Function(String code) personalByBarcode;

  /// Step 2: the offline pack.
  final Future<CatalogFood?> Function(String code) packByBarcode;

  /// Step 3: `GET /v1/foods/barcode/{code}`.
  final Future<BarcodeApiResult> Function(String code) server;

  /// Reserves the ID a scanned product is saved under.
  final String Function() newId;

  /// The coverage counter.
  final Future<void> Function(BarcodeCoverageKind kind) count;

  /// Normalizes a scanned or typed code: UPC-E expanded when [upcE], then
  /// GTIN-normalized; null when it isn't a product barcode.
  static String? normalize(String raw, {bool upcE = false}) {
    final digits = raw.trim();
    final expanded = upcE ? Gtin.expandUpcE(digits) : null;
    return Gtin.normalize(expanded ?? digits);
  }

  /// How a typed code can be read (review fix 4): an 8-digit code that is
  /// both a valid EAN-8 and a valid UPC-E is ambiguous and the user picks;
  /// the check digit alone can't tell them apart (`01000009`). Empty when
  /// it's no product barcode.
  static List<TypedReading> typedReadings(String digits) => [
    if (Gtin.normalize(digits) != null) TypedReading.gtin,
    if (digits.length <= 8 && Gtin.expandUpcE(digits) != null)
      TypedReading.upcE,
  ];

  /// Runs the chain for [raw].
  Future<BarcodeOutcome> lookup(String raw, {bool upcE = false}) async {
    final code = normalize(raw, upcE: upcE);
    if (code == null) return const BarcodeInvalid();
    final personal = await personalByBarcode(code);
    if (personal != null) {
      await count(BarcodeCoverageKind.found);
      final off = OffOrigin.decode(personal.createdFrom);
      return BarcodeFound(
        personalChoice(personal),
        ScannedProduct(
          code: code,
          source: ScannedSource.personal,
          brand: personal.brand,
          fromOff: off != null,
          fiberMissing: off?.fiberAssumed ?? false,
          halal: {
            ...?off?.halal,
            ...HalalCheck.check(
              name: personal.names.en,
              nameAr: personal.names.ar,
            ),
          },
        ),
      );
    }
    final packed = await packByBarcode(code);
    if (packed != null) {
      await count(BarcodeCoverageKind.found);
      return BarcodeFound(
        catalogChoice(packed),
        ScannedProduct(
          code: code,
          source: ScannedSource.pack,
          halal: HalalCheck.check(name: packed.nameEn, nameAr: packed.nameAr),
        ),
      );
    }
    switch (await server(code)) {
      case BarcodeApiFound(:final product):
        await count(
          product.complete
              ? BarcodeCoverageKind.found
              : BarcodeCoverageKind.incomplete,
        );
        final header = ScannedProduct(
          code: product.code,
          source: product.isOff
              ? ScannedSource.openFoodFacts
              : ScannedSource.pack,
          brand: product.brand,
          servingLabel: product.servingLabel,
          fiberMissing: product.fiber == null,
          fromOff: product.isOff,
          checkLabel: product.checkLabel,
          halal: _halalOf(product),
        );
        final draft = draftFromOff(product);
        if (draft == null) {
          return BarcodeIncomplete(
            product,
            ScanPrefill.fromOff(product),
            header,
          );
        }
        return BarcodeFound(scannedChoice(newId(), draft), header);
      case BarcodeApiNotFound():
        await count(BarcodeCoverageKind.notFound);
        return BarcodeNotFound(code);
      case BarcodeApiUnavailable():
        return BarcodeWaiting(code);
    }
  }
}
