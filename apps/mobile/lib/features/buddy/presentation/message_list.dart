import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_messages.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/food_proposal_card.dart';
import 'package:fb_mobile/features/buddy/presentation/message_direction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Buddy's fixed English replies from ARB (A22 D7, D16; AI-143).
BuddyReplyTexts buddyReplyTexts(AppLocalizations l10n) => BuddyReplyTexts(
  cards: l10n.buddyReplyCards,
  updated: l10n.buddyReplyUpdated,
  cardClosed: l10n.buddyReplyCardClosed,
  medical: l10n.buddyReplyMedical,
  notFood: l10n.buddyReplyNotFood,
  noCard: l10n.buddyReplyNoCard,
  unsupported: l10n.buddyReplyUnsupported,
);

/// The thread (A22 D14): newest at the bottom, in display order (each user
/// message, then the replies to it, then its cards). Text and status come
/// from the saved rows.
///
/// It follows the thread as it grows: when a turn's first card arrives the
/// sheet goes to full height and the card's top is scrolled into view (a
/// card is taller than the resting sheet); otherwise it follows the newest
/// item. Not a reversed list: the sheet's drag shares this scroll, and a
/// reversed list would turn "drag up for the full thread" upside down.
class BuddyMessageList extends ConsumerStatefulWidget {
  /// The list, scrolled by [controller]; [sheet] sizes the sheet; [onSearch]
  /// opens food search.
  const new({
    required this.controller,
    required this.onSearch,
    this.sheet,
    super.key,
  });

  /// The sheet's scroll controller.
  final ScrollController controller;

  /// The sheet's size, expanded when a card arrives.
  final DraggableScrollableController? sheet;

  /// Closes the sheet and opens food search.
  final VoidCallback onSearch;

  @override
  ConsumerState<BuddyMessageList> createState() => _BuddyMessageListState();
}

class _BuddyMessageListState extends ConsumerState<BuddyMessageList> {
  /// The first card of each turn, to scroll its top into view.
  final Map<String, GlobalKey> _firstCards = {};

  /// What the list last followed, and the cards already shown.
  String? _followed;
  final Set<String> _shownCards = {};

  ScrollController get controller => widget.controller;

