import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/food/food_state.dart';
import 'package:fb_domain/src/food/gtin.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/nutrition/sanity.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// A09 §3.0: shared wire bounds. Sanity is a separate app-side rule.
abstract final class PersonalFoodBounds {
  /// Maximum trimmed name/alias length.
  static const name = 80;

  /// Maximum trimmed brand length.
  static const brand = 60;

  /// Maximum aliases.
  static const aliases = 30;

  /// Maximum GTINs.
  static const barcodes = 10;

  /// Maximum serving definitions.
  static const servings = 10;

  /// Maximum kcal per 100.
  static const double kcal = 920;

  /// Maximum gram nutrient per 100.
  static const double grams = 1000;

  /// Maximum milligram nutrient per 100.
  static const double milligrams = 100000;

  /// Smallest serving on its own basis.
  static const double minServing = 0.1;

  /// Largest serving on its own basis.
  static const double maxServing = 5000;

  /// Maximum creation code length.
  static const createdFrom = 32;

  /// Wire string cap, including JSON encoding overhead.
  static const jsonLength = 16384;

  /// Shared bounds plus 05 §5.5's exact .NET-decimal wire representation.
  /// Rejects unrepresentable tiny values instead of silently rounding them.
  static bool acceptsNutrient(double value, double maximum) {
    if (!value.isFinite || value < 0 || value > maximum) return false;
    if (value == 0) return true;
    final parts = value.toString().toLowerCase().split('e');
    final exponent = parts.length == 1 ? 0 : int.parse(parts[1]);
    final point = parts[0].indexOf('.');
    final fractional = point < 0 ? 0 : parts[0].length - point - 1;
    final digits = parts[0].replaceAll('.', '').replaceFirst(RegExp('^0+'), '');
    final significant = digits.replaceFirst(RegExp(r'0+$'), '');
    final scale = fractional - exponent - (digits.length - significant.length);
    if (scale > 28) return false;
    final coefficient =
        BigInt.parse(significant) *
        (scale < 0 ? BigInt.from(10).pow(-scale) : BigInt.one);
    return coefficient < (BigInt.one << 96);
  }

  /// Closed, ARB-rendered serving vocabulary (A09 D2).
  static const units = {
    'piece',
    'loaf',
    'plate',
    'glass',
    'sandwich',
    'disc',
    'serving',
    'can',
    'cup',
    'tbsp',
    'tsp',
  };
}

/// A food-specific serving; kept distinct from the entry serving (PA7).
final class PersonalFoodServing {
  /// The unit code and its size on the food's basis.
  new(this.unit, this.amount) {
    if (!PersonalFoodBounds.units.contains(unit) ||
        !amount.isFinite ||
        amount < PersonalFoodBounds.minServing ||
        amount > PersonalFoodBounds.maxServing) {
      throw ArgumentError('invalid serving');
    }
  }

  /// Closed unit code.
  final String unit;

  /// Grams or ml.
  final double amount;
  @override
  bool operator ==(Object other) =>
      other is PersonalFoodServing &&
      other.unit == unit &&
      other.amount == amount;
  @override
  int get hashCode => Object.hash(unit, amount);
  @override
  String toString() => 'PersonalFoodServing';
}

/// Typed draft validation; contains no private values.
enum InvalidDraft {
  /// Invalid name or brand.
  name,

  /// Invalid aliases.
  aliases,

  /// Invalid GTINs.
  barcodes,

  /// Invalid serving definitions.
  servings,

  /// Outside shared numeric bounds.
  bounds,

  /// Impossible mass/macros, as opposed to an advisory kcal mismatch.
  sanity,

  /// Invalid creation code.
  createdFrom,
}

/// A merge yields a definition or the content-free `MergeTooMany` outcome.
abstract interface class PersonalFoodMergeResult;

