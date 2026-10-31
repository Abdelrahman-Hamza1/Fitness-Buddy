import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:fb_catalog/src/model/yields.dart';
import 'package:fb_catalog/src/validate/report.dart';
import 'package:fb_domain/fb_domain.dart';

/// Catalog household units beyond `fb_domain`'s core units. Quarter, half
/// and whole describe edible chicken portions, not mass/volume measures.
const extraPortionUnits = {'can', 'quarter', 'half', 'whole'};

/// Base mass and volume codes: amounts, not portion words.
const _measureUnits = {'mg', 'g', 'kg', 'oz', 'lb', 'ml', 'l', 'fl_oz'};

/// Semantic rules for yields and portion words, added to [report]:
/// `from` differs from `to`, one row per group and direction (the converter
/// never chains), every basic's `yield_group` has a row (checked once
/// yields.yaml exists), food references resolve, units are known, ranges
/// contain the value, no Open Food Facts source (C-5).
void validateYieldsAndPortionWords(
  ValidationReport report, {
  required List<BasicFood> basics,
  required List<ReferenceDish> dishes,
  List<YieldRow>? yields,
  List<PortionWordRow>? portionWords,
  bool basicsLoaded = true,
}) {
  if (yields != null) {
    _yields(report, yields);
    // Skipped while yields.yaml doesn't exist yet (not curated).
    final states = <String, Set<FoodState>>{};
    for (final y in yields) {
      (states[y.group] ??= {}).addAll([y.from, y.to]);
    }
    for (final b in basics) {
      final g = b.yieldGroup;
      if (g == null) continue;
      final groupStates = states[g];
      String? message;
      if (groupStates == null) {
        message = '${b.id}: yield_group `$g` has no row in yields.yaml';
      } else if (!groupStates.contains(b.state)) {
        final allowed = [for (final s in groupStates) s.code].join(', ');
        message =
            '${b.id}: state `${b.state.code}` is not a from/to state of '
            'yield group `$g` ($allowed)';
      }
      if (message != null) {
        report.errors.add(
          CatalogIssue(b.file, '/foods/${b.index}/yield_group', message),
        );
      }
    }
  }
  if (portionWords != null) {
    _words(report, portionWords, basics, dishes, basicsLoaded);
  }
}

void _yields(ValidationReport report, List<YieldRow> rows) {
  final seen = <(String, FoodState, FoodState)>{};
  for (final r in rows) {
    final at = '/rows/${r.index}';
    void error(String path, String message) =>
        report.errors.add(CatalogIssue(r.file, '$at$path', message));
    if (r.from == r.to) {
      error('/to', '`to` must differ from `from` (${r.from.code})');
      continue;
    }
    if (!seen.add((r.group, r.from, r.to))) {
      error(
        '',
        'duplicate yield row ${r.group} ${r.from.code} -> ${r.to.code}',
      );
    } else if (seen.contains((r.group, r.to, r.from))) {
      error(
        '',
        '${r.group}: ${r.from.code} -> ${r.to.code} is already given by the '
            'inverse row (the converter inverts, one row per pair)',
      );
    }
    if (offSourcePattern.hasMatch(r.source)) {
      error('/source', 'Open Food Facts is not allowed as a source (C-5)');
    }
  }
}

void _words(
  ValidationReport report,
  List<PortionWordRow> rows,
  List<BasicFood> basics,
  List<ReferenceDish> dishes,
  bool basicsLoaded,
) {
  final basicIds = {for (final b in basics) b.id};
  final byId = {for (final b in basics) b.id: b};
  final seen = <String>{};
  for (final r in rows) {
    final at = '/rows/${r.index}';
    void error(String path, String message) =>
        report.errors.add(CatalogIssue(r.file, '$at$path', message));
    if (!foodResolves(r.food, basicIds, dishes, basicsLoaded: basicsLoaded)) {
      error(
        '/food',
        '`${r.food}` does not resolve to a USDA basic or a reference dish',
      );
    }
    if (_measureUnits.contains(r.unit)) {
      error(
        '/unit',
        '`${r.unit}` is a mass or volume unit, not a portion word',
      );
    } else if (!isKnownFoodUnitCode(r.unit) &&
        !extraPortionUnits.contains(r.unit)) {
      error('/unit', 'unknown unit `${r.unit}`');
    }
    // Household units have one owner: this file (A04 D5). A selection
    // serving with the same unit must agree.
    final serving = byId[r.food]?.servings[r.unit];
    if (serving != null && serving != r.g) {
      final says = r.g != null ? '${r.g} g' : '${r.ml} ml';
      error(
        '',
        '${r.food} ${r.unit}: usda_selection.yaml servings says $serving g '
            'but the portion word says $says'
            ' (one owner: fix or remove the serving)',
      );
    }
    if (!seen.add('${r.food}\u0000${r.unit}')) {
      error('', 'duplicate portion word ${r.unit} for ${r.food}');
    }
    final range = r.range;
    if (range != null) {
      if (range.lo > range.hi) {
        error('/range', 'range $range: low is above high');
      } else if (!range.contains(r.amount)) {
        error(
          '/range',
          '${r.g != null ? 'g' : 'ml'} ${r.amount} is outside its range '
              '$range',
        );
      }
    }
    if (offSourcePattern.hasMatch(r.source)) {
      error('/source', 'Open Food Facts is not allowed as a source (C-5)');
    }
  }
}
