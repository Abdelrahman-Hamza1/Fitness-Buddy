/// The `diaryEntry` / `savedMealItem` v2 wire rules W1–W3 of
/// `contracts/README.md` § "diaryEntry and savedMealItem versions" (A62a D5,
/// D27, TD-114), and nothing else. The server admits exactly these after the
/// schema check (`DiaryEstimatePayloadValidator`), the app keeps them on
/// every write, and the shared corpus
/// (`contracts/testdata/sync/diary-estimate-validation-vectors.json`) is
/// generated from them. v1 has no wire rules.
enum DiaryEstimateWireRule {
  /// W1: a `userEstimate` row is `foodKind` `estimate`, `source` `yours`,
  /// `isEstimate` true and `foodId` null.
  userEstimateShape('W1', 'W1 user estimate shape'),

  /// W2: a row with any `*Known` false is a `userEstimate`.
  unknownsOnlyOnUserEstimates('W2', 'W2 unknowns only on user estimates'),

  /// W3: an unknown nutrient is 0 in its snapshot and per-100 field.
  unknownIsStoredZero('W3', 'W3 unknown is stored zero');

  new(this.id, this.readme);

  /// The short rule ID (`W1` …).
  final String id;

  /// The README bullet label.
  final String readme;
}

/// The wire checks on a decoded v2 payload. Content-free: results name a
/// rule, never a value.
abstract final class DiaryEstimateWireRules {
  /// The entities the rules cover.
  static const List<String> entities = ['diaryEntry', 'savedMealItem'];

  /// The schema versions the rules know; v1 has none, v2 has W1–W3.
  static const List<int> versions = [1, 2];

  /// The `foodKind` of a user estimate (W1).
  static const String foodKind = 'estimate';

  /// The `source` of a user estimate (W1).
  static const String source = 'yours';

  /// The four nutrients that can be unknown, as wire fields:
  /// (known flag, snapshot, per-100). kcal is always known.
  static const List<(String, String, String)> nutrients = [
    ('proteinKnown', 'proteinG', 'per100ProteinG'),
    ('carbsKnown', 'carbsG', 'per100CarbsG'),
    ('fatKnown', 'fatG', 'per100FatG'),
    ('fiberKnown', 'fiberG', 'per100FiberG'),
  ];

  /// The five fields v2 adds to v1, in contract order.
  static const List<String> v2Fields = [
    'userEstimate',
    'proteinKnown',
    'carbsKnown',
    'fatKnown',
    'fiberKnown',
  ];

  /// The first rule [payload] breaks at [schemaVersion], or `null` when it
  /// holds. Throws an `ArgumentError` for an unknown entity or version (fail
  /// closed). A v2 payload whose rule fields don't have their schema types
  /// (a non-boolean flag, a non-number value) breaks the rule that reads
  /// them; the schema rejects those as well.
  static DiaryEstimateWireRule? violation(
    String entity,
    int schemaVersion,
    Map<String, Object?> payload,
  ) {
    if (!entities.contains(entity)) {
      throw ArgumentError.value(entity, 'entity');
    }
    if (!versions.contains(schemaVersion)) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    if (schemaVersion == 1) return null;
    final userEstimate = payload['userEstimate'];
    if (userEstimate == true &&
        !(payload['foodKind'] == foodKind &&
            payload['source'] == source &&
            payload['isEstimate'] == true &&
            payload.containsKey('foodId') &&
            payload['foodId'] == null)) {
      return DiaryEstimateWireRule.userEstimateShape;
    }
    final anyUnknown = nutrients.any((n) => payload[n.$1] != true);
    if (anyUnknown && userEstimate != true) {
      return DiaryEstimateWireRule.unknownsOnlyOnUserEstimates;
    }
    for (final (known, snapshot, per100) in nutrients) {
      if (payload[known] == true) continue;
      if (!_isZero(payload[snapshot]) || !_isZero(payload[per100])) {
        return DiaryEstimateWireRule.unknownIsStoredZero;
      }
    }
    return null;
  }

  /// Whether [payload] keeps W1–W3 at [schemaVersion].
  static bool holds(
    String entity,
    int schemaVersion,
    Map<String, Object?> payload,
  ) => violation(entity, schemaVersion, payload) == null;

  static bool _isZero(Object? value) => value is num && value == 0;
}
