import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/application/barcode_lookup.dart'
    show ScanPrefill;
import 'package:fb_mobile/features/foods/application/barcode_providers.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/foods/application/new_food_prefill.dart';
import 'package:fb_mobile/features/foods/application/personal_food_actions.dart';
import 'package:fb_text/fb_text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'personal_food_form.g.dart';

/// Typed field identities; no labels or user content in errors.
enum PersonalFoodField {
  /// The name field.
  name,

  /// The name ar field.
  nameAr,

  /// The aliases field.
  aliases,

  /// The brand field.
  brand,

  /// The barcodes field.
  barcodes,

  /// The kcal field.
  kcal,

  /// The protein field.
  protein,

  /// The carbs field.
  carbs,

  /// The fat field.
  fat,

  /// The fiber field.
  fiber,

  /// The sugar field.
  sugar,

  /// The saturated fat field.
  saturatedFat,

  /// The trans fat field.
  transFat,

  /// The sodium field.
  sodium,

  /// The cholesterol field.
  cholesterol,

  /// The alcohol field.
  alcohol,

  /// The serving size field.
  servingSize,

  /// Editable food-specific serving rows.
  servings,

  /// The nutrients field.
  nutrients,
}

/// Field failures rendered by the presentation layer.
enum PersonalFoodFieldError {
  /// A required input is missing.
  required,

  /// The numeric buffer is not a finite nonnegative decimal.
  invalidNumber,

  /// The value exceeds shared wire bounds.
  bounds,

  /// A nonzero value too small to store (it would round to nothing).
  tooSmall,

  /// The text violates its length or content bounds.
  invalidText,

  /// A GTIN is malformed or has an invalid check digit.
  invalidBarcode,

  /// A serving has an invalid unit, size or duplicate code.
  invalidServing,

  /// The nutrition values violate the hard sanity rules.
  impossible,
}

/// Input interpretation, independent of nutrient basis.
enum PersonalFoodMode {
  /// Values entered per 100 g or ml.
  per100,

  /// Values entered for the selected serving.
  perServing,
}

/// Optimistic edit status.
enum PersonalFoodStaleness {
  /// The observed definition is current.
  current,

  /// The observed row version changed.
  changed,

  /// The source row is no longer live.
  removed,
}

/// One editable serving row, including incomplete numeric input.
final class PersonalFoodServingInput {
  /// Creates this structured value.
  const new(this.unit, this.amount);

  /// Closed serving unit code.
  final String unit;

  /// Typed size on the selected basis.
  final String amount;
}

/// The identity of one open form (A09a fix 1). Equality is identity, so two
/// "New food" forms (one per tab of the indexed stack) never share typed
/// input; each screen makes one key and keeps it for its lifetime.
final class PersonalFoodFormKey {
  /// A form for the food [id], or for a new food when null. [fromScan]: a
  /// new food opened from the barcode scanner, prefilled from the scan
  /// (A28a D9).
  new([this.id]) : fromScan = false;

  /// A new-food form opened from the barcode scanner.
  new scan() : id = null, fromScan = true;

  /// The food being edited; null for a new one.
  final String? id;

  /// Opened by "Add it yourself" / "Add the missing values".
  final bool fromScan;

  @override
  String toString() => 'PersonalFoodFormKey';
}

/// The fields holding a nutrient value (their meaning depends on the mode,
/// the basis and the serving they were typed for).
const Set<PersonalFoodField> nutrientFields = {
  PersonalFoodField.kcal,
  PersonalFoodField.protein,
  PersonalFoodField.carbs,
  PersonalFoodField.fat,
  PersonalFoodField.fiber,
  PersonalFoodField.sugar,
  PersonalFoodField.saturatedFat,
  PersonalFoodField.transFat,
  PersonalFoodField.sodium,
  PersonalFoodField.cholesterol,
  PersonalFoodField.alcohol,
};

