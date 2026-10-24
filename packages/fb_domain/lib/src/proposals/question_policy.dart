part of 'proposal_input.dart';

/// Client-config thresholds, snapshotted before building a message session.
final class ProposalPolicy extends ProposalValue {
  /// Validated built-in defaults or remote values.
  const new _(this.relativeDelta, this.kcalDelta);

  /// Invalid/missing tuning falls back independently; cap is never config.
  factory fromThresholds(Map<String, double> thresholds) {
    double read(String key, double fallback, double max) {
      final v = thresholds[key];
      return v != null && v.isFinite && v >= 0 && v <= max ? v : fallback;
    }

    return ProposalPolicy._(
      read('proposalQuestionRelativeDelta', .20, 1),
      read('proposalQuestionKcalDelta', 50, 10000),
    );
  }

  /// Strict relative spread threshold.
  final double relativeDelta;

  /// Strict absolute spread threshold, kcal.
  final double kcalDelta;

  /// Both inequalities must hold (TD-081).
  bool asks(double low, double high) =>
      low.isFinite &&
      high.isFinite &&
      low >= 0 &&
      high >= low &&
      high - low > kcalDelta &&
      ProposalPolicyConstants.relativeDelta(low, high) > relativeDelta;

  @override
  List<Object?> get _values => [relativeDelta, kcalDelta];
}

/// Eligible unsettled question; construction enforces chip option bounds.
final class ProposalQuestion extends ProposalValue {
  /// Default and impact extremes first when there are more than four options.
  new({
    required this.dimensionId,
    required String kind,
    required this.impact,
    required Iterable<String> optionIds,
    String? subject,
  }) : questionKind = '$kind:${subject ?? '*'}',
       optionIds = List.unmodifiable(optionIds) {
    if (this.optionIds.length < 2 ||
        this.optionIds.length > 4 ||
        this.optionIds.toSet().length != this.optionIds.length ||
        !impact.isFinite ||
        impact < 0) {
      throw const _Invalid();
    }
  }

  /// Owning dimension ID, also the stable issued question ID.
  final String dimensionId;

  /// A26 answer-log key; no subject uses the wildcard.
  final String questionKind;

  /// Absolute kcal spread used for ranking.
  final double impact;

  /// Two to four structural option identities; A22 adds the Other action.
  final List<String> optionIds;
  @override
  List<Object?> get _values => [dimensionId, questionKind, impact, optionIds];
}

/// Closed bounded collection: no public constructor accepts arbitrary lists.
final class QuestionBudget extends ProposalValue {
  new _(Iterable<ProposalQuestion> questions)
    : questions = List.unmodifiable(questions);

  /// Highest impact first; stable source-order ties, at most two issued IDs.
  factory select(Iterable<ProposalQuestion> candidates) {
    final indexed = candidates.indexed.toList()
      ..sort((a, b) {
        final impact = b.$2.impact.compareTo(a.$2.impact);
        return impact == 0 ? a.$1.compareTo(b.$1) : impact;
      });
    final seen = <String>{};
    return QuestionBudget._(
      [
        for (final (_, q) in indexed)
          if (seen.add(q.dimensionId)) q,
      ].take(ProposalPolicyConstants.questionCap),
    );
  }

  /// Immutable bounded questions. Later reducers retain issued history.
  final List<ProposalQuestion> questions;
  @override
  List<Object?> get _values => [questions];
}
