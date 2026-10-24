/// Invariants and defensive limits, distinct from remote tuning (A21 D12).
abstract final class ProposalPolicyConstants {
  /// TD-081: one message can issue at most two question IDs, ever.
  static const questionCap = 2;

  /// TD-082: the visible reduced-share oil assumption, not measured absorption.
  static const mostOilLeft = .25;

  /// Maximum normalized intents in a local interpretation.
  static const maxIntents = 20;

  /// Maximum food items across a message.
  static const maxItems = 50;

  /// Maximum ambiguity dimensions on an item.
  static const maxDimensions = 8;

  /// Maximum options in a dimension before asking/assuming policy.
  static const maxOptions = 32;

  /// Selected candidate plus at most three distinct alternatives.
  static const maxCandidates = 4;

  /// Local boundary size; independent of the later sync-string ceiling.
  static const int maxInputBytes = 512 * 1024;

  /// TD-081: zero-to-positive has infinite impact; zero-to-zero has none.
  static double relativeDelta(double low, double high) =>
      low == 0 ? (high == 0 ? 0 : double.infinity) : (high - low) / low;
}
