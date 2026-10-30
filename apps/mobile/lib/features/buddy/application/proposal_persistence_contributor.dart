import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/durable_proposals.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proposal_persistence_contributor.g.dart';

/// Adds ops to the change sets of the Buddy thread (A22 D12, PA4; A23 D8):
/// each hook's ops are appended to the **same** change set as the thread's
/// own, so a reply, a follow-up, a confirm or a discard commits (or rolls
/// back) as one transaction. Every default adds nothing.
///
/// The app registers [DurableProposals], which writes the proposal rows
/// and assistant budgets through `ProposalSessionWriter`.
abstract class ProposalPersistenceContributor {
  /// A contributor.
  const new();

  /// With the reply change set that saves assistant row [assistantMessageId]
  /// for [session].
  List<ChangeOp> onReply(ProposalSession session, String assistantMessageId) =>
      const [];

  /// A change of [session] (an adjustment) worth persisting on its own:
  /// the whole session at its revision (A23 D7, D8).
  List<ChangeOp> onSessionChanged(
    ProposalSession session,
    SessionMembership membership,
  ) => const [];

  /// With the change set of follow-up assistant row [followUpMessageId]
  /// that rebuilt [card] into [session], moving it out of [from] (A22b,
  /// A23 D7).
  List<ChangeOp> onFollowUp(
    ProposalCard card,
    ProposalSession session,
    String followUpMessageId, {
    required ProposalSession from,
    required SessionMembership membership,
  }) => const [];

  /// With the confirm change set of [card] (`Origin.proposal(card.id)`);
  /// [resolved] is the session with the card confirmed.
  List<ChangeOp> onConfirm(
    ProposalCard card,
    ProposalSession resolved,
    SessionMembership membership,
  ) => const [];

  /// On discarding [card]; [resolved] is the session with it discarded.
  /// Any op makes the discard one undoable change set.
  List<ChangeOp> onDiscard(
    ProposalCard card,
    ProposalSession resolved,
    SessionMembership membership,
  ) => const [];
}

/// The registered contributors, in order: durable proposals (A23).
@Riverpod(keepAlive: true)
List<ProposalPersistenceContributor> proposalPersistenceContributors(Ref ref) =>
    const [DurableProposals()];