const Map<PersonalFoodField, NutrientKey> _extras = {
  PersonalFoodField.sugar: NutrientKey.sugar,
  PersonalFoodField.saturatedFat: NutrientKey.saturatedFat,
  PersonalFoodField.transFat: NutrientKey.transFat,
  PersonalFoodField.sodium: NutrientKey.sodium,
  PersonalFoodField.cholesterol: NutrientKey.cholesterol,
  PersonalFoodField.alcohol: NutrientKey.alcohol,
};

/// Form parsing accepts decimal commas, Arabic digits and Arabic decimal marks.
/// Grouping and mixed separators are deliberately refused rather than guessed.
double? parsePersonalFoodNumber(String text) {
  var value = text.trim();
  for (var i = 0; i < 10; i++) {
    value = value
        .replaceAll(String.fromCharCode(0x660 + i), '$i')
        .replaceAll(String.fromCharCode(0x6f0 + i), '$i');
  }
  value = value.replaceAll(',', '.').replaceAll('٫', '.');
  if (!RegExp(r'^\+?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$').hasMatch(value)) {
    return null;
  }
  final number = double.tryParse(value);
  if (number == null || !number.isFinite || number < 0) {
    return null;
  }
  // A nonzero decimal must not silently underflow to a persisted zero.
  if (number == 0 && RegExp('[1-9]').hasMatch(value)) {
    return null;
  }
  return number;
}

/// Immutable typed input plus the row version the user is editing.
final class PersonalFoodFormState {
  /// Creates this structured value.
  new({
    this.original,
    this.latest,
    Map<PersonalFoodField, String> fields = const {},
    Set<PersonalFoodField> touched = const {},
    this.mode = PersonalFoodMode.per100,
    this.basis = NutrientBasis.per100g,
    this.foodState = FoodState.asSold,
    this.servingUnit = 'serving',
    List<PersonalFoodServingInput> servings = const [],
    this.configurationTouched = false,
    this.typedServing,
    this.staleness = PersonalFoodStaleness.current,
    this.duplicate,
    this.submitting = false,
    this.newCreatedFrom = 'form',
  }) : fields = Map.unmodifiable(fields),
       touched = Set.unmodifiable(touched),
       servings = List.unmodifiable(servings);

  /// Definition and version on which this edit is based.
  final PersonalFood? original;

  /// Most recent live definition offered for Reload.
  final PersonalFood? latest;

  /// Typed buffers, including incomplete input.
  final Map<PersonalFoodField, String> fields;

  /// Fields explicitly edited in this form.
  final Set<PersonalFoodField> touched;

  /// Interpretation of the typed nutrient values.
  final PersonalFoodMode mode;

  /// Canonical nutrient basis.
  final NutrientBasis basis;

  /// Selected preparation state.
  final FoodState foodState;

  /// Closed unit code for per-serving entry.
  final String servingUnit;

  /// Editable food-specific serving rows.
  final List<PersonalFoodServingInput> servings;

  /// Whether the user changed the interpretation of values.
  final bool configurationTouched;

  /// The serving the typed numbers were entered for, when a Reload kept it
  /// over the stored food's own entry serving (A09a fix 2). Null means the
  /// stored entry serving (or the typed size, once reinterpreted).
  final PersonalFoodServing? typedServing;

  /// Whether Save must wait for Reload or source recovery.
  final PersonalFoodStaleness staleness;

  /// Matching live row; presentation may display its name without logging it.
  final PersonalFood? duplicate;

  /// Whether a save is in flight.
  final bool submitting;

  /// The creation code of a new food: `form`, or the OFF origin of a scan
  /// prefill (review fix 2). An edited food keeps its own.
  final String newCreatedFrom;

  /// Reads a field without inventing a default number.
  String text(PersonalFoodField field) => fields[field] ?? '';

  /// Whether any typed or configuration input was edited.
  bool get dirty => touched.isNotEmpty || configurationTouched;

  /// Whether the form is valid, current and idle.
  bool get canSave =>
      !submitting &&
      staleness == PersonalFoodStaleness.current &&
      validation.errors.isEmpty;

