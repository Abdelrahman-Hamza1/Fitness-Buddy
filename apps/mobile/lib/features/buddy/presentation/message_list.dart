import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_messages.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/application/turn/buddy_trace.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/buddy_notice_row.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/food_proposal_card.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/record_proposal_card.dart';
import 'package:fb_mobile/features/buddy/presentation/message_direction.dart';
import 'package:fb_mobile/features/buddy/presentation/trace_sheet.dart';
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
/// from the saved rows. Built lazily, one keyed item per message, card or
/// note (A57 A77).
///
/// It follows the thread as it grows, but only while the reader is at the
/// bottom (within 48 dp, A67) or has just sent a message: when a turn's
/// first card arrives the sheet goes to full height and the card's top is
/// scrolled into view (a card is taller than the resting sheet); otherwise
/// it follows the newest item. A reader scrolled up stays where they are
/// and gets a "New message" button that jumps down. Reopened, it shows the
/// latest turn (A66), or the oldest waiting card with [revealPending].
/// Following runs from a listener on the thread, never from `build`. Not a
/// reversed list: the sheet's drag shares this scroll, and a reversed list
/// would turn "drag up for the full thread" upside down.
class BuddyMessageList extends ConsumerStatefulWidget {
  /// The list, scrolled by [controller]; [sheet] sizes the sheet; [onSearch]
  /// opens food search.
  const new({
    required this.controller,
    required this.onSearch,
    this.onReviewFood,
    this.sheet,
    this.revealPending = false,
    super.key,
  });

  /// The sheet's scroll controller.
  final ScrollController controller;

  /// The sheet's size, expanded when a card arrives.
  final DraggableScrollableController? sheet;

  /// Closes the sheet and opens food search.
  final VoidCallback onSearch;

  /// Closes the sheet and opens the prepared new-food form (A67 D8).
  final VoidCallback? onReviewFood;

  /// Whether the list opens at the oldest open card (D-094).
  final bool revealPending;

  /// The "New message" button's key.
  static const ValueKey<String> newMessagesKey = ValueKey('buddy-new-messages');

  /// How close to the bottom still counts as "at the bottom" (A67).
  static const double followSlack = 48;

  @override
  ConsumerState<BuddyMessageList> createState() => _BuddyMessageListState();
}

class _BuddyMessageListState extends ConsumerState<BuddyMessageList> {
  /// Every card's key, to scroll a card's top into view.
  final Map<String, GlobalKey> _firstCards = {};

  /// What the list last followed, and the cards already shown.
  String? _followed;
  int _turns = 0;
  final Set<String> _shownCards = {};

  /// Something arrived below while the reader was scrolled up (A67).
  bool _unseen = false;

  ScrollController get controller => widget.controller;

