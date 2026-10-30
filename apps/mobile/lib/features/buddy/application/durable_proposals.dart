import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/proposal_outcomes.dart';
import 'package:fb_mobile/features/buddy/application/proposal_persistence_contributor.dart';
import 'package:fb_mobile/features/buddy/application/proposal_session_writer.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';

/// Makes every Buddy card a durable `proposals` row (A23 D8): the one
/// registered contributor, delegating to [ProposalSessionWriter].
///
/// Creating, saving or rebinding an unconfirmed card is bookkeeping without
/// an undo entry; confirm and discard are undoable by their change set.
final class DurableProposals extends ProposalPersistenceContributor {
  /// The contributor.
  const new();

  @override
  List<ChangeOp> onReply(ProposalSession session, String assistantMessageId) =>
      ProposalSessionWriter.reply(session, assistantMessageId);

  @override
  List<ChangeOp> onSessionChanged(
    ProposalSession session,
    SessionMembership membership,
  ) => ProposalSessionWriter.write(session, membership);

  @override
  List<ChangeOp> onFollowUp(
    ProposalCard card,
    ProposalSession session,
    String followUpMessageId, {
    required ProposalSession from,
    required SessionMembership membership,
  }) => ProposalSessionWriter.move(card, session, from, membership);

  @override
  List<ChangeOp> onConfirm(
    ProposalCard card,
    ProposalSession resolved,
    SessionMembership membership,
  ) => ProposalSessionWriter.write(
    resolved,
    membership,
    resolve: ResolvedCard(
      card.id,
      ProposalStatus.confirmed,
      ProposalOutcomes.confirmed(resolved, card, membership),
    ),
  );

  @override
  List<ChangeOp> onDiscard(
    ProposalCard card,
    ProposalSession resolved,
    SessionMembership membership,
  ) => ProposalSessionWriter.write(
    resolved,
    membership,
    resolve: ResolvedCard(
      card.id,
      ProposalStatus.discarded,
      ProposalOutcomes.discarded,
    ),
  );

  @override
  String toString() => 'DurableProposals';
}