/// Immutable form data (FD-070). Explicit validation gives forms and handlers
/// typed failures without logging input.
final class PersonalFoodDraft implements PersonalFoodMergeResult {
  /// Names and optional text are trimmed; collections cannot be mutated.
  new({
    required FoodNames names,
    required this.per100,
    this.state = FoodState.asSold,
    this.basis = NutrientBasis.per100g,
    Iterable<String> aliases = const [],
    String? brand,
    Iterable<String> barcodes = const [],
    Iterable<PersonalFoodServing> servings = const [],
    this.entryServing,
    this.createdFrom = 'form',
  }) : names = FoodNames(names.en.trim(), ar: names.ar?.trim()),
       aliases = List.unmodifiable(aliases.map((s) => s.trim())),
       brand = brand?.trim(),
       barcodes = List.unmodifiable(barcodes),
       servings = List.unmodifiable(servings);

  /// Converts exactly once to per-100; the typed serving stays explicit.
  factory fromServing({
    required FoodNames names,
    required Nutrients valuesPerServing,
    required PersonalFoodServing serving,
    NutrientBasis basis = NutrientBasis.per100g,
    FoodState state = FoodState.asSold,
    Iterable<String> aliases = const [],
    String? brand,
    Iterable<String> barcodes = const [],
    Iterable<PersonalFoodServing> servings = const [],
    String createdFrom = 'form',
  }) => PersonalFoodDraft(
    names: names,
    per100: _scale(valuesPerServing, 100 / serving.amount),
    basis: basis,
    state: state,
    aliases: aliases,
    brand: brand,
    barcodes: barcodes,
    servings: servings,
    entryServing: serving,
    createdFrom: createdFrom,
  );

  /// Display names (private).
  final FoodNames names;

  /// Alternate names (private).
  final List<String> aliases;

  /// Optional brand (private).
  final String? brand;

  /// GTIN strings, preserving leading zeroes.
  final List<String> barcodes;

  /// Definition state.
  final FoodState state;

  /// Definition basis.
  final NutrientBasis basis;

  /// Stored per-100 values.
  final Nutrients per100;

  /// Food-specific units.
  final List<PersonalFoodServing> servings;

  /// Serving for which values were originally typed; null means per-100.
  final PersonalFoodServing? entryServing;

  /// Creation method; open vocabulary for later form paths.
  final String createdFrom;

  /// Recomputed advisory/hard sanity verdict.
  SanityResult get sanity => const SanityCheck().check(per100, basis);

  /// Original entry values, without display rounding.
  Nutrients perServing() => _scale(per100, (entryServing?.amount ?? 100) / 100);

  /// Validates wire bounds without applying app-only sanity to stored data.
  InvalidDraft? validateWire() {
    bool text(String s, int max) =>
        s.isNotEmpty && s.length <= max && !s.contains('\u0000');
    if (!text(names.en, PersonalFoodBounds.name) ||
        (names.ar != null && !text(names.ar!, PersonalFoodBounds.name)) ||
        (brand != null && !text(brand!, PersonalFoodBounds.brand))) {
      return InvalidDraft.name;
    }
    if (aliases.length > PersonalFoodBounds.aliases ||
        aliases.toSet().length != aliases.length ||
        aliases.any((s) => !text(s, PersonalFoodBounds.name))) {
      return InvalidDraft.aliases;
    }
    if (barcodes.length > PersonalFoodBounds.barcodes ||
        barcodes.toSet().length != barcodes.length ||
        barcodes.any((s) => !Gtin.isValid(s))) {
      return InvalidDraft.barcodes;
    }
    if (servings.length > PersonalFoodBounds.servings ||
        servings.map((s) => s.unit).toSet().length != servings.length) {
      return InvalidDraft.servings;
    }
    bool bounded(double value, double max) =>
        PersonalFoodBounds.acceptsNutrient(value, max);
    if (!bounded(per100.kcal, PersonalFoodBounds.kcal) ||
        [
          per100.protein,
          per100.carbs,
          per100.fat,
          per100.fiber,
        ].any((v) => !bounded(v, PersonalFoodBounds.grams)) ||
        per100.extras.entries.any(
          (e) => !bounded(
            e.value,
            e.key.unit == NutrientUnit.milligram
                ? PersonalFoodBounds.milligrams
                : PersonalFoodBounds.grams,
          ),
        )) {
      return InvalidDraft.bounds;
    }
    if (createdFrom.isEmpty ||
        createdFrom.length > PersonalFoodBounds.createdFrom ||
        !RegExp(r'^[a-zA-Z]+$').hasMatch(createdFrom)) {
      return InvalidDraft.createdFrom;
    }
    return null;
  }

