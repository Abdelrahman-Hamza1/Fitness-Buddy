import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/proposal_persistence_contributor.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_reader.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proposal_resolution.g.dart';

/// Where a card came from: the answer it was built from, the assistant row
/// that owns its budget and the send time. Needed to rebuild it with current
/// facts after a rejected confirm. Holds user content: never logged.
final class CardOrigin {
  /// The origin.
  const new({
    required this.interpretation,
    required this.messageId,
    required this.referenceTime,
  });

  /// The answer JSON.
  final Map<String, Object?> interpretation;

  /// The assistant row (the card's `budgetMessageId`).
  final String messageId;

  /// The engine's reference time.
  final EntryTime referenceTime;

  @override
  String toString() => 'CardOrigin($messageId)';
}

/// What confirming a card gave.
sealed class ConfirmOutcome {
  const new _();
}

/// The card's ops committed as one change set: [session] has it confirmed,
/// with refreshed confirmed totals; [undoEntryId] undoes it (one undo per
/// confirm, D25).
final class CardLogged extends ConfirmOutcome {
  /// The outcome.
  const new({
    required this.session,
    required this.undoEntryId,
    required this.appliedAt,
  }) : super._();

  /// When the change set was applied (UTC): the undo window starts here.
  final DateTime appliedAt;

  /// The recomputed session.
  final ProposalSession session;

  /// The undo stack entry.
  final String undoEntryId;

  @override
  String toString() => 'CardLogged($undoEntryId)';
}

/// Nothing was written: a food or slot behind the card changed, so it was
/// rebuilt with current facts ([session] holds the new card, same ID).
final class CardRebuilt extends ConfirmOutcome {
  /// The outcome.
  const new(this.session) : super._();

  /// The rebuilt card's session.
  final ProposalSession session;

  @override
  String toString() => 'CardRebuilt';
}

/// Nothing was written and nothing rebuilt ("Couldn't log this card.").
final class CardNotLogged extends ConfirmOutcome {
  /// The outcome.
  const new() : super._();

  @override
  String toString() => 'CardNotLogged';
}

/// What discarding a card gave: the session with it discarded, or `null`
/// when a contributor's change set was rejected (nothing changed).
typedef DiscardOutcome = ProposalSession?;

/// Confirm and discard of one proposal card (A22 D12, D25, AI-035–037).
///
/// Confirm composes only this card's draft ops plus the contributors'
/// `onConfirm` ops into one `ChangeSet` with `Origin.proposal(card.id)` and
/// one apply. Nothing from a pending card is ever written before that.
final class ProposalResolution {
  /// Resolution over its ports.
  const new({
    required this._apply,
    required this._undo,
    required this._loader,
    required this._ids,
    required this._contributors,
    BuddyIssueSink? report,
  }) : _report = report ?? _ignore;

  static void _ignore(BuddyIssue _) {}

  final Future<ApplyResult> Function(ChangeSet) _apply;
  final UndoStack _undo;
  final ProposalInputLoader _loader;
  final IdGenerator _ids;
  final List<ProposalPersistenceContributor> _contributors;
  final BuddyIssueSink _report;

  /// Confirms [cardId] of [session]. A card that can't be confirmed writes
  /// nothing ([CardNotLogged]).
  Future<ConfirmOutcome> confirm(
    ProposalSession session,
    String cardId,
    CardOrigin origin,
  ) async {
    final card = session.cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null || !card.canConfirm) return const CardNotLogged();
    final ops = [
      ...card.draftOps,
      for (final c in _contributors) ...c.onConfirm(card, session),
    ];
    if (ops.length > ChangeSet.maxOps) return const CardNotLogged();
    final result = await _apply(
      ChangeSet(ops, origin: Origin.proposal(card.id)),
    );
    switch (result) {
      case Applied():
        final entry = _undo.record(result, UndoLabel('proposalLogged'));
        // Written and undoable from here: a failing refresh must never make
        // a logged card look unlogged (the user would log it twice). The
        // previews stay as they were until the next refresh (A22a review
        // round 2); only the issue type is reported.
        ProposalSession next;
        try {
          next = await refresh(
            session,
            origin.referenceTime,
            confirmedCardId: card.id,
          );
          // Any throw here: the write already happened.
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {
          _report(const BuddyRefreshFailed());
          next =
              ProposalEngine.recompute(
                session,
                ProposalSetLifecycle(card.id, ProposalLifecycle.confirmed),
              ).value?.session ??
              session;
        }
        return CardLogged(
          session: next,
          undoEntryId: entry.id,
          appliedAt: entry.appliedAt,
        );
      case Rejected(:final failure):
        if (!isFactChange(failure)) return const CardNotLogged();
        final request = await _loader.load(
          interpretation: origin.interpretation,
          messageId: origin.messageId,
          idSource: GeneratorProposalIds(_ids),
          referenceTime: origin.referenceTime,
          days: {card.preview.date},
        );
        final fresh = request.value;
        final rebuilt = fresh == null
            ? null
            : ProposalEngine.rebuild(card, fresh).value;
        return rebuilt == null
            ? const CardNotLogged()
            : CardRebuilt(rebuilt.session);
    }
  }

