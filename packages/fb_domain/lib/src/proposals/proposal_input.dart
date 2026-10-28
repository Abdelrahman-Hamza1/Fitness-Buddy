/// Pure normalized proposal values and the v1 interpretation boundary.
library;

import 'dart:convert';

import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/diary/food_ref.dart';
import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/diary/provenance.dart';
import 'package:fb_domain/src/diary/slot_assigner.dart';
import 'package:fb_domain/src/food/food_state.dart';
import 'package:fb_domain/src/food/personal_food_ops.dart';
import 'package:fb_domain/src/food/portion/default_portion.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/nutrition/calculator.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/nutrition/yield.dart';
import 'package:fb_domain/src/proposals/proposal_policy_constants.dart';
import 'package:fb_domain/src/proposals/proposal_sync_codes.dart';
import 'package:fb_domain/src/targets/target_settings.dart';
import 'package:fb_domain/src/targets/weekly_budget.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/time/week_calendar.dart';
import 'package:fb_domain/src/units/amounts.dart';
import 'package:fb_domain/src/units/food_measures.dart';

part 'interpretation_decoder.dart';
part 'proposal_adjustment.dart';
part 'proposal_diff.dart';
part 'proposal_dimension.dart';
part 'proposal_engine.dart';
part 'proposal_models.dart';
part 'proposal_targets.dart';
part 'proposal_codec.dart';
part 'proposal_evaluation.dart';
part 'question_policy.dart';

/// Value equality for normalized immutable values; diagnostics omit all data.
abstract class ProposalValue {
  /// Base for immutable proposal values.
  const new();

  List<Object?> get _values;

  @override
  bool operator ==(Object other) =>
      other is ProposalValue &&
      runtimeType == other.runtimeType &&
      _same(_values, other._values);

  @override
  int get hashCode => Object.hash(runtimeType, _hash(_values));

  @override
  String toString() => '$runtimeType(redacted)';
}

bool _same(Object? a, Object? b) {
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(a.length, (i) => i).every((i) => _same(a[i], b[i]));
  }
  return a == b;
}

int _hash(Object? value) =>
    value is List ? Object.hashAll(value.map(_hash)) : value.hashCode;

/// Fixed boundary/engine issues; never include rejected content.
enum ProposalIssue {
  /// Invalid types, codes, bounds or references.
  invalidInput,

  /// Defensive work or byte-size ceiling exceeded.
  inputTooLarge,

  /// Local personal food or attached catalog key is unavailable.
  missingFoodFacts,

  /// Serialized facts or embedded identity contradict trusted definitions.
  factsMismatch,

  /// No trusted definition exists at the serialized source/version.
  staleFacts,

  /// An unmatched estimated food needs a user-provided amount.
  needsAmount,

  /// A missing unit, yield, density or active slot prevents a valid draft.
  needsConversion,

  /// Required assistant budget or current card rows have not arrived.
  sessionIncomplete,

  /// Message/card bindings, revisions or ownership disagree.
  budgetConflict,

  /// Unsupported stored codec version.
  unsupportedCodecVersion,

  /// Local pending draft must be reduced before syncing this projection.
  syncPayloadTooLarge,
}

/// Typed outcome, with exactly one of a value or a fixed issue.
final class ProposalResult<T> extends ProposalValue {
  /// A validated value.
  const new success(T this.value) : issue = null;

  /// A content-free failure.
  const new failure(ProposalIssue this.issue) : value = null;

  /// Validated value, absent on failure.
  final T? value;

  /// Fixed failure, absent on success.
  final ProposalIssue? issue;

  @override
  List<Object?> get _values => [value, issue];
}

/// Caller-owned allocator; computation has no clock or randomness.
abstract interface class ProposalIdSource {
  /// Allocate one UUIDv7 at build/add or for an unmatched rebuild line only.
  String next();
}

/// Canonical per-100 nutrient uncertainty, distinct from serving amounts.
final class ProposalRange extends ProposalValue {
  /// Finite, ordered lower/upper values in each core nutrient.
  new(this.low, this.high) {
    final l = _core(low);
    final h = _core(high);
    if (List.generate(5, (i) => i).any((i) => l[i] > h[i])) {
      throw const _Invalid();
    }
  }

  /// Lower per-100 bounds.
  final Nutrients low;

  /// Upper per-100 bounds.
  final Nutrients high;

  @override
  List<Object?> get _values => [low, high];
}

List<double> _core(Nutrients n) => [n.kcal, n.protein, n.carbs, n.fat, n.fiber];

/// Serving-specific canonical amount bounds, not nutrient ranges.
final class ProposalServing extends ProposalValue {
  /// A strictly positive amount on one canonical basis.
  new(this.code, this.amount, this.basis, this.low, this.high) {
    if (code.trim().isEmpty ||
        !amount.isFinite ||
        amount <= 0 ||
        (low == null) != (high == null) ||
        (low != null &&
            (!low!.isFinite ||
                !high!.isFinite ||
                low! <= 0 ||
                low! > amount ||
                high! < amount))) {
      throw const _Invalid();
    }
  }

  /// Serving unit code.
  final String code;

