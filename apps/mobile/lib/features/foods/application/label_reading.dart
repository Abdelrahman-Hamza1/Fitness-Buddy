import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/application/personal_food_form.dart';

/// One more nutrient a label lists (vitamins, minerals…), as printed; shown
/// on the review form, not stored (a personal food has no field for it).
/// User content: never logged.
final class LabelOther {
  /// The nutrient.
  const new(this.name, this.value, this.unit);

  /// Its printed name.
  final String name;

  /// Its value.
  final double value;

  /// Its unit as printed.
  final String unit;

  @override
  String toString() => 'LabelOther';
}

/// A nutrition label as read by `POST /v1/buddy/label` (FD-040–042, A69
/// D8), on the label's own basis: the review form's input. User content:
/// never logged.
final class LabelReading {
  /// The reading.
  const new({
    required this.basis,
    this.perServing = false,
    this.servingSize,
    this.name,
    this.values = const {},
    this.uncertain = const {},
    this.others = const [],
  });

  /// g or ml.
  final NutrientBasis basis;

  /// The numbers are for one serving of [servingSize] (else per 100).
  final bool perServing;

  /// The serving in g or ml, when printed.
  final double? servingSize;

  /// The product name guess.
  final String? name;

  /// The values by form field (kcal, g; mg for sodium and cholesterol).
  final Map<PersonalFoodField, double> values;

  /// The fields to check: unsure, missing or converted (kJ, salt).
  final Set<PersonalFoodField> uncertain;

  /// Other nutrients listed.
  final List<LabelOther> others;

  @override
  String toString() => 'LabelReading';
}

/// How a label read ended.
sealed class LabelOutcome {
  const new _();
}

/// Read: review [reading].
final class LabelRead extends LabelOutcome {
  /// Read.
  const new(this.reading) : super._();

  /// What the label says.
  final LabelReading reading;
}

/// Why a label couldn't be read. Codes only.
enum LabelFailure {
  /// No nutrition panel was found in the photo.
  notFound,

  /// Today's Buddy allowance is used up (429).
  limited,

  /// No connection.
  offline,

  /// Buddy can't read labels right now (503, a timeout, a server error).
  unavailable,
}

/// Not read, because of [failure].
final class LabelNotRead extends LabelOutcome {
  /// Not read.
  const new(this.failure) : super._();

  /// Why.
  final LabelFailure failure;
}