  /// New user input additionally enforces the app-side hard sanity reasons.
  InvalidDraft? validate() {
    final wireFailure = validateWire();
    if (wireFailure != null) return wireFailure;
    if (sanity.reason == SanityReason.invalidValue ||
        sanity.reason == SanityReason.kcalTooHigh ||
        sanity.reason == SanityReason.macrosTooHeavy) {
      return InvalidDraft.sanity;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is PersonalFoodDraft &&
      names == other.names &&
      brand == other.brand &&
      state == other.state &&
      basis == other.basis &&
      per100 == other.per100 &&
      entryServing == other.entryServing &&
      createdFrom == other.createdFrom &&
      _same(aliases, other.aliases) &&
      _same(barcodes, other.barcodes) &&
      _same(servings, other.servings);
  @override
  int get hashCode => Object.hash(
    names,
    brand,
    state,
    basis,
    per100,
    entryServing,
    createdFrom,
    Object.hashAll(aliases),
    Object.hashAll(barcodes),
    Object.hashAll(servings),
  );
  @override
  String toString() => 'PersonalFoodDraft';
}

/// A live personal food and its optimistic version.
final class PersonalFood {
  /// Identity and immutable definition.
  new({required this.id, required this.version, required this.draft}) {
    checkUuid(id, 'id');
    checkRowVersion(version);
  }

  /// Row identity.
  final String id;

  /// Observed version.
  final int version;

  /// Definition.
  final PersonalFoodDraft draft;

  /// Definition names.
  FoodNames get names => draft.names;

  /// Definition aliases.
  List<String> get aliases => draft.aliases;

  /// Definition brand.
  String? get brand => draft.brand;

  /// Definition barcodes.
  List<String> get barcodes => draft.barcodes;

  /// Definition state.
  FoodState get state => draft.state;

  /// Definition basis.
  NutrientBasis get basis => draft.basis;

  /// Definition per100.
  Nutrients get per100 => draft.per100;

  /// Definition servings.
  List<PersonalFoodServing> get servings => draft.servings;

  /// Definition entryServing.
  PersonalFoodServing? get entryServing => draft.entryServing;

  /// Definition createdFrom.
  String get createdFrom => draft.createdFrom;

  /// Food-specific portion resolution.
  FoodMeasures get measures => FoodMeasures(
    basis: draft.basis,
    servingUnits: [
      for (final s in draft.servings)
        if (draft.basis == NutrientBasis.per100g)
          ServingUnit.grams(s.unit, s.amount)
        else
          ServingUnit.milliliters(s.unit, s.amount),
    ],
  );

  /// Computed sanity, never persisted.
  SanityResult get sanity => draft.sanity;
  @override
  String toString() => 'PersonalFood';
  @override
  bool operator ==(Object other) =>
      other is PersonalFood &&
      other.id == id &&
      other.version == version &&
      other.draft == draft;
  @override
  int get hashCode => Object.hash(id, version, draft);
}

bool _same<T>(List<T> a, List<T> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

Nutrients _scale(Nutrients values, double factor) {
  try {
    return values.scale(factor);
  }
  // Overflow must not include nutrient values in ArgumentError.toString.
  // ignore: avoid_catching_errors
  on ArgumentError {
    throw ArgumentError('invalid nutrient conversion');
  }
}