  /// Typed field failures and the exact save draft.
  PersonalFoodFormValidation get validation => _validate(this);

  /// Computed advisory or hard nutrition verdict.
  SanityResult? get sanity => validation.sanity;

  /// Whether the nonblocking kcal mismatch banner is needed.
  bool get showSanityWarning => sanity?.reason == SanityReason.kcalMismatch;

  /// Whether anything beyond the name and the numbers is filled in: the
  /// Arabic name, other names, brand, barcodes, servings or a state other
  /// than "as sold". The form opens its "More details" when it is.
  bool get hasDetails =>
      [
        PersonalFoodField.nameAr,
        PersonalFoodField.aliases,
        PersonalFoodField.brand,
        PersonalFoodField.barcodes,
      ].any((f) => text(f).trim().isNotEmpty) ||
      servings.isNotEmpty ||
      foodState != FoodState.asSold;

  /// Returns a new immutable form state.
  PersonalFoodFormState copyWith({
    PersonalFood? original,
    PersonalFood? latest,
    Map<PersonalFoodField, String>? fields,
    Set<PersonalFoodField>? touched,
    PersonalFoodMode? mode,
    NutrientBasis? basis,
    FoodState? foodState,
    String? servingUnit,
    List<PersonalFoodServingInput>? servings,
    bool? configurationTouched,
    PersonalFoodServing? typedServing,
    bool clearTypedServing = false,
    PersonalFoodStaleness? staleness,
    PersonalFood? duplicate,
    bool clearDuplicate = false,
    bool? submitting,
  }) => PersonalFoodFormState(
    newCreatedFrom: newCreatedFrom,
    original: original ?? this.original,
    latest: latest ?? this.latest,
    fields: fields ?? this.fields,
    touched: touched ?? this.touched,
    mode: mode ?? this.mode,
    basis: basis ?? this.basis,
    foodState: foodState ?? this.foodState,
    servingUnit: servingUnit ?? this.servingUnit,
    servings: servings ?? this.servings,
    configurationTouched: configurationTouched ?? this.configurationTouched,
    typedServing: clearTypedServing ? null : typedServing ?? this.typedServing,
    staleness: staleness ?? this.staleness,
    duplicate: clearDuplicate ? null : duplicate ?? this.duplicate,
    submitting: submitting ?? this.submitting,
  );
}

/// A validated draft, or typed field failures; never throws input in an error.
final class PersonalFoodFormValidation {
  /// Creates this structured value.
  new(
    this.draft,
    Map<PersonalFoodField, PersonalFoodFieldError> errors,
    this.sanity, {
    Set<int> badServings = const {},
  }) : errors = Map.unmodifiable(errors),
       badServings = Set.unmodifiable(badServings);

  /// Exact validated values to send through the single writer.
  final PersonalFoodDraft? draft;

  /// Content-free failures keyed by form field.
  final Map<PersonalFoodField, PersonalFoodFieldError> errors;

  /// Computed advisory or hard nutrition verdict.
  final SanityResult? sanity;

  /// Indexes of the serving rows that are invalid (bad size or a unit used
  /// twice), so each can be marked. Empty when only the count is too high.
  final Set<int> badServings;
}

