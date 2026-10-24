part of 'proposal_input.dart';

/// Production-identical deterministic result plus metrics-ready typed values.
final class ProposalEvaluationResult extends ProposalValue {
  /// No second arithmetic or question allocator lives in the eval facade.
  const new(this.result);

  /// Exact production outcome, including routing, lines, sources and issues.
  final ProposalBuildResult result;

  /// Count once per assistant message, never once per card.
  int get questionCount => result.value?.budget.questions.length ?? 0;

  /// All production cards with lifecycle, provenance, ranges and day previews.
  List<ProposalCard> get cards => result.value?.cards ?? const [];
  @override
  List<Object?> get _values => [result];
}

/// Headless B09 seam: recorded transport + local facts, no app/network imports.
abstract final class ProposalEvaluation {
  /// Same input admission, fact precedence and computations as the phone.
  static ProposalEvaluationResult evaluate(ProposalRequest request) =>
      ProposalEvaluationResult(ProposalEngine.build(request));
}