  /// Canonical amount for one serving.
  final double amount;

  /// Canonical basis of that amount.
  final NutrientBasis basis;

  /// Optional lower amount bound.
  final double? low;

  /// Optional upper amount bound.
  final double? high;

  @override
  List<Object?> get _values => [code, amount, basis, low, high];
}

/// Provenance of the exact facts used, frozen for local recompute.
enum ProposalFactOrigin {
  /// Current local personal-food row.
  localPersonal,

  /// Current local catalog row.
  localCatalog,

  /// Embedded per-100g facts when the entire pack is absent.
  embeddedServer,
}

/// Normalized food definition. No API DTOs or I/O dependencies.
final class ProposalFood extends ProposalValue {
  /// The local adapter supplies basis/version and personal optimistic version.
  new({
    required this.key,
    required this.names,
    required this.state,
    required this.source,
    required this.per100,
    this.basis = NutrientBasis.per100g,
    this.origin = ProposalFactOrigin.embeddedServer,
    this.version,
    this.personalVersion,
    this.density,
    this.yieldGroup,
    this.range,
    Iterable<ProposalServing> servings = const [],
  }) : servings = List.unmodifiable(servings);

  /// Opaque food identity, never inferred from the display name.
  final String key;

  /// Display-name snapshot, never logged.
  final FoodNames names;

  /// Actual definition state.
  final FoodState state;

  /// Actual food source.
  final FoodSource source;

  /// Definition values, never replaced by a model estimate on a match.
  final Nutrients per100;

  /// Definition basis; personal foods always take this from the local row.
  final NutrientBasis basis;

  /// Which frozen fact source won precedence.
  final ProposalFactOrigin origin;

  /// Optional local catalog pack version.
  final String? version;

  /// Personal row version for the confirm-time guard.
  final int? personalVersion;

  /// Grams per millilitre when known.
  final double? density;

  /// Catalog yield-group code.
  final String? yieldGroup;

  /// Optional reviewed per-100 ranges.
  final ProposalRange? range;

  /// Original serving order and amount uncertainty.
  final List<ProposalServing> servings;

  /// Domain measures, including food-specific units before generic units.
  FoodMeasures get measures => FoodMeasures(
    basis: basis,
    densityGramsPerMl: density,
    servingUnits: [
      for (final s in servings)
        if (s.basis == NutrientBasis.per100g)
          ServingUnit.grams(s.code, s.amount)
        else
          ServingUnit.milliliters(s.code, s.amount),
    ],
  );

  /// A provenance reference without a fabricated catalog version.
  FoodRef get ref => source == FoodSource.yours
      ? FoodRef.personal(key)
      : FoodRef(FoodRefKind.catalog, id: key, version: version);

  @override
  List<Object?> get _values => [
    key,
    names,
    state,
    source,
    per100,
    basis,
    origin,
    version,
    personalVersion,
    density,
    yieldGroup,
    range,
    servings,
  ];
}

/// Frozen adapter facts. Absence of a whole pack differs from a missing key.
final class ProposalFacts {
  /// Copies local maps so a later catalog/config refresh cannot affect a draft.
  new({
    Map<String, ProposalFood> personal = const {},
    Map<String, ProposalFood> catalog = const {},
    Map<String, String> catalogAliases = const {},
    this.packAvailable = false,
    Iterable<String> cookingFatIds = const {},
  }) : personal = Map.unmodifiable(personal),
       catalog = Map.unmodifiable(catalog),
       catalogAliases = Map.unmodifiable(catalogAliases),
       cookingFatIds = Set.unmodifiable(cookingFatIds);

  /// Current personal definitions and versions.
  final Map<String, ProposalFood> personal;

  /// Current catalog definitions with pack versions.
  final Map<String, ProposalFood> catalog;

  /// Trusted dish ID to default variant ID bindings from the local pack.
  final Map<String, String> catalogAliases;

  /// Verified cooking-fat IDs; never inferred from names or nutrient values.
  final Set<String> cookingFatIds;

  /// Whether the local pack is available, even if a requested key is missing.
  final bool packAvailable;

  @override
  String toString() => 'ProposalFacts(redacted)';
}

/// Invalid public proposal value; diagnostics contain only a fixed code.
final class ProposalInputException implements Exception {
  /// Never retains the rejected value.
  const new([this.issue = ProposalIssue.invalidInput]);

  /// Machine-readable failure.
  final ProposalIssue issue;
  @override
  String toString() => 'ProposalInputException(${issue.name})';
}

typedef _Invalid = ProposalInputException;

/// Independently loaded current definitions for restoring persisted drafts.
/// Serialized origin/version claims must never be used to construct this input.
final class TrustedFoodFacts {
  /// Copies the caller's local database/pack snapshot, including yield facts.
  new({
    Map<String, ProposalFood> foods = const {},
    Iterable<YieldFactor> yields = const [],
  }) : foods = Map.unmodifiable(foods),
       yields = List.unmodifiable(yields);

  /// Food key to current trusted source, version, nutrients and measures.
  final Map<String, ProposalFood> foods;

  /// Current pack's conversion facts.
  final List<YieldFactor> yields;
}
