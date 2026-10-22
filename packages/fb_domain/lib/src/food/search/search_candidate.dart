import 'package:fb_domain/src/food/search/name_matcher.dart';
import 'package:fb_domain/src/ids/hlc.dart';

/// Source precedence within the good band (FD-011/021).
enum SourceTier {
  /// User-created food.
  personal,

  /// A previously logged food.
  history,

  /// Verified database food.
  database,

  /// Reference dish.
  reference,
}

/// Immutable ranking input; keys are precomputed outside the pure domain.
/// Include identity keys and, only with known state, strict name/state/brand
/// keys (A07 D4). IDs must uniquely identify payloads within a search.
final class SearchCandidate<T> {
  /// One food or variant with its best strength across all its names.
  new({
    required Iterable<String> keys,
    required this.tier,
    required this.strength,
    required this.nameLength,
    required this.id,
    required this.payload,
    this.uses = 0,
    this.lastUsedHlc,
    this.isDefaultVariant = false,
  }) : keys = Set.unmodifiable(keys) {
    if (this.keys.isEmpty) throw ArgumentError('keys must not be empty');
  }

  /// Identity and strict duplicate keys; sharing any key merges candidates.
  final Set<String> keys;

  /// Source precedence.
  final SourceTier tier;

  /// Best whole-name match.
  final MatchStrength strength;

  /// Number of prior uses.
  final int uses;

  /// Most recent use, if any.
  final Hlc? lastUsedHlc;

  /// English display name's rune count.
  final int nameLength;

  /// Whether this is the dish's default variant.
  final bool isDefaultVariant;

  /// Stable identity, also the final deterministic tie breaker.
  final String id;

  /// Data returned when this candidate represents its merged group.
  final T payload;
}