PersonalFoodFormValidation _validate(PersonalFoodFormState s) {
  final errors = <PersonalFoodField, PersonalFoodFieldError>{};
  String? optional(PersonalFoodField field, int max, {bool required = false}) {
    final text = s.text(field).trim();
    if (text.isEmpty) {
      if (required) errors[field] = PersonalFoodFieldError.required;
      return null;
    }
    if (text.length > max || text.contains('\u0000')) {
      errors[field] = PersonalFoodFieldError.invalidText;
    }
    return text;
  }

  final name = optional(
    PersonalFoodField.name,
    PersonalFoodBounds.name,
    required: true,
  );
  final ar = optional(PersonalFoodField.nameAr, PersonalFoodBounds.name);
  final brand = optional(PersonalFoodField.brand, PersonalFoodBounds.brand);
  List<String> list(PersonalFoodField field) => s
      .text(field)
      .split(RegExp('[,،]'))
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList();
  final aliases = <String>[];
  final aliasKeys = <String>{};
  for (final alias in list(PersonalFoodField.aliases)) {
    if (aliasKeys.add(normalizeKey(alias))) aliases.add(alias);
  }
  if (aliases.length > PersonalFoodBounds.aliases ||
      aliases.any(
        (a) => a.length > PersonalFoodBounds.name || a.contains('\u0000'),
      )) {
    errors[PersonalFoodField.aliases] = PersonalFoodFieldError.invalidText;
  }
  final barcodes = list(PersonalFoodField.barcodes).toSet().toList();
  if (barcodes.length > PersonalFoodBounds.barcodes ||
      barcodes.any((b) => !Gtin.isValid(b))) {
    errors[PersonalFoodField.barcodes] = PersonalFoodFieldError.invalidBarcode;
  }

  final old = s.original?.draft;
  // A mode/size change reinterprets the typed numbers. Other edits never
  // round-trip untouched nutrients through display text (A09 PA7).
  final reinterpret =
      s.configurationTouched ||
      s.touched.contains(PersonalFoodField.servingSize);
  var factor = 1.0;
  PersonalFoodServing? entryServing;
  if (s.mode == PersonalFoodMode.perServing) {
    final size = parsePersonalFoodNumber(s.text(PersonalFoodField.servingSize));
    if (size == null ||
        size < PersonalFoodBounds.minServing ||
        size > PersonalFoodBounds.maxServing ||
        !PersonalFoodBounds.units.contains(s.servingUnit)) {
      errors[PersonalFoodField.servingSize] =
          PersonalFoodFieldError.invalidServing;
    } else {
      // Untouched configuration: the serving the numbers were typed for
      // (kept by Reload, or the stored one), never re-parsed (PA7).
      final kept = reinterpret ? null : s.typedServing ?? old?.entryServing;
      entryServing = kept ?? PersonalFoodServing(s.servingUnit, size);
      factor = 100 / entryServing.amount;
    }
  }
  double nutrient(
    PersonalFoodField field,
    double? stored, {
    bool required = false,
    double maximum = PersonalFoodBounds.grams,
  }) {
    if (old != null &&
        !reinterpret &&
        !s.touched.contains(field) &&
        stored != null) {
      return stored;
    }
    final text = s.text(field).trim();
    if (text.isEmpty && !required) return 0;
    final number = parsePersonalFoodNumber(text);
    if (number == null) {
      errors[field] = text.isEmpty
          ? PersonalFoodFieldError.required
          : PersonalFoodFieldError.invalidNumber;
      return 0;
    }
    final scaled = number * factor;
    if (scaled > maximum) {
      errors[field] = PersonalFoodFieldError.bounds;
      return 0;
    }
    if ((number != 0 && scaled == 0) ||
        !PersonalFoodBounds.acceptsNutrient(scaled, maximum)) {
      // Within range but not storable: a nonzero value that rounds away.
      errors[field] = PersonalFoodFieldError.tooSmall;
      return 0;
    }
    return scaled;
  }

  final values = Nutrients(
    kcal: nutrient(
      PersonalFoodField.kcal,
      old?.per100.kcal,
      required: true,
      maximum: PersonalFoodBounds.kcal,
    ),
    protein: nutrient(
      PersonalFoodField.protein,
      old?.per100.protein,
      required: true,
    ),
    carbs: nutrient(PersonalFoodField.carbs, old?.per100.carbs, required: true),
    fat: nutrient(PersonalFoodField.fat, old?.per100.fat, required: true),
    fiber: nutrient(PersonalFoodField.fiber, old?.per100.fiber),
    extras: {
      for (final e in _extras.entries)
        if (s.text(e.key).trim().isNotEmpty ||
            (old?.per100.extras.containsKey(e.value) == true &&
                !reinterpret &&
                !s.touched.contains(e.key)))
          e.value: nutrient(
            e.key,
            old?.per100.extra(e.value),
            maximum: e.value.unit == NutrientUnit.milligram
                ? PersonalFoodBounds.milligrams
                : PersonalFoodBounds.grams,
          ),
    },
  );
  final servings = <PersonalFoodServing>[];
  final units = <String>{};
  final badServings = <int>{};
  for (final (index, row) in s.servings.indexed) {
    final amount = parsePersonalFoodNumber(row.amount);
    if (amount == null ||
        amount < PersonalFoodBounds.minServing ||
        amount > PersonalFoodBounds.maxServing ||
        !PersonalFoodBounds.units.contains(row.unit) ||
        !units.add(row.unit)) {
      errors[PersonalFoodField.servings] =
          PersonalFoodFieldError.invalidServing;
      badServings.add(index);
    } else {
      servings.add(PersonalFoodServing(row.unit, amount));
    }
  }
  if (servings.length > PersonalFoodBounds.servings) {
    errors[PersonalFoodField.servings] = PersonalFoodFieldError.invalidServing;
  }
  final sanity = const SanityCheck().check(values, s.basis);
  final newValues =
      old == null ||
      reinterpret ||
      [
        ..._extras.keys,
        PersonalFoodField.kcal,
        PersonalFoodField.protein,
        PersonalFoodField.carbs,
        PersonalFoodField.fat,
        PersonalFoodField.fiber,
      ].any(s.touched.contains);
  if (newValues &&
      (sanity.reason == SanityReason.macrosTooHeavy ||
          sanity.reason == SanityReason.kcalTooHigh ||
          sanity.reason == SanityReason.invalidValue)) {
    errors[PersonalFoodField.nutrients] = PersonalFoodFieldError.impossible;
  }
  if (errors.isNotEmpty) {
    return PersonalFoodFormValidation(
      null,
      errors,
      sanity,
      badServings: badServings,
    );
  }
  final draft = PersonalFoodDraft(
    names: FoodNames(name!, ar: ar),
    per100: values,
    basis: s.basis,
    state: s.foodState,
    aliases: old != null && !s.touched.contains(PersonalFoodField.aliases)
        ? old.aliases
        : aliases,
    brand: brand,
    barcodes: old != null && !s.touched.contains(PersonalFoodField.barcodes)
        ? old.barcodes
        : barcodes,
    servings: old != null && !s.touched.contains(PersonalFoodField.servings)
        ? old.servings
        : servings,
    entryServing: entryServing,
    createdFrom: _createdFrom(s, old, reinterpret: reinterpret),
  );
  if ((newValues ? draft.validate() : draft.validateWire()) != null) {
    errors[PersonalFoodField.nutrients] = PersonalFoodFieldError.bounds;
  }
  return PersonalFoodFormValidation(
    errors.isEmpty ? draft : null,
    errors,
    sanity,
  );
}

