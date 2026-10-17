/// One FDC nutrient the importer reads: its `nutrient.id` and the unit
/// `nutrient.csv` must declare for it.
class FdcNutrient {
  const new(this.id, this.unit);

  final int id;
  final String unit;
}

/// The core five plus extras, per 100 g (A03 D3). Each field lists FDC
/// nutrient ids in priority order: the first one present wins.
class NutrientField {
  const new(this.key, this.sources, {this.core = false});

  /// Key in the extract (`kcal`, `protein_g`, ...).
  final String key;

  /// Candidate nutrients, best first.
  final List<FdcNutrient> sources;

  /// The core five are required (FD-002); extras are left out when absent.
  final bool core;
}

const _kcal = 'KCAL';
const _g = 'G';
const _mg = 'MG';

/// A03 D3. Energy: 1008, else Atwater specific (2048), else Atwater general
/// (2047). Carbs: by difference (1005), else by summation (1050).
const nutrientFields = <NutrientField>[
  NutrientField('kcal', [
    FdcNutrient(1008, _kcal),
    FdcNutrient(2048, _kcal),
    FdcNutrient(2047, _kcal),
  ], core: true),
  NutrientField('protein_g', [FdcNutrient(1003, _g)], core: true),
  NutrientField('fat_g', [FdcNutrient(1004, _g)], core: true),
  NutrientField('carbs_g', [
    FdcNutrient(1005, _g),
    FdcNutrient(1050, _g),
  ], core: true),
  NutrientField('fiber_g', [FdcNutrient(1079, _g)], core: true),
  NutrientField('sugar_g', [FdcNutrient(2000, _g), FdcNutrient(1063, _g)]),
  NutrientField('saturated_fat_g', [FdcNutrient(1258, _g)]),
  NutrientField('trans_fat_g', [FdcNutrient(1257, _g)]),
  NutrientField('sodium_mg', [FdcNutrient(1093, _mg)]),
  NutrientField('cholesterol_mg', [FdcNutrient(1253, _mg)]),
  NutrientField('alcohol_g', [FdcNutrient(1018, _g)]),
];
