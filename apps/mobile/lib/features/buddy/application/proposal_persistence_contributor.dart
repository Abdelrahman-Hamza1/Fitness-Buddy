import 'package:fb_domain/fb_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proposal_persistence_contributor.g.dart';

/// Adds ops to the change sets of the Buddy thread (A22 D12, PA4): each
/// hook's ops are appended to the **same** change set as A22's own, so a
/// reply, a confirm or a discard commits (or rolls back) as one transaction.
///
/// A22a registers none. A23 adds proposal create, resolve, outcome and
/// message-budget ops here; whichever of A22b/A23 merges second wires
/// [onFollowUp]. Every default adds nothing.
abstract class ProposalPersistenceContributor {
  /// A contributor.
  const new();

  /// With the reply change set that saves assistant row [assistantMessageId]
  /// for [session].
  List<ChangeOp> onReply(ProposalSession session, String assistantMessageId) =>
      const [];

  /// With the confirm change set of [card] (`Origin.proposal(card.id)`).
  List<ChangeOp> onConfirm(ProposalCard card, ProposalSession session) =>
      const [];

  /// On discarding [card]; any op makes the discard one change set.
  List<ChangeOp> onDiscard(ProposalCard card, ProposalSession session) =>
      const [];

  /// With the change set of follow-up assistant row [followUpMessageId]
  /// that rebuilt [card] (A22b/A23).
  List<ChangeOp> onFollowUp(
    ProposalCard card,
    ProposalSession session,
    String followUpMessageId,
  ) => const [];
}

/// The registered contributors, in order. Empty in A22a.
@Riverpod(keepAlive: true)
List<ProposalPersistenceContributor> proposalPersistenceContributors(Ref ref) =>
    const [];