String _display(double? n) =>
    n == null ? '' : n.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');

/// The nutrient buffers of [values], as typed for [values]' own basis.
Map<PersonalFoodField, String> _nutrientTexts(Nutrients? values) => {
  for (final pair in [
    (PersonalFoodField.kcal, values?.kcal),
    (PersonalFoodField.protein, values?.protein),
    (PersonalFoodField.carbs, values?.carbs),
    (PersonalFoodField.fat, values?.fat),
    (PersonalFoodField.fiber, values?.fiber),
    for (final e in _extras.entries) (e.key, values?.extra(e.value)),
  ])
    pair.$1: _display(pair.$2),
};

PersonalFoodFormState _initial(PersonalFood? food, {String? name}) {
  final draft = food?.draft;
  return PersonalFoodFormState(
    original: food,
    latest: food,
    mode: food?.entryServing == null
        ? PersonalFoodMode.per100
        : PersonalFoodMode.perServing,
    basis: food?.basis ?? NutrientBasis.per100g,
    foodState: food?.state ?? FoodState.asSold,
    servingUnit: food?.entryServing?.unit ?? 'serving',
    servings: [
      for (final row in food?.servings ?? <PersonalFoodServing>[])
        PersonalFoodServingInput(row.unit, row.amount.toString()),
    ],
    fields: {
      PersonalFoodField.name: food?.names.en ?? name ?? '',
      PersonalFoodField.nameAr: food?.names.ar ?? '',
      PersonalFoodField.brand: food?.brand ?? '',
      PersonalFoodField.aliases: food?.aliases.join(', ') ?? '',
      PersonalFoodField.barcodes: food?.barcodes.join(', ') ?? '',
      PersonalFoodField.servingSize:
          food?.entryServing?.amount.toString() ?? '',
      ..._nutrientTexts(draft?.perServing()),
    },
  );
}

