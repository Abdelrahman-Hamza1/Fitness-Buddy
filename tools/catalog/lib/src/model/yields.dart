import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_domain/fb_domain.dart';

/// One row of `data/yields.yaml` (FD-060).
class YieldRow {
  const new({
    required this.file,
    required this.index,
    required this.group,
    required this.from,
    required this.to,
    required this.factor,
    required this.source,
    this.note,
  });

  final String file;

  /// Position in the file's `rows:` list.
  final int index;
  final String group;
  final FoodState from;
  final FoodState to;

  /// Grams in [to] per gram in [from].
  final double factor;
  final String source;
  final String? note;
}

/// One row of `data/portion_words.yaml` (FD-003, LC-051): what one [unit]
/// of [food] weighs ([g]) or holds ([ml]) - exactly one of the two is set.
class PortionWordRow {
  const new({
    required this.file,
    required this.index,
    required this.food,
    required this.unit,
    required this.source,
    this.g,
    this.ml,
    this.range,
    this.note,
  });

  final String file;
  final int index;

  /// Catalog ID: `usda:<slug>`, `ref:<dish>` or `ref:<dish>/<variant>`.
  final String food;

  /// A unit code known to `fb_domain` (plus `can`, see the validator).
  final String unit;
  final double? g;
  final double? ml;
  final Range? range;
  final String source;
  final String? note;

  /// The amount, in whichever of g / ml the row states.
  double get amount => (g ?? ml)!;
}