  /// Discards [cardId]: in memory only, unless a contributor adds ops (then
  /// one change set).
  Future<DiscardOutcome> discard(ProposalSession session, String cardId) async {
    final card = session.cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null || card.lifecycle != ProposalLifecycle.active) {
      return null;
    }
    final ops = [for (final c in _contributors) ...c.onDiscard(card, session)];
    if (ops.isNotEmpty &&
        await _apply(ChangeSet(ops, origin: Origin.system)) is! Applied) {
      return null;
    }
    return ProposalEngine.recompute(
      session,
      ProposalSetLifecycle(card.id, ProposalLifecycle.discarded),
    ).value?.session;
  }

  /// Whether a discard can be undone in memory: only while no contributor
  /// could have written ops with it (A22b E8; A23 adds a resolve-undo
  /// first).
  bool get discardUndoable => _contributors.isEmpty;

  /// Undoes the confirm [undoEntryId] (the single undo of D25).
  Future<UndoOutcome> undo(String undoEntryId) => _undo.undo(undoEntryId);

  /// [session] recomputed with a refreshed context, so every preview counts
  /// confirmed intake once (D12); [confirmedCardId], when given, becomes
  /// confirmed in the same step. Unchanged when the context can't be read.
  Future<ProposalSession> refresh(
    ProposalSession session,
    EntryTime referenceTime, {
    String? confirmedCardId,
  }) async {
    if (session.cards.isEmpty) return session;
    final context = await _loader.refreshContext(
      referenceTime: referenceTime,
      days: {for (final c in session.cards) c.preview.date},
    );
    if (context == null) return session;
    final card = confirmedCardId == null
        ? session.cards.first
        : session.cards.where((c) => c.id == confirmedCardId).firstOrNull;
    if (card == null) return session;
    // Re-stating a card's lifecycle is the engine's context refresh.
    final lifecycle = confirmedCardId == null
        ? card.lifecycle
        : ProposalLifecycle.confirmed;
    return ProposalEngine.recompute(
          session,
          ProposalSetLifecycle(card.id, lifecycle),
          context: context,
        ).value?.session ??
        session;
  }

  /// Whether [failure] means a fact or slot behind the card changed (a
  /// personal food's version, a missing food, a removed or inactive slot):
  /// the only rejections that rebuild the card (PA5). A duplicate ID or any
  /// other rejection never does.
  static bool isFactChange(ChangeFailure failure) => switch (failure) {
    VersionConflict(entity: 'personalFood') ||
    RowNotFound(entity: 'personalFood' || 'mealSlot') => true,
    InvalidOp(code: 'unknownSlot' || 'inactiveSlot' || 'noSlot') => true,
    _ => false,
  };

  @override
  String toString() => 'ProposalResolution';
}

/// The app's proposal resolution.
@Riverpod(keepAlive: true)
ProposalResolution proposalResolution(Ref ref) => ProposalResolution(
  apply: ref.watch(changeSetApplierProvider).apply,
  undo: ref.watch(undoStackProvider),
  loader: ref.watch(proposalInputLoaderProvider),
  ids: ref.watch(idGeneratorProvider),
  contributors: ref.watch(proposalPersistenceContributorsProvider),
  report: ref.watch(buddyIssueSinkProvider),
);