/// A new food prefilled from a scan (A28a D9): the barcode, and the name,
/// brand, per-100 values and serving Open Food Facts has; the rest is typed.
/// "More details" opens because a barcode is set.
PersonalFoodFormState _initialFromScan(ScanPrefill p) => PersonalFoodFormState(
  // Review fix 2: a prefill from OFF keeps the origin and the scan's halal
  // flags; the fiber mark is decided from the field at save.
  newCreatedFrom: switch (p.halal) {
    final halal? => OffOrigin(halal: halal).encode(),
    null => 'form',
  },
  basis: p.perMl ? NutrientBasis.per100ml : NutrientBasis.per100g,
  servings: [
    if (p.servingQuantity case final q?
        when q >= PersonalFoodBounds.minServing &&
            q <= PersonalFoodBounds.maxServing)
      PersonalFoodServingInput('serving', _display(q)),
  ],
  fields: {
    PersonalFoodField.name: p.name ?? '',
    PersonalFoodField.nameAr: p.nameAr ?? '',
    PersonalFoodField.brand: p.brand ?? '',
    PersonalFoodField.aliases: '',
    PersonalFoodField.barcodes: p.code,
    PersonalFoodField.servingSize: '',
    PersonalFoodField.kcal: _display(p.kcal),
    PersonalFoodField.protein: _display(p.protein),
    PersonalFoodField.carbs: _display(p.carbs),
    PersonalFoodField.fat: _display(p.fat),
    PersonalFoodField.fiber: _display(p.fiber),
    for (final extra in _extras.keys) extra: '',
  },
);

/// How a form's typed numbers are meant: per 100 or per one serving of a
/// size, on a basis. The serving is null per 100, or when the typed size
/// can't be read.
typedef _Reading = ({
  PersonalFoodMode mode,
  NutrientBasis basis,
  PersonalFoodServing? serving,
});

_Reading _readingOf(PersonalFoodFormState s) {
  PersonalFoodServing? serving;
  if (s.mode == PersonalFoodMode.perServing) {
    final reinterpret =
        s.configurationTouched ||
        s.touched.contains(PersonalFoodField.servingSize);
    serving = reinterpret ? null : s.typedServing ?? s.original?.entryServing;
    if (serving == null) {
      final size = parsePersonalFoodNumber(
        s.text(PersonalFoodField.servingSize),
      );
      if (size != null &&
          size >= PersonalFoodBounds.minServing &&
          size <= PersonalFoodBounds.maxServing &&
          PersonalFoodBounds.units.contains(s.servingUnit)) {
        serving = PersonalFoodServing(s.servingUnit, size);
      }
    }
  }
  return (mode: s.mode, basis: s.basis, serving: serving);
}

/// The saved creation code. A food from an OFF scan keeps its origin; its
/// "fiber stored as 0" mark follows the fiber field once that is typed
/// (empty means 0 again).
String _createdFrom(
  PersonalFoodFormState s,
  PersonalFoodDraft? old, {
  required bool reinterpret,
}) {
  final base = old?.createdFrom ?? s.newCreatedFrom;
  final off = OffOrigin.decode(base);
  final fiberTyped =
      old == null || reinterpret || s.touched.contains(PersonalFoodField.fiber);
  if (off == null || !fiberTyped) return base;
  return off
      .withFiberAssumed(assumed: s.text(PersonalFoodField.fiber).trim().isEmpty)
      .encode();
}