  VoidCallback get onSearch => widget.onSearch;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onScroll);
    ref
      ..listenManual(buddyThreadControllerProvider, (_, _) => _changed())
      ..listenManual(buddyThreadMessagesProvider, (_, _) => _changed());
    _remember(ref.read(buddyThreadControllerProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_opened()));
  }

  @override
  void didUpdateWidget(BuddyMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_onScroll);
      controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onScroll);
    super.dispose();
  }

  bool get _atBottom {
    if (!controller.hasClients) return true;
    final position = controller.position;
    return position.maxScrollExtent - position.pixels <=
        BuddyMessageList.followSlack;
  }

  void _onScroll() {
    if (_unseen && _atBottom) setState(() => _unseen = false);
  }

  /// The thread's shape: what changed since the last follow.
  String _keyOf(BuddyThread thread) => [
    ref.read(buddyThreadMessagesProvider).value?.length ?? 0,
    // The streamed reply's growth follows too (A67).
    for (final turn in thread.turns)
      '${turn.phase.name}${turn.cards.length}:${turn.replyText.length}',
  ].join();

  /// Records [thread] as followed; returns the cards that just arrived.
  List<String> _remember(BuddyThread thread) {
    _followed = _keyOf(thread);
    _turns = thread.turns.length;
    final arrived = [
      for (final turn in thread.turns)
        if (turn.cards.isNotEmpty && !_shownCards.contains(turn.cards.first.id))
          turn.cards.first.id,
    ];
    _shownCards.addAll([
      for (final turn in thread.turns) ...turn.cards.map((c) => c.id),
    ]);
    return arrived;
  }

  /// The first frame of an opened sheet: the latest turn, or the oldest
  /// waiting card (A66, D-094).
  Future<void> _opened() async {
    if (!mounted) return;
    final thread = ref.read(buddyThreadControllerProvider);
    final open = [
      for (final turn in thread.turns)
        for (final card in turn.cards)
          if (card.resolution == CardResolution.open) card.id,
    ].firstOrNull;
    await _jumpToEnd();
    if (widget.revealPending && open != null) await _reveal(open);
  }

  /// The thread changed: follow it when the reader is at the bottom or has
  /// just sent, else offer "New message" (A67). Runs after the change, but
  /// before the new content is laid out, so [_atBottom] is where the reader
  /// was.
  void _changed() {
    final thread = ref.read(buddyThreadControllerProvider);
    if (_keyOf(thread) == _followed) return;
    final sent = thread.turns.length > _turns;
    final follow = sent || _atBottom;
    final arrived = _remember(thread);
    if (!follow) {
      if (!_unseen) setState(() => _unseen = true);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !controller.hasClients) return;
      final card = arrived.lastOrNull;
      if (card != null) {
        await _expandSheet();
        if (await _reveal(card)) return;
      }
      await _toEnd();
    });
  }

  Future<void> _expandSheet() async {
    final sheet = widget.sheet;
    if (sheet == null || !sheet.isAttached || sheet.size >= 1) return;
    final duration = FbMotion.localOf(context);
    if (duration == Duration.zero) {
      sheet.jumpTo(1);
    } else {
      await sheet.animateTo(1, duration: duration, curve: FbMotion.standard);
    }
  }

  /// Scrolls card [id]'s top into view. A lazily built card that isn't
  /// laid out yet is found by stepping up from the end, a screen at a time.
  Future<bool> _reveal(String id) async {
    for (var step = 0; step < 64; step++) {
      if (!mounted || !controller.hasClients) return false;
      final target = _firstCards[id]?.currentContext;
      if (target != null && target.mounted) {
        final duration = FbMotion.localOf(context);
        await Scrollable.ensureVisible(
          target,
          duration: duration,
          curve: FbMotion.standard,
        );
        return true;
      }
      final position = controller.position;
      if (position.pixels <= position.minScrollExtent) return false;
      controller.jumpTo(
        (position.pixels - position.viewportDimension).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    return false;
  }

  /// Animates to the newest item.
  Future<void> _toEnd() async {
    if (!mounted || !controller.hasClients) return;
    final duration = FbMotion.localOf(context);
    if (duration == Duration.zero) {
      await _jumpToEnd();
      return;
    }
    await controller.animateTo(
      controller.position.maxScrollExtent,
      duration: duration,
      curve: FbMotion.standard,
    );
    // A lazy list's extent firms up as the last items are laid out.
    await _jumpToEnd();
  }

  /// Jumps to the newest item; a lazy list's end is estimated until its
  /// last items are laid out, so it settles over a few frames.
  Future<void> _jumpToEnd() async {
    for (var step = 0; step < 8; step++) {
      if (!mounted || !controller.hasClients) return;
      final end = controller.position.maxScrollExtent;
      if (controller.position.pixels == end) return;
      controller.jumpTo(end);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final thread = ref.watch(buddyThreadControllerProvider);
    final rows = ref.watch(buddyThreadMessagesProvider).value ?? const {};
    final items = <(String, Widget)>[
      if (thread.turns.isEmpty)
        (
          'empty',
          Padding(
            padding: const EdgeInsetsDirectional.all(FbSpace.s2),
            child: Text(
              l10n.buddyEmpty,
              style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      // Stored cards with no turn to show them in (A23 D13).
      for (final card in thread.orphans)
        ('orphan:${card.id}', UnrestorableCardRow(card: card)),
      for (final turn in thread.turns) ..._turn(context, ref, turn, rows),
    ];
    final indexOf = {for (final (i, item) in items.indexed) item.$1: i};
    return Stack(
      children: [
        ListView.builder(
          controller: controller,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: FbSpace.s4,
            vertical: FbSpace.s2,
          ),
          itemCount: items.length,
          // Keyed: an item keeps its state when others arrive before it.
          findChildIndexCallback: (key) =>
              key is ValueKey<String> ? indexOf[key.value] : null,
          itemBuilder: (context, i) => KeyedSubtree(
            key: ValueKey(items[i].$1),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: FbSpace.s1,
              ),
              child: items[i].$2,
            ),
          ),
        ),
        // A67: something new below while the reader is scrolled up.
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: FbSpace.s2,
          child: Center(
            child: FbReveal(
              visible: _unseen,
              child: FbButton.primary(
                key: BuddyMessageList.newMessagesKey,
                label: l10n.newMessages,
                icon: FbIcons.expand,
                onPressed: () {
                  setState(() => _unseen = false);
                  unawaited(_toEnd());
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<(String, Widget)> _turn(
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
    final running = turn.phase == BuddyTurnPhase.sending;
    final controller = ref.read(buddyThreadControllerProvider.notifier);
    final thread = ref.read(buddyThreadControllerProvider);
    final last = thread.turns.lastOrNull?.userMessageId == turn.userMessageId;
    final applicable = turn.applicableCount;
    final trace = ref.watch(buddyTraceEnabledProvider);
    Widget buddyBubble(String text) => FbMessageBubble(
      text: text,
      fromUser: false,
      semanticLabel: l10n.buddyBubbleBuddy(text),
      // Who is talking, as on the canvas (A44); decorative.
      leading: const FbBuddyAvatar(size: 24),
    );
    return [
      (
        'user:${turn.userMessageId}',
        FbMessageBubble(
          text: userText,
          fromUser: true,
          textDirection: messageDirection(userText),
          semanticLabel: l10n.buddyBubbleYou(userText),
        ),
      ),
      // A card's holder row (it has a budget) is never a bubble (A66 D5);
      // nor is the plain "here's your meal" line above its cards.
      if (reply != null &&
          reply.budgetJson == null &&
          !(turn.cards.isNotEmpty && reply.draft.text == l10n.buddyReplyCards))
        ('reply:${reply.id}', buddyBubble(reply.draft.text))
      // The reply as it streams in (AI-170).
      else if (running && turn.replyText.trim().isNotEmpty)
        ('stream:${turn.userMessageId}', buddyBubble(turn.replyText)),
      // The live step and Stop while Buddy works (AI-170, AI-171).
      if (running)
        (
          'step:${turn.userMessageId}',
          _StepLine(
            text: stepText(l10n, turn.step),
            onStop: () => controller.stop(turn.userMessageId),
          ),
        ),
      if (running && turn.cards.isEmpty && turn.replyText.trim().isEmpty)
        (
          'working:${turn.userMessageId}',
          FbProposalCard.skeleton(semanticLabel: l10n.buddyWorking),
        ),
      if (turn.phase == BuddyTurnPhase.failed ||
          turn.phase == BuddyTurnPhase.pending)
        (
          'failed:${turn.userMessageId}',
          _Failure(turn: turn, onSearch: onSearch),
        ),
      for (final card in turn.cards) ...[
        (
          'card:${card.id}',
          FoodProposalCard(
            key: _firstCards.putIfAbsent(card.id, GlobalKey.new),
            onSearch: onSearch,
            view: FoodCardView.of(
              card,
              referenceDate: turn.message.time.localDate,
              turnAnswer: turn.interpretation,
            ),
          ),
        ),
        if (card.resolution == CardResolution.open &&
            (card.possibleDuplicate || card.changedMeanwhile))
          (
            'note:${card.id}',
            FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: card.changedMeanwhile
                  ? l10n.buddyChangedMeanwhile
                  : l10n.buddyPossibleDuplicate,
            ),
          ),
      ],
      // Record cards (A67): edits, copies, saved meals, batches, foods,
      // memory and weigh-ins.
      for (final record in turn.records)
        (
          'record:${record.id}',
          RecordProposalCard(
            card: record,
            referenceDate: turn.message.time.localDate,
            onReviewFood: widget.onReviewFood == null
                ? null
                : () {
                    if (controller.prepareFoodForm(record.id)) {
                      widget.onReviewFood!();
                    }
                  },
          ),
        ),
      // Offers and tips after a logged card (AI-065, AI-084).
      for (final notice in turn.notices)
        (
          'notice:${turn.userMessageId}:${notice.id}',
          BuddyNoticeRow(turnId: turn.userMessageId, notice: notice),
        ),
      // Several open cards: log them all, one Undo (AI-162).
      if (applicable >= 2)
        (
          'all:${turn.userMessageId}',
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FbButton.primary(
              label: l10n.buddyApplyAll(applicable),
              icon: FbIcons.check,
              onPressed: () =>
                  unawaited(controller.applyAll(turn.userMessageId)),
            ),
          ),
        ),
      // Buddy's question: a chip is the next message (AI-166).
      if (turn.question case final question? when last && !running)
        (
          'ask:${turn.userMessageId}',
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              for (final option in question.options)
                FbAnswerChip(
                  label: option,
                  onTap: () => unawaited(
                    controller.answer(option, buddyReplyTexts(l10n)),
                  ),
                ),
            ],
          ),
        ),
      // Stored cards that couldn't be reopened (A23 D13).
      for (final card in turn.unrestorable)
        ('lost:${card.id}', UnrestorableCardRow(card: card)),
      // The dev trace (AI-172): dev and owner builds only, local only.
      if (trace && turn.trace.isNotEmpty)
        (
          'trace:${turn.userMessageId}',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbButton.text(
              label: l10n.buddyTrace,
              icon: FbIcons.info,
              onPressed: () => unawaited(showBuddyTrace(context, turn.trace)),
            ),
          ),
        ),
    ];
  }
}

/// The live step's words (AI-170), one ARB text per step code.
String stepText(AppLocalizations l10n, String? code) => switch (code) {
  'searchingFoods' => l10n.buddyStepSearchingFoods,
  'readingDiary' => l10n.buddyStepReadingDiary,
  'readingYourFoods' => l10n.buddyStepReadingYourFoods,
  'readingBody' => l10n.buddyStepReadingBody,
  'readingWorkouts' => l10n.buddyStepReadingWorkouts,
  'readingMemory' => l10n.buddyStepReadingMemory,
  'computing' => l10n.buddyStepComputing,
  'checkingFit' => l10n.buddyStepCheckingFit,
  'writingReply' => l10n.buddyStepWritingReply,
  'summarizing' => l10n.buddyStepSummarizing,
  _ => l10n.buddyStepWorking,
};

/// "Searching foods…" with Stop, while a turn runs.
class _StepLine extends StatelessWidget {
  const new({required this.text, required this.onStop});

  final String text;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              text,
              style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        FbButton.text(
          label: context.l10n.buddyStop,
          icon: FbIcons.close,
          onPressed: onStop,
        ),
      ],
    );
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
    final pending = turn.phase == BuddyTurnPhase.pending;
    final message = pending
        ? l10n.buddyWaitingOnline
        : turn.limited
        ? l10n.buddyFailureRateLimited
        : l10n.buddyFailureServer;
    final controller = ref.read(buddyThreadControllerProvider.notifier);
    return FbInlineBanner(
      kind: pending ? FbInlineBannerKind.offline : FbInlineBannerKind.info,
      message: message,
      actionLabel: pending
          ? l10n.buddyTryNow
          : turn.limited
          ? l10n.buddySearchFoods
          : l10n.buddyTryAgain,
      onAction: pending
          ? () => unawaited(controller.wake(buddyReplyTexts(l10n)))
          : turn.limited
          ? onSearch
          : () => unawaited(
              controller.tryAgain(turn.userMessageId, buddyReplyTexts(l10n)),
            ),
    );
  }
}
