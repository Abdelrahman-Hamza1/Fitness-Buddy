import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';

/// How a resolved card ended (A23 D9, `06` §5): the outcome A26 learns
/// from, only ever for confirmed or discarded cards.
abstract final class ProposalOutcomes {
  /// The outcome of confirming [card] of [session]: `adjusted` when the user
  /// changed the card ([ProposalEngine.hasUserState]) or a follow-up rebuilt
  /// it (its budget message is a follow-up reply other than its origin);
  /// a fact rebuild into a new message alone isn't an adjustment (rec R3).
  /// Otherwise `unchanged`.
  static ProposalOutcome confirmed(
    ProposalSession session,
    ProposalCard card,
    SessionMembership membership,
  ) {
    final followedUp =
        card.budgetMessageId != card.originMessageId &&
        membership.isFollowUp(card.budgetMessageId);
    return followedUp || ProposalEngine.hasUserState(session, card.id)
        ? ProposalOutcome.adjusted
        : ProposalOutcome.unchanged;
  }

  /// The outcome of discarding a card.
  static const ProposalOutcome discarded = ProposalOutcome.discarded;
}