/// Disposable per-form state; only submit calls the application commands.
/// Each open form passes its own [PersonalFoodFormKey].
@riverpod
class PersonalFoodFormController extends _$PersonalFoodFormController {
  @override
  Future<PersonalFoodFormState> build(PersonalFoodFormKey key) async {
    final id = key.id;
    ref.listen(personalFoodsProvider, (_, next) {
      if (state.value case final current?) {
        state = AsyncData(_duplicate(current, next.value ?? []));
      }
    });
    if (id == null) {
      // Consume the handoff after provider initialization; Riverpod forbids
      // updating another notifier during the synchronous build phase.
      await Future<void>.value();
      final scan = key.fromScan
          ? ref.read(scanFoodPrefillProvider.notifier).take()
          : null;
      return _duplicate(
        scan != null
            ? _initialFromScan(scan)
            : _initial(
                null,
                name: ref.read(newFoodPrefillProvider.notifier).take(),
              ),
        ref.read(personalFoodsProvider).value ?? [],
      );
    }
    ref.listen(personalFoodProvider(id), (_, next) {
      if ((next, state.value) case (
        AsyncData<PersonalFood?>(),
        final current?,
      )) {
        final food = next.value;
        state = AsyncData(
          current.copyWith(
            latest: food,
            staleness: food == null
                ? PersonalFoodStaleness.removed
                : food.version != current.original?.version
                ? PersonalFoodStaleness.changed
                : PersonalFoodStaleness.current,
          ),
        );
      }
    });
    final food = await ref.read(personalFoodProvider(id).future);
    return _duplicate(
      _initial(food).copyWith(
        staleness: food == null
            ? PersonalFoodStaleness.removed
            : PersonalFoodStaleness.current,
      ),
      ref.read(personalFoodsProvider).value ?? [],
    );
  }

  PersonalFoodFormState _duplicate(
    PersonalFoodFormState current,
    List<PersonalFood> foods,
  ) {
    final key = normalizeKey(current.text(PersonalFoodField.name));
    final duplicate = foods
        .where(
          (f) =>
              f.id != current.original?.id && normalizeKey(f.names.en) == key,
        )
        .firstOrNull;
    return current.copyWith(
      duplicate: duplicate,
      clearDuplicate: duplicate == null,
    );
  }

  /// Edits one typed buffer and marks that field touched.
  void setField(PersonalFoodField field, String text) {
    final current = state.requireValue;
    state = AsyncData(
      _duplicate(
        current.copyWith(
          fields: {...current.fields, field: text},
          touched: {...current.touched, field},
        ),
        ref.read(personalFoodsProvider).value ?? [],
      ),
    );
  }

  /// Interpretation changes preserve every typed buffer.
  void setMode(PersonalFoodMode mode, {NutrientBasis? basis, String? unit}) =>
      state = AsyncData(
        state.requireValue.copyWith(
          mode: mode,
          basis: basis,
          servingUnit: unit,
          configurationTouched: true,
        ),
      );

  /// Selects a preparation state without changing numeric buffers.
  void setFoodState(FoodState value) => state = AsyncData(
    state.requireValue.copyWith(
      foodState: value,
      touched: {...state.requireValue.touched, PersonalFoodField.nutrients},
    ),
  );

  /// Replaces editable serving rows, retaining incomplete input.
  void setServings(List<PersonalFoodServingInput> rows) => state = AsyncData(
    state.requireValue.copyWith(
      servings: rows,
      touched: {...state.requireValue.touched, PersonalFoodField.servings},
    ),
  );