  VoidCallback get onSearch => widget.onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final thread = ref.watch(buddyThreadControllerProvider);
    final rows = ref.watch(buddyThreadMessagesProvider).value ?? const {};
    final items = <Widget>[
      if (thread.turns.isEmpty)
        Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s2),
          child: Text(
            l10n.buddyEmpty,
            style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      // Stored cards with no turn to show them in (A23 D13).
      for (final card in thread.orphans)
        UnrestorableCardRow(key: ValueKey(card.id), card: card),
      for (final turn in thread.turns) ..._turn(context, ref, turn, rows),
    ];
    _follow(thread, rows.length);
    return ListView(
      controller: controller,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s4,
        vertical: FbSpace.s2,
      ),
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: FbSpace.s1,
            ),
            child: item,
          ),
      ],
    );
  }

  /// After this frame: show a newly arrived card from its top (full height),
  /// or follow the newest item when the thread changed otherwise.
  void _follow(BuddyThread thread, int rows) {
    final key = [
      rows,
      for (final turn in thread.turns) '${turn.phase.name}${turn.cards.length}',
    ].join();
    if (key == _followed) return;
    final first = _followed == null;
    _followed = key;
    final arrived = [
      for (final turn in thread.turns)
        if (turn.cards.isNotEmpty && !_shownCards.contains(turn.cards.first.id))
          turn.cards.first.id,
    ];
    _shownCards.addAll([
      for (final turn in thread.turns) ...turn.cards.map((c) => c.id),
    ]);
    if (first) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !controller.hasClients) return;
      final duration = FbMotion.of(context);
      final card = arrived.isEmpty ? null : _firstCards[arrived.last];
      if (card != null) {
        final sheet = widget.sheet;
        if (sheet != null && sheet.isAttached && sheet.size < 1) {
          if (duration == Duration.zero) {
            sheet.jumpTo(1);
          } else {
            await sheet.animateTo(1, duration: duration, curve: FbMotion.curve);
          }
        }
        final target = card.currentContext;
        if (target != null && target.mounted) {
          await Scrollable.ensureVisible(
            target,
            duration: duration,
            curve: FbMotion.curve,
          );
          return;
        }
      }
      if (!controller.hasClients) return;
      final end = controller.position.maxScrollExtent;
      if (duration == Duration.zero) {
        controller.jumpTo(end);
      } else {
        await controller.animateTo(
          end,
          duration: duration,
          curve: FbMotion.curve,
        );
      }
    });
  }

  List<Widget> _turn(
    BuildContext context,
    WidgetRef ref,
    BuddyTurn turn,
    Map<String, ChatMessage> rows,
  ) {
    final l10n = context.l10n;
    final user = rows[turn.userMessageId];
    final userText = user?.draft.text ?? turn.message.text;
    final reply = turn.assistantMessageId == null
        ? null
        : rows[turn.assistantMessageId];
    return [
      FbMessageBubble(
        key: ValueKey(turn.userMessageId),
        text: userText,
        fromUser: true,
        textDirection: messageDirection(userText),
        semanticLabel: l10n.buddyBubbleYou(userText),
      ),
      // The plain "here's your meal" line adds nothing above its cards; it
      // stays stored (the transcript) but isn't drawn.
      if (reply != null &&
          !(turn.cards.isNotEmpty && reply.draft.text == l10n.buddyReplyCards))
        FbMessageBubble(
          key: ValueKey(reply.id),
          text: reply.draft.text,
          fromUser: false,
          semanticLabel: l10n.buddyBubbleBuddy(reply.draft.text),
          // Who is talking, as on the canvas (A44); decorative.
          leading: const FbBuddyAvatar(size: 24),
        ),
      // A follow-up updates its card in place ("Updating…" on the card), so
      // it gets no skeleton of its own.
      if (turn.phase == BuddyTurnPhase.sending && turn.followUpCardId == null)
        FbProposalCard.skeleton(semanticLabel: l10n.buddyWorking),
      if (turn.phase == BuddyTurnPhase.failed)
        _Failure(turn: turn, onSearch: onSearch),
      for (final (index, card) in turn.cards.indexed)
        FoodProposalCard(
          key: index == 0
              ? _firstCards.putIfAbsent(card.id, GlobalKey.new)
              : ValueKey(card.id),
          onSearch: onSearch,
          view: FoodCardView.of(
            card,
            referenceDate: turn.message.time.localDate,
            updating: ref
                .read(buddyThreadControllerProvider)
                .isUpdating(card.id),
            turnAnswer: turn.interpretation,
          ),
        ),
      // Stored cards that couldn't be reopened (A23 D13).
      for (final card in turn.unrestorable)
        UnrestorableCardRow(key: ValueKey(card.id), card: card),
    ];
  }
}

/// What to say and offer under a message that failed (A22 D6).
class _Failure extends ConsumerWidget {
  const new({required this.turn, required this.onSearch});

  final BuddyTurn turn;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final failure = turn.failure ?? BuddySendFailure.server;
    final secondUnavailable =
        failure == BuddySendFailure.unavailable && turn.unavailableCount >= 2;
    final message = switch (failure) {
      BuddySendFailure.offline => l10n.buddyFailureOffline,
      BuddySendFailure.timeout => l10n.buddyFailureTimeout,
      BuddySendFailure.server => l10n.buddyFailureServer,
      BuddySendFailure.unavailable =>
        secondUnavailable
            ? l10n.buddyFailureUnavailableFinal
            : l10n.buddyFailureUnavailable,
      BuddySendFailure.rejected => l10n.buddyFailureRejected,
      BuddySendFailure.rateLimited => l10n.buddyFailureRateLimited,
    };
    final retry = turn.canRetry && failure != BuddySendFailure.offline;
    // Search works offline and after Buddy gives up: offer it then too.
    final search = !retry;
    return FbInlineBanner(
      kind: failure == BuddySendFailure.offline
          ? FbInlineBannerKind.offline
          : FbInlineBannerKind.info,
      message: message,
      actionLabel: retry
          ? l10n.buddyTryAgain
          : search
          ? l10n.buddySearchFoods
          : null,
      onAction: retry
          ? () => unawaited(
              ref
                  .read(buddyThreadControllerProvider.notifier)
                  .retry(turn.userMessageId, buddyReplyTexts(l10n)),
            )
          : search
          ? onSearch
          : null,
    );
  }
}