  /// Rebase on the new row, keeping typed fields and their interpretation.
  ///
  /// Typed numbers keep the meaning they were typed with (A09a fix 2): when
  /// the stored food now reads its numbers differently (another serving
  /// size, per 100 instead of per serving, or g instead of ml), the form
  /// keeps the reading the user typed in, and shows the latest stored
  /// values in that reading. Untouched values still save exactly as stored.
  void reload() {
    final current = state.requireValue;
    final food = current.latest;
    if (current.staleness == PersonalFoodStaleness.removed || food == null) {
      return;
    }
    final fresh = _initial(food);
    final reinterpret =
        current.configurationTouched ||
        current.touched.contains(PersonalFoodField.servingSize);
    final typed = _readingOf(current);
    final typedNumbers = nutrientFields.any(current.touched.contains);
    final keepReading =
        reinterpret ||
        (typedNumbers &&
            (typed.mode != fresh.mode ||
                typed.basis != food.basis ||
                typed.serving != food.entryServing));
    final kept = <PersonalFoodField, String>{
      for (final f in current.touched) f: current.text(f),
    };
    if (!keepReading) {
      state = AsyncData(
        _duplicate(
          fresh.copyWith(
            fields: {...fresh.fields, ...kept},
            touched: current.touched,
            foodState: current.touched.contains(PersonalFoodField.nutrients)
                ? current.foodState
                : fresh.foodState,
            servings: current.touched.contains(PersonalFoodField.servings)
                ? current.servings
                : fresh.servings,
          ),
          ref.read(personalFoodsProvider).value ?? [],
        ),
      );
      return;
    }
    // The latest stored values, shown in the reading the user typed in. A
    // per-serving reading whose size can't be read keeps what was shown.
    final serving = typed.serving;
    final shown = typed.mode == PersonalFoodMode.per100
        ? _nutrientTexts(food.per100)
        : serving != null
        ? _nutrientTexts(food.per100.scale(serving.amount / 100))
        : {for (final f in nutrientFields) f: current.text(f)};
    state = AsyncData(
      _duplicate(
        fresh.copyWith(
          fields: {
            ...fresh.fields,
            ...shown,
            PersonalFoodField.servingSize: current.text(
              PersonalFoodField.servingSize,
            ),
            ...kept,
          },
          touched: current.touched,
          mode: current.mode,
          basis: current.basis,
          servingUnit: current.servingUnit,
          configurationTouched: current.configurationTouched,
          // Without a reinterpretation the numbers keep the exact serving
          // they were typed for; with one, the typed size decides.
          typedServing: reinterpret ? null : typed.serving,
          clearTypedServing: reinterpret || typed.serving == null,
          foodState: current.touched.contains(PersonalFoodField.nutrients)
              ? current.foodState
              : fresh.foodState,
          servings: current.touched.contains(PersonalFoodField.servings)
              ? current.servings
              : fresh.servings,
        ),
        ref.read(personalFoodsProvider).value ?? [],
      ),
    );
  }

  /// Saves the validated current form, returning typed refusals.
  Future<PersonalFoodOutcome> submit() async {
    final current = state.requireValue;
    // A second activation while the first is in flight: not "unchanged",
    // so the screen never leaves on it.
    if (current.submitting) return const PersonalFoodPending();
    if (current.staleness != PersonalFoodStaleness.current) {
      return PersonalFoodFailed(
        current.staleness == PersonalFoodStaleness.removed
            ? PersonalFoodFailure.removed
            : PersonalFoodFailure.changed,
      );
    }
    final draft = current.validation.draft;
    if (draft == null) {
      return const PersonalFoodFailed(PersonalFoodFailure.invalid);
    }
    state = AsyncData(current.copyWith(submitting: true));
    try {
      final actions = ref.read(personalFoodActionsProvider);
      return current.original == null
          ? await actions.create(draft)
          : await actions.update(current.original!, draft);
    } finally {
      if (ref.mounted) {
        state = AsyncData(state.requireValue.copyWith(submitting: false));
      }
    }
  }
}
