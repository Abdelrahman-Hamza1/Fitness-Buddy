import 'dart:async';
import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_restorer.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_state.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/proposal_write_lane.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:fb_mobile/features/buddy/application/turn/agent_card_writer.dart';
import 'package:fb_mobile/features/buddy/application/turn/buddy_trace.dart';
import 'package:fb_mobile/features/buddy/data/buddy_turn_api.dart';
import 'package:fb_mobile/features/buddy/data/buddy_turn_context_reader.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_repository.dart';
import 'package:fb_mobile/features/buddy/data/phone_tools.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/buddy/data/proposal_repository.dart';
import 'package:fb_mobile/features/buddy/data/turn/buddy_turn_runner.dart';
import 'package:fb_mobile/features/buddy/data/turn/turn_checkpoint.dart';
import 'package:fb_mobile/features/foods/foods.dart' show FoodChoice;
import 'package:fb_mobile/features/settings/settings.dart' show AppSettings;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/features/buddy/application/buddy_thread_state.dart';

part 'buddy_thread_controller.g.dart';

/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// pending cards and waiting messages come back after a restart (A23, A66).
///
/// Orchestrates agent turns (A66: one at a time, the runner, the message
/// queue), card adjustments, single-flight confirm and Apply all, discard
/// and the one undo per confirm. Writes only through the use cases (single
/// writer); a `proposal` event only ever becomes a pending card.
@Riverpod(keepAlive: true)
class BuddyThreadController extends _$BuddyThreadController {
  /// A save in flight, before its turn exists (keeps Send single-flight).
  bool _saving = false;

  /// The thread's one serial write lane (A23 D7, D8): replies, follow-ups,
  /// coalesced adjustments, confirms, discards, rebuilds and undos run here
  /// one after another, each from the latest sessions. New per generation.
  ProposalWriteLane _lane = ProposalWriteLane();

  /// Messages whose session one or more Undos are reverting, with how many:
  /// their cards take no adjustment until the last one is done, so no edit
  /// is lost to a reopened session (A23 D10).
  /// New per generation: an older generation's undo releases only its own.
  Map<String, int> _undoing = {};

  /// This generation's restore, once started (A23 D12: idempotent).
  Future<void>? _restored;

  /// Whether the app is past its first frame (the bootstrap restored the
  /// first generation): later generations restore from [build].
  bool _started = false;

  /// The profile generation this thread belongs to (A33 round 4).
  int _generation = 0;

  /// The running turns' runners (one at a time), by turn ID.
  final Map<String, BuddyTurnRunner> _runners = {};

  /// The reply templates the sheet last handed over (A22 D16).
  BuddyReplyTexts? _texts;

  /// Whether the app is in the foreground: the queue runs only then (G2).
  bool _foreground = true;

  /// The queue's retry timer and how many waits it has done (A66 D12).
  Timer? _retry;
  int _waits = 0;
  bool _draining = false;

  /// The backoff between queue attempts (A66 D12).
  static const _backoff = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  /// How long a waiting message is replayed on its own (A23b D17).
  static const _replayFor = Duration(hours: 23);

  /// Whether work started in generation [gen] may still change the thread.
  bool _current(int gen) => ref.mounted && gen == _generation;

  @override
  BuddyThread build() {
    // A profile switch rebuilds the thread empty: no text, card or confirm
    // crosses profiles (A33 round 4).
    _generation = ref.watch(profileGenerationProvider);
    _saving = false;
    _lane = ProposalWriteLane();
    _undoing = {};
    _restored = null;
    // A turn of another profile never writes here (A33).
    for (final runner in _runners.values) {
      runner.stop();
    }
    _runners.clear();
    _retry?.cancel();
    _waits = 0;
    _draining = false;
    if (_started) {
      // A profile switch after the first frame: this profile's cards come
      // back too (A23 D12).
      final gen = _generation;
      unawaited(Future.microtask(() => ensureRestored(gen)));
    }
    // A diary change made elsewhere (the sheet closed, a manual log) moves
    // the open cards' "today after this": refresh them (A22a review). This
    // controller lives for the app process, so it hears changes while the
    // sheet is closed. Its own confirms refresh themselves.
    final changes = ref
        .read(domainEventBusProvider)
        .on<ChangeSetApplied>()
        .where(
          (e) =>
              e.origin is! OriginProposal && e.entities.contains('diaryEntry'),
        )
        .listen((_) => unawaited(_refreshOpenCards()));
    // A34 D17 (A23 handoff): rows pulled from another phone can add or
    // resolve cards; read this profile's pending cards back again (merged
    // by message ID, a turn in memory wins).
    final remote = ref
        .read(domainEventBusProvider)
        .on<RemoteChangesApplied>()
        .where(
          (e) =>
              e.entities.contains('chatMessage') ||
              e.entities.contains('proposal'),
        )
        .listen((_) => unawaited(_restoreAgain()));
    AppLifecycleListener? lifecycle;
    try {
      // Foreground only (G2): a resumed app tries waiting messages again.
      lifecycle = AppLifecycleListener(
        onResume: () {
          _foreground = true;
          unawaited(wake());
        },
        onPause: () {
          _foreground = false;
          _retry?.cancel();
        },
      );
      // No binding (a plain unit test): the sheet and Try now still wake.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
    ref
      ..onDispose(changes.cancel)
      ..onDispose(remote.cancel)
      ..onDispose(() => lifecycle?.dispose())
      ..onDispose(() => _retry?.cancel());
    return const BuddyThread();
  }

  Future<void> _refreshOpenCards() async {
    final gen = _generation;
    final open = state.turns.any(
      (t) => t.cards.any((c) => c.resolution == CardResolution.open),
    );
    if (open) await _refreshOthersSafely('', gen);
  }

  /// Reads this profile's pending cards back into the thread once per
  /// [generation] (A23 D12): after the first frame, the catalog install and
  /// account recovery. Every session with a pending card returns, merged by
  /// message ID (a turn already in memory wins). Never before the first
  /// frame; a stale generation's restore is dropped.
  Future<void> ensureRestored(int generation) {
    _started = true;
    if (!ref.mounted || generation != _generation) return Future.value();
    return _restored ??= _restore(generation)
        .then((_) => _resumeWaiting(generation));
  }

  /// Re-runs the restore after a remote apply, once the first restore of
  /// this generation ran (never before the first frame).
  Future<void> _restoreAgain() {
    if (!_started || !ref.mounted) return Future.value();
    final gen = _generation;
    return _restored = (_restored ?? Future.value()).then(
      (_) => _current(gen) ? _restore(gen) : Future.value(),
    );
  }

  Future<void> _restore(int gen) async {
    try {
      final restorer = ref.read(buddyThreadRestorerProvider);
      final lane = _lane;
      await lane.run(() async {
        final restored = await restorer.restore(generation: gen);
        if (!_current(gen)) return;
        final live = {for (final t in state.turns) t.userMessageId};
        final liveCards = {
          for (final t in state.turns) ...t.cards.map((c) => c.id),
        };
        final added = [
          for (final t in restored.turns)
            if (!live.contains(t.userMessageId))
              t.copyWith(
                cards: [
                  for (final c in t.cards)
                    if (!liveCards.contains(c.id)) c,
                ],
              ),
        ];
        final turns = [...state.turns, ...added]
          ..sort((a, b) {
            final at = a.message.time.occurredAtUtc;
            final bt = b.message.time.occurredAtUtc;
            return at != bt
                ? at.compareTo(bt)
                : a.userMessageId.compareTo(b.userMessageId);
          });
        final shown = {for (final o in state.orphans) o.id};
        state = state.copyWith(
          turns: turns,
          membership: state.membership.merge(restored.membership),
          orphans: [
            ...state.orphans,
            for (final o in restored.orphans)
              if (!shown.contains(o.id)) o,
          ],
        );
      });
      // A restore that fails leaves the thread as it is; cards come back on
      // the next generation or launch.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  SendBuddyMessage get _send => ref.read(sendBuddyMessageProvider);

  ProposalResolution get _resolution => ref.read(proposalResolutionProvider);

  /// Saves [raw] and runs it as a turn (A66): the live step line at once,
  /// cards as they come. Ignored while a turn runs or for blank text; a
  /// message waiting offline is tried first.
  Future<void> send(String raw, BuddyReplyTexts texts) async {
    _texts = texts;
    if (state.sending || _saving || _draining) {
      // One turn at a time: the text goes back to the composer, never lost.
      if (raw.trim().isNotEmpty) {
        state = state.copyWith(composerRestore: raw);
      }
      return;
    }
    final gen = _generation;
    // The use case of this generation (its applier is bound to it).
    final send = _send;
    _saving = true;
    SavedBuddyMessage? message;
    try {
      message = await send.save(raw);
    } on Object {
      message = null;
    } finally {
      if (_current(gen)) _saving = false;
    }
    if (!_current(gen)) return;
    if (message == null) {
      // Not persisted (e.g. the write gate refused during an account
      // transition): the text goes back to the composer (A33 re-check 4).
      if (raw.trim().isNotEmpty && ref.mounted) {
        state = state.copyWith(composerRestore: raw);
      }
      return;
    }
    state = state.copyWith(
      turns: [
        ...state.turns,
        BuddyTurn(message: message, profileGeneration: gen),
      ],
      clearComposer: true,
    );
    await _begin(message.id, gen);
  }

  /// A question chip (AI-166): the chip's text is the next message.
  Future<void> answer(String option, BuddyReplyTexts texts) =>
      send(option, texts);

  /// Try again on a failed turn: its text as a new message (a new turn,
  /// 06 §3.4).
  Future<void> tryAgain(String userMessageId, BuddyReplyTexts texts) async {
    final turn = _turn(userMessageId);
    if (turn == null || turn.phase != BuddyTurnPhase.failed) return;
    await send(turn.message.text, texts);
  }

  /// Stops the running turn [userMessageId] (AI-171): what it was preparing
  /// is never applied; cards already shown stay.
  void stop(String userMessageId) {
    final runner = _runners[userMessageId];
    if (runner == null) return;
    runner.stop();
    // The stop is durable at once (a kill right after Stop never resumes
    // the turn, 06 §3.4); not behind the lane: a card still being prepared
    // there checks the stop right before it commits and writes nothing.
    final gen = _generation;
    unawaited(
      Future(() async {
        if (!_current(gen)) return;
        final messages = ref.read(chatMessageRepositoryProvider);
        final checkpoint = TurnCheckpoint.decode(
          await messages.checkpointOf(userMessageId),
          userMessageId,
        );
        if (checkpoint == null || checkpoint.stopped) return;
        await ref
            .read(changeSetApplierProvider)
            .apply(
              ChangeSet([
                SaveTurnCheckpoint(
                  userMessageId,
                  checkpoint.copyWith(stopped: true).encode(),
                ),
              ], origin: Origin.system),
            );
      }).catchError((Object _) {}),
    );
  }

  /// Whether turn [turnId]'s runner was stopped (checked right before
  /// every card write).
  bool _stoppedTurn(String turnId) => _runners[turnId]?.stopped ?? false;

  /// Tries waiting messages now (sheet opened, app resumed, Try now).
  Future<void> wake([BuddyReplyTexts? texts]) async {
    if (texts != null) _texts = texts;
    _retry?.cancel();
    await _drain(_generation);
  }

  /// The composer's text to restore, once (then cleared).
  String? takeComposerRestore() {
    final text = state.composerRestore;
    if (text != null) {
      state = state.copyWith(clearComposer: true);
    }
    return text;
  }

  /// The open cards a start request lists (`snapshot.openCards`).
  List<OpenCardRef> _openCards() => [
    for (final t in state.turns)
      for (final c in t.cards)
        if (c.resolution == CardResolution.open)
          (
            cardId: c.id,
            revision: c.revision,
            label: AgentCardWriter.labelOf(c.card),
          ),
  ];

  /// Builds turn [turnId]'s start request, marks it `processing` with its
  /// checkpoint and runs it.
  Future<void> _begin(String turnId, int gen) async {
    try {
      final turn = _turn(turnId)!;
      final settings = ref.read(settingsStoreProvider);
      final units = await settings.read(AppSettings.unitSystem);
      final halal = await settings.read(AppSettings.halal);
      final body = await ref
          .read(buddyTurnContextReaderProvider)
          .start(
            turnId: turnId,
            text: turn.message.text,
            now: turn.message.time,
            openCards: _openCards(),
            units: units,
            halal: halal,
            trace: ref.read(buddyTraceEnabledProvider),
          );
      if (!_current(gen)) return;
      final json = jsonDecode(jsonEncode(body.toJson())) as Map<String, Object?>
        ..remove('priorAttempt');
      final checkpoint = TurnCheckpoint.start(
        turnId,
        json,
        createdAtMs: ref.read(clockProvider).nowUtc().millisecondsSinceEpoch,
      );
      if (!await _setStatus(
        turnId,
        ChatMessageStatus.processing,
        checkpoint: checkpoint,
      )) {
        _failed(turnId);
        return;
      }
      await _run(turnId, checkpoint, gen);
      // A throw never leaves the turn running (Send would stay disabled).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      if (_current(gen)) {
        _failed(turnId);
        await _setStatus(turnId, ChatMessageStatus.failed);
      }
    }
  }

  void _failed(String userMessageId) => _update(
    userMessageId,
    (t) => t.copyWith(phase: BuddyTurnPhase.failed, clearStep: true),
  );

  /// Runs turn [turnId] from [checkpoint] and saves how it ended.
  Future<void> _run(
    String turnId,
    TurnCheckpoint checkpoint,
    int gen, {
    bool resumed = false,
  }) async {
    final host = _Host(
      this,
      turnId,
      gen,
      writer: ref.read(agentCardWriterProvider),
      apply: ref.read(changeSetApplierProvider).apply,
    );
    final runner = BuddyTurnRunner(
      host,
      api: ref.read(buddyTurnApiProvider),
      tools: ref.read(phoneToolsProvider),
      today:
          _turn(turnId)?.message.time.localDate ??
          EntryTime.now(ref.read(clockProvider)).localDate,
    );
    _runners[turnId] = runner;
    _update(turnId, (t) => t.copyWith(phase: BuddyTurnPhase.sending));
    TurnEnd end;
    try {
      end = await runner.run(checkpoint, resumed: resumed);
      // Anything unexpected fails the turn (its cards stay).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      end = const TurnEnd(TurnEndKind.failed);
    } finally {
      if (identical(_runners[turnId], runner)) _runners.remove(turnId);
    }
    if (!_current(gen)) return;
    await _finish(turnId, end, gen);
  }

  /// Saves the end of turn [turnId] (A66 D3, D8): the reply row and `done`,
  /// `pending_offline` (the checkpoint kept), or `failed`.
  Future<void> _finish(String turnId, TurnEnd end, int gen) async {
    final turn = _turn(turnId);
    if (turn == null) return;
    switch (end.kind) {
      case TurnEndKind.pending:
        await _setStatus(turnId, ChatMessageStatus.pendingOffline);
        _update(
          turnId,
          (t) => t.copyWith(phase: BuddyTurnPhase.pending, clearStep: true),
        );
        _schedule(gen);
      case TurnEndKind.failed:
      case TurnEndKind.rateLimited:
        await _setStatus(turnId, ChatMessageStatus.failed);
        _update(
          turnId,
          (t) => t.copyWith(
            phase: BuddyTurnPhase.failed,
            limited: end.kind == TurnEndKind.rateLimited,
            clearStep: true,
          ),
        );
      case TurnEndKind.done:
      case TurnEndKind.stopped:
        _waits = 0;
        final texts = _texts;
        final now = _turn(turnId)!;
        final parts = [
          if (now.replyText.trim() case final t when t.isNotEmpty) t,
          if (now.question?.text.trim() case final q? when q.isNotEmpty) q,
        ];
        var body = parts.isEmpty ? null : parts.join('\n\n');
        if (body == null &&
            end.kind == TurnEndKind.done &&
            now.cards.isEmpty &&
            !now.unsupported) {
          body = texts?.noCard;
        }
        if (now.unsupported && texts != null) {
          body = body == null
              ? texts.unsupported
              : '$body ${texts.unsupported}';
        }
        final local = <String, Object?>{
          if (now.question case final q?)
            'question': {'text': q.text, 'options': q.options},
          if (now.trace.isNotEmpty)
            'trace': [for (final step in now.trace) step.toJson()],
        };
        final replyId = body == null
            ? null
            : ref.read(idGeneratorProvider).next();
        final row = await ref.read(chatMessageRepositoryProvider).byId(turnId);
        if (row == null || !_current(gen)) return;
        final answer = local.isEmpty ? null : jsonEncode(local);
        await ref
            .read(changeSetApplierProvider)
            .apply(
              ChangeSet([
                SetChatMessageStatus(
                  row.id,
                  row.version,
                  ChatMessageStatus.done,
                ),
                if (replyId != null)
                  CreateChatMessage(
                    replyId,
                    ChatMessageDraft(
                      role: ChatMessageRole.assistant,
                      text: ChatText.sanitize(body!),
                      status: ChatMessageStatus.done,
                      language: ChatLanguage.english,
                      replyToMessageId: row.id,
                    ),
                    answerJson: answer != null && isLocalJsonObject(answer)
                        ? answer
                        : null,
                  ),
              ], origin: Origin.system),
            );
        if (!_current(gen)) return;
        _update(
          turnId,
          (t) => t.copyWith(
            phase: BuddyTurnPhase.replied,
            // Without a reply text, the first card's holder row stands for
            // the reply (it's never drawn as a bubble).
            assistantMessageId:
                replyId ?? t.cards.firstOrNull?.card.budgetMessageId,
            clearStep: true,
          ),
        );
        // The next waiting message, if any.
        unawaited(_drain(gen));
    }
  }

  /// Moves user row [id] to [status] (with [checkpoint], when given, in the
  /// same change set); whether it was written.
  Future<bool> _setStatus(
    String id,
    ChatMessageStatus status, {
    TurnCheckpoint? checkpoint,
  }) async {
    final row = await ref.read(chatMessageRepositoryProvider).byId(id);
    if (row == null) return false;
    final result = await ref
        .read(changeSetApplierProvider)
        .apply(
          ChangeSet([
            SetChatMessageStatus(row.id, row.version, status),
            if (checkpoint != null) SaveTurnCheckpoint(id, checkpoint.encode()),
          ], origin: Origin.system),
        );
    return result is Applied;
  }

  /// The next queue attempt after a wait (5 s → 15 s → 1 min → 5 min).
  void _schedule(int gen) {
    _retry?.cancel();
    final wait = _backoff[_waits.clamp(0, _backoff.length - 1)];
    _waits++;
    if (!_foreground) return;
    _retry = Timer(wait, () {
      if (_current(gen) && _foreground) unawaited(_drain(gen));
    });
  }

  /// Runs this profile's waiting turns one at a time, oldest first (A66
  /// D12); stops at the first that is still waiting.
  Future<void> _drain(int gen) async {
    if (_draining ||
        state.sending ||
        _saving ||
        !_foreground ||
        !_current(gen)) {
      return;
    }
    _draining = true;
    try {
      final messages = ref.read(chatMessageRepositoryProvider);
      final clock = ref.read(clockProvider);
      // Only this install's rows (A23b D22): another phone's stay its own.
      final device = await ref.read(deviceIdStoreProvider).deviceId();
      final own = {
        for (final (m, owner) in await messages.waiting())
          if (owner == device) m.id,
      };
      for (final turn in [
        for (final t in state.turns)
          if (t.phase == BuddyTurnPhase.pending &&
              own.contains(t.userMessageId))
            t,
      ]) {
        if (!_current(gen)) return;
        final checkpoint = TurnCheckpoint.decode(
          await messages.checkpointOf(turn.userMessageId),
          turn.userMessageId,
        );
        if (checkpoint == null ||
            clock.nowUtc().millisecondsSinceEpoch - checkpoint.createdAtMs >
                _replayFor.inMilliseconds) {
          _failed(turn.userMessageId);
          await _setStatus(turn.userMessageId, ChatMessageStatus.failed);
          continue;
        }
        // Paused meanwhile: the rest waits for the next wake (G2).
        if (!_foreground || !_current(gen)) return;
        await _setStatus(turn.userMessageId, ChatMessageStatus.processing);
        await _run(turn.userMessageId, checkpoint, gen);
        if (_turn(turn.userMessageId)?.phase == BuddyTurnPhase.pending) return;
      }
      // Bookkeeping only: the next wake tries again.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
    } finally {
      if (_current(gen)) _draining = false;
    }
  }

  /// After a restart (once per generation, after the restore): this
  /// install's unfinished turns resume (06 §3.4). A `processing` row with a
  /// checkpoint is the one retry; a waiting one runs from the queue; one
  /// without a checkpoint (a crash before it was prepared) fails once.
  /// Rows from another phone are never touched (A23b D22).
  Future<void> _resumeWaiting(int gen) async {
    try {
      final messages = ref.read(chatMessageRepositoryProvider);
      final device = await ref.read(deviceIdStoreProvider).deviceId();
      final clock = ref.read(clockProvider);
      for (final (row, owner) in await messages.waiting()) {
        if (!_current(gen)) return;
        if (owner != device) continue;
        if (_turn(row.id) == null) {
          state = state.copyWith(
            turns:
                [
                  ...state.turns,
                  BuddyTurn(
                    message: SavedBuddyMessage(
                      id: row.id,
                      text: row.text,
                      time: EntryTime.at(row.createdAt, clock),
                    ),
                    profileGeneration: gen,
                  ),
                ]..sort(
                  (a, b) => a.message.time.occurredAtUtc.compareTo(
                    b.message.time.occurredAtUtc,
                  ),
                ),
          );
        }
        final checkpoint = TurnCheckpoint.decode(
          await messages.checkpointOf(row.id),
          row.id,
        );
        if (checkpoint == null) {
          _failed(row.id);
          await _setStatus(row.id, ChatMessageStatus.failed);
          continue;
        }
        // Every card the turn already made, resolved ones too, so the
        // retry's priorAttempt and the duplicate check see them (review 2).
        await _hydrate(row.id, checkpoint, gen);
        if (checkpoint.stopped) {
          await _finish(row.id, const TurnEnd(TurnEndKind.stopped), gen);
          continue;
        }
        if (row.status == ChatMessageStatus.pendingOffline) {
          _update(row.id, (t) => t.copyWith(phase: BuddyTurnPhase.pending));
          continue;
        }
        // In the background it waits for the next wake (G2); as a
        // processing row it is still the one retry when it runs.
        if (!_foreground) {
          _update(row.id, (t) => t.copyWith(phase: BuddyTurnPhase.pending));
          continue;
        }
        await _run(row.id, checkpoint, gen, resumed: true);
      }
      await _drain(gen);
      // A resume that fails leaves the rows for the next launch.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Reads every card [checkpoint] names back from storage into turn
  /// [turnId] (logged, discarded or open, at the checkpoint's revision).
  Future<void> _hydrate(
    String turnId,
    TurnCheckpoint checkpoint,
    int gen,
  ) async {
    final proposals = ref.read(proposalRepositoryProvider);
    final restorer = ref.read(buddyThreadRestorerProvider);
    for (final c in checkpoint.cards) {
      final turn = _turn(turnId);
      if (!_current(gen) || turn == null) return;
      final shown = _card(c.cardId);
      if (shown != null) {
        if (shown.$2.revision < c.revision) {
          _setCard(
            shown.$1.userMessageId,
            shown.$2.copyWith(revision: c.revision),
          );
        }
        continue;
      }
      final record = await proposals.byId(c.cardId);
      final budget = record?.budgetMessageId;
      if (budget == null) continue;
      final session = (await restorer.session(
        budget,
        referenceTime: turn.message.time,
      )).value;
      final card = session?.cards.where((x) => x.id == c.cardId).firstOrNull;
      if (session == null || card == null || !_current(gen)) continue;
      _update(
        turnId,
        (t) => t.copyWith(
          cards: [
            ...t.cards,
            BuddyCard(
              id: c.cardId,
              session: session,
              revision: c.revision,
              resolution: switch (card.lifecycle) {
                ProposalLifecycle.active => CardResolution.open,
                ProposalLifecycle.confirmed => CardResolution.logged,
                ProposalLifecycle.discarded => CardResolution.discarded,
                ProposalLifecycle.superseded => CardResolution.superseded,
              },
            ),
          ]..sort((a, b) => a.id.compareTo(b.id)),
        ),
      );
    }
  }

  /// Writes a `proposal` event as a pending card (A66 D5–D7): a new card,
  /// or an update of an open card at the revision the event names. Never a
  /// diary op: only a user tap confirms. The new checkpoint, or `null`.
  Future<TurnCheckpoint?> _proposal(
    String turnId,
    TurnProposal proposal,
    TurnCheckpoint Function(CheckpointCard) withCard,
    int gen,
    AgentCardWriter writer,
  ) async {
    final turn = _turn(turnId);
    if (turn == null || !_current(gen)) return null;
    final lane = _lane;
    if (proposal.replaces case final replaces?) {
      final cardId =
          proposal.target?.cardId ??
          (_card(replaces.proposalId) == null ? null : replaces.proposalId);
      if (cardId == null) return null;
      return await lane.run(() async {
        await lane.drain(_writeLatest(_resolution, gen));
        final found = _card(cardId);
        if (!_current(gen) || found == null || _stoppedTurn(turnId)) {
          return null;
        }
        final (owner, card) = found;
        if (card.resolution != CardResolution.open ||
            replaces.expectedRevision != card.revision) {
          // Changed here meanwhile (or resolved): Buddy's update is dropped.
          if (card.resolution == CardResolution.open) {
            _setCard(
              owner.userMessageId,
              card.copyWith(changedMeanwhile: true),
            );
          }
          return null;
        }
        final next = withCard(
          CheckpointCard(
            proposalId: proposal.target?.proposalId ?? replaces.proposalId,
            cardId: cardId,
            revision: proposal.revision,
            round: proposal.target?.round ?? proposal.round,
            attempt: proposal.target?.attempt ?? proposal.attempt,
          ),
        );
        final written = await writer.update(
          card: card.card,
          from: card.session,
          membership: state.membership,
          intent: proposal.intent,
          revision: proposal.revision,
          userId: turnId,
          referenceTime: owner.message.time,
          checkpoint: next.encode(),
          cancelled: () => _stoppedTurn(turnId) || !_current(gen),
        );
        if (written == null || !_current(gen)) return null;
        state = state.copyWith(
          membership: state.membership.followedUp(
            cardId,
            card.card.budgetMessageId,
            written.holderId,
          ),
        );
        _setCard(
          owner.userMessageId,
          BuddyCard(
            id: cardId,
            session: written.session,
            changeToken: Object(),
            removed: card.removed,
            revision: proposal.revision,
            origin: CardOrigin(
              interpretation: written.answer,
              messageId: written.holderId,
              referenceTime: owner.message.time,
            ),
          ),
        );
        return next;
      });
    }
    if (!AgentCardWriter.buildable.contains(proposal.intent['kind'])) {
      _update(turnId, (t) => t.copyWith(unsupported: true));
      return null;
    }
    final cardId = ref.read(idGeneratorProvider).next();
    return await lane.run(() async {
      if (!_current(gen) || _stoppedTurn(turnId)) return null;
      final next = withCard(
        CheckpointCard(
          proposalId: proposal.proposalId,
          cardId: cardId,
          revision: proposal.revision,
          round: proposal.round,
          attempt: proposal.attempt,
        ),
      );
      final written = await writer.create(
        intent: proposal.intent,
        revision: proposal.revision,
        cardId: cardId,
        userId: turnId,
        referenceTime: turn.message.time,
        checkpoint: next.encode(),
        cancelled: () => _stoppedTurn(turnId) || !_current(gen),
      );
      if (!_current(gen)) return null;
      if (written == null) {
        _update(turnId, (t) => t.copyWith(unsupported: true));
        return null;
      }
      final duplicate = _confirmedAlike(turnId, written.card);
      _update(
        turnId,
        (t) => t.copyWith(
          cards: [
            ...t.cards,
            BuddyCard(
              id: cardId,
              session: written.session,
              revision: proposal.revision,
              possibleDuplicate: duplicate,
              origin: CardOrigin(
                interpretation: written.answer,
                messageId: written.holderId,
                referenceTime: t.message.time,
              ),
            ),
          ],
        ),
      );
      return next;
    });
  }

  /// Whether [card]'s food, meal and amounts match a card already logged in
  /// turn [turnId] (06 §3.4 "possible duplicate").
  bool _confirmedAlike(String turnId, ProposalCard card) {
    String key(ProposalCard c) => [
      c.preview.date,
      c.lines.firstOrNull?.entry.slotId,
      ...([
        for (final l in c.lines)
          [
            l.selectedFood?.key ?? l.entry.food.names.en,
            l.entry.amount.input.amount,
            l.entry.amount.input.unitCode,
          ].join(':'),
      ]..sort()),
    ].join('|');
    final mine = key(card);
    final turn = _turn(turnId);
    return turn?.cards.any(
          (c) => c.resolution == CardResolution.logged && key(c.card) == mine,
        ) ??
        false;
  }

  /// Drops the still-pending cards [cardIds] an earlier attempt made (a
  /// retry replaced them, 06 §3.4); logged ones stay.
  Future<void> _supersede(
    String turnId,
    List<String> cardIds,
    int gen,
    AgentCardWriter writer,
  ) async {
    final lane = _lane;
    for (final id in cardIds) {
      await lane.run(() async {
        await lane.drain(_writeLatest(_resolution, gen));
        final found = _card(id);
        if (!_current(gen) ||
            found == null ||
            found.$2.resolution != CardResolution.open) {
          return;
        }
        final done = await writer.supersede(
          found.$2.session,
          id,
          state.membership,
        );
        if (done == null || !_current(gen)) return;
        _update(
          found.$1.userMessageId,
          (t) => t.copyWith(
            cards: [
              for (final c in t.cards)
                if (c.id != id) c,
            ],
          ),
        );
      });
    }
  }

  /// Stores a `summary` event when the stored revision is still the one
  /// the compaction named (06 §6.1); a stale one is dropped.
  Future<void> _summary(
    String summary,
    int revision,
    String watermark,
    int gen,
  ) async {
    if (!_current(gen)) return;
    final text = ChatText.sanitize(summary, limit: BuddySummaryOp.maxText);
    try {
      await ref
          .read(changeSetApplierProvider)
          .apply(
            ChangeSet([
              SaveBuddySummary(
                text: text,
                revision: revision,
                watermark: watermark,
                expectedRevision: revision - 1,
              ),
            ], origin: Origin.system),
          );
      // A refused summary is asked for again by the next compaction.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Clears the conversation summary ("Buddy remembers", AI-165).
  Future<bool> clearSummary() async {
    final result = await ref
        .read(changeSetApplierProvider)
        .apply(ChangeSet([const ClearBuddySummary()], origin: Origin.direct));
    return result is Applied;
  }

  /// Logs every still-open card of turn [userMessageId] as currently shown
  /// in one change set with one Undo (AI-162). Only cards still pending at
  /// their current revision are applied; nothing else is touched.
  Future<void> applyAll(String userMessageId) async {
    final turn = _turn(userMessageId);
    final gen = _generation;
    if (turn == null || turn.profileGeneration != gen) return;
    final targets = turn.applicable;
    if (targets.length < 2) return;
    final resolution = _resolution;
    final lane = _lane;
    for (final c in targets) {
      _setCard(
        userMessageId,
        c.copyWith(resolution: CardResolution.confirming, couldNotLog: false),
      );
    }
    final ids = {for (final c in targets) c.id};
    try {
      await lane.run(() async {
        await lane.drain(_writeLatest(resolution, gen));
        if (!_current(gen)) return;
        final latest = [
          for (final id in ids)
            if (_card(id)?.$2 case final c?
                when c.resolution == CardResolution.confirming &&
                    c.card.canConfirm)
              c,
        ];
        final outcome = latest.length < 2
            ? null
            : await resolution.confirmAll(
                [for (final c in latest) (c.session, c.id)],
                _origin(turn).referenceTime,
                membership: state.membership,
              );
        if (!_current(gen)) return;
        if (outcome == null) {
          for (final id in ids) {
            final now = _card(id)?.$2;
            if (now != null && now.resolution == CardResolution.confirming) {
              _setCard(
                userMessageId,
                now.copyWith(
                  resolution: CardResolution.open,
                  couldNotLog: latest.length >= 2,
                ),
              );
            }
          }
          return;
        }
        for (final c in latest) {
          final session = outcome.sessions[c.id] ?? c.session;
          final before = c.card;
          _replaceSession(turn, c.session, session, null);
          _setCard(
            userMessageId,
            _card(c.id)!.$2.copyWith(
              resolution: CardResolution.logged,
              undoEntryId: outcome.undoEntryId,
              resolvedFrom: c.session,
              logged: LoggedSummary(
                kcal: before.totals.kcal,
                preview:
                    session.cards
                        .where((x) => x.id == c.id)
                        .firstOrNull
                        ?.preview ??
                    before.preview,
                estimate: before.lines.any(
                  (l) => l.range != null || l.entry.food.provenance.isEstimate,
                ),
                loggedAt: outcome.appliedAt,
              ),
            ),
          );
        }
      });
      // A throw never leaves cards "confirming".
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      for (final id in ids) {
        final now = _card(id)?.$2;
        if (now != null && now.resolution == CardResolution.confirming) {
          _setCard(
            userMessageId,
            now.copyWith(resolution: CardResolution.open, couldNotLog: true),
          );
        }
      }
      return;
    }
    if (_current(gen)) await _refreshOthersSafely('', gen);
  }

  /// Applies a chip/answer [adjustment] to open card [cardId] and recomputes
  /// its session; nothing is written (AI-033, AI-034, AI-036).
  void adjust(String cardId, ProposalAdjustment adjustment) {
    final found = _card(cardId);
    if (found == null ||
        found.$2.resolution != CardResolution.open ||
        _undoing.containsKey(SessionMembership.messageOf(found.$2.session))) {
      return;
    }
    final update = ProposalEngine.recompute(found.$2.session, adjustment).value;
    if (update == null) return;
    // A coalesced latest-wins write, flushed on dismiss, pause, or before a
    // confirm or discard (A23 D8).
    if (!update.diff.isEmpty) {
      if (SessionMembership.messageOf(update.session) case final message?) {
        _lane.schedule(message);
      }
    }
    _replaceSession(found.$1, found.$2.session, update.session, update.diff);
    // A change made here outranks Buddy's pending update of the card
    // (A66 D6): its next revision is what an update must name.
    if (!update.diff.isEmpty) {
      final now = _card(cardId);
      if (now != null) {
        _setCard(
          now.$1.userMessageId,
          now.$2.copyWith(revision: now.$2.revision + 1),
        );
      }
    }
  }

  /// − / + on an assumed amount (AI-040, A22b E3): the next amount from
  /// [AmountStep], recomputed by the engine. Nothing is written.
  void stepAmount(String cardId, String lineId, {required bool up}) {
    final line = _line(cardId, lineId);
    if (line == null) return;
    final current = line.entry.amount.input;
    final next = up ? AmountStep.up(current) : AmountStep.down(current);
    if (next == null) return;
    adjust(cardId, ProposalSetAmount(lineId, next));
  }

  /// Sets line [lineId]'s amount to [quantity] from the inline number pad
  /// and unit chips (AI-040); the engine recomputes. Nothing is written.
  void setAmount(String cardId, String lineId, Quantity quantity) {
    if (quantity.amount <= 0 || _line(cardId, lineId) == null) return;
    adjust(cardId, ProposalSetAmount(lineId, quantity));
  }

  /// Swaps line [lineId]'s food for [food] (an alternative or a food picked
  /// in search, AI-041).
  void swapFood(String cardId, String lineId, ProposalFood food) {
    if (_line(cardId, lineId) == null) return;
    adjust(cardId, ProposalSwap(lineId, food));
  }

  /// Adds [food] at [quantity] to open card [cardId] ("Add item", AI-042):
  /// a new line with its own ID, computed by the engine.
  void addFood(String cardId, ProposalFood food, Quantity quantity) {
    if (quantity.amount <= 0) return;
    final ids = ref.read(idGeneratorProvider);
    adjust(
      cardId,
      ProposalAdd(
        cardId,
        ids.next(),
        ProposalItem(
          id: 'add',
          displayName: food.names.en,
          match: food,
          quantity: quantity,
          explicit: true,
          alternatives: const [],
          dimensions: const [],
        ),
        GeneratorProposalIds(ids),
      ),
    );
  }

  /// Swaps line [lineId] for the food [choice] picked in food search
  /// (AI-041); a choice that's neither a catalog nor a personal food
  /// changes nothing.
  void swapPicked(String cardId, String lineId, FoodChoice choice) {
    final food = ProposalInputLoader.proposalFoodOf(choice);
    if (food != null) swapFood(cardId, lineId, food);
  }

  /// Adds the food [choice] picked in food search at [quantity] (AI-042).
  void addPicked(String cardId, FoodChoice choice, Quantity quantity) {
    final food = ProposalInputLoader.proposalFoodOf(choice);
    if (food != null) addFood(cardId, food, quantity);
  }

  /// Swipes line [lineId] off open card [cardId] (AI-042); the card offers
  /// "Removed … · Undo" ([restoreLine]).
  void removeLine(String cardId, String lineId) {
    final line = _line(cardId, lineId);
    if (line == null) return;
    adjust(cardId, ProposalSetRemoved(lineId, removed: true));
    final found = _card(cardId);
    if (found == null || found.$2.card.lines.any((l) => l.entry.id == lineId)) {
      return;
    }
    _setCard(
      found.$1.userMessageId,
      found.$2.copyWith(
        removed: [
          ...found.$2.removed,
          RemovedLine(lineId, line.entry.food.names),
        ],
      ),
    );
  }

  /// Puts back a line removed from open card [cardId].
  void restoreLine(String cardId, String lineId) {
    final found = _card(cardId);
    if (found == null || !found.$2.removed.any((r) => r.id == lineId)) return;
    adjust(cardId, ProposalSetRemoved(lineId, removed: false));
    final now = _card(cardId);
    if (now == null || !now.$2.card.lines.any((l) => l.entry.id == lineId)) {
      return;
    }
    _setCard(
      now.$1.userMessageId,
      now.$2.copyWith(
        removed: [
          for (final r in now.$2.removed)
            if (r.id != lineId) r,
        ],
      ),
    );
  }

  /// Moves open card [cardId] to meal [slotId] (AI-043).
  void setSlot(String cardId, String slotId) =>
      adjust(cardId, ProposalSetWhen(cardId, slotId: slotId));

  /// Moves open card [cardId] to [time] on its day, in its own offset
  /// (AI-043).
  void setTime(String cardId, LocalTime time) {
    final found = _card(cardId);
    final when = found?.$2.card.lines.firstOrNull?.entry.when;
    if (when is! EntryAt) return;
    final current = when.time;
    adjust(
      cardId,
      ProposalSetWhen(
        cardId,
        time: EntryTime.local(time.on(current.localDate), current.tzOffsetMin),
      ),
    );
  }

  ProposalLine? _line(String cardId, String lineId) =>
      _card(cardId)?.$2.card.lines
          .where((l) => l.entry.id == lineId)
          .firstOrNull;

  /// Logs card [cardId] (one tap, UX-003). Single-flight: a second call
  /// while one applies, or for a card that can't be confirmed, does nothing.
  /// Runs as a lane job from the card's latest session, after any pending
  /// adjustment write (A23 D7, D8).
  Future<void> confirm(String cardId) async {
    final found = _card(cardId);
    if (found == null) return;
    final (turn, card) = found;
    if (card.resolution != CardResolution.open || !card.card.canConfirm) {
      return;
    }
    final gen = _generation;
    if (turn.profileGeneration != gen) return;
    // The use cases and lane of this generation (A33).
    final resolution = _resolution;
    final lane = _lane;
    _setCard(
      turn.userMessageId,
      card.copyWith(resolution: CardResolution.confirming, couldNotLog: false),
    );
    var logged = false;
    try {
      await lane.run(() async {
        await lane.drain(_writeLatest(resolution, gen));
        final latest = _card(cardId)?.$2;
        if (!_current(gen) || latest == null) return;
        final before = latest.card;
        final outcome = await resolution.confirm(
          latest.session,
          cardId,
          latest.origin ?? _origin(turn),
          membership: state.membership,
        );
        if (!_current(gen)) return;
        logged = _onConfirmed(turn, latest, before, outcome);
      });
      // A throw never leaves the card "confirming": it's open again with
      // "Couldn't log this card." (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      if (!_current(gen)) return;
      final now = _card(cardId)?.$2;
      if (now != null && now.resolution == CardResolution.confirming) {
        _setCard(
          turn.userMessageId,
          now.copyWith(resolution: CardResolution.open, couldNotLog: true),
        );
      }
      return;
    }
    if (logged && _current(gen)) await _refreshOthersSafely(cardId, gen);
  }

  /// The thread after confirm [outcome] of [card] (whose card was
  /// [before]); whether it was logged.
  bool _onConfirmed(
    BuddyTurn turn,
    BuddyCard card,
    ProposalCard before,
    ConfirmOutcome outcome,
  ) {
    final cardId = card.id;
    switch (outcome) {
      case CardLogged(:final session, :final undoEntryId, :final appliedAt):
        // The day as it is now, from the refreshed session (confirmed
        // intake with this card in it), not the card's pre-confirm preview.
        final after =
            session.cards.where((c) => c.id == cardId).firstOrNull?.preview ??
            before.preview;
        _replaceSession(
          turn,
          _card(cardId)!.$2.session,
          _rebased(card.session, session, cardId, ProposalLifecycle.confirmed),
          null,
        );
        _setCard(
          turn.userMessageId,
          _card(cardId)!.$2.copyWith(
            resolution: CardResolution.logged,
            undoEntryId: undoEntryId,
            resolvedFrom: card.session,
            logged: LoggedSummary(
              kcal: before.totals.kcal,
              preview: after,
              estimate: before.lines.any(
                (l) => l.range != null || l.entry.food.provenance.isEstimate,
              ),
              loggedAt: appliedAt,
            ),
          ),
        );
        return true;
      case CardRebuilt(
        :final session,
        :final messageId,
        :final from,
        :final interpretation,
      ):
        // Rebuilt with current facts into its own message (A23 D11).
        if (messageId != null && from != null) {
          state = state.copyWith(
            membership: state.membership.rebuilt(cardId, from),
          );
        }
        final origin = card.origin ?? _origin(turn);
        _setCard(
          turn.userMessageId,
          BuddyCard(
            id: cardId,
            session: session,
            removed: card.removed,
            rebuilt: messageId != null,
            origin: messageId == null
                ? card.origin
                : CardOrigin(
                    interpretation: interpretation ?? origin.interpretation,
                    messageId: messageId,
                    referenceTime: origin.referenceTime,
                  ),
          ),
        );
        return false;
      case CardNotLogged():
        _setCard(
          turn.userMessageId,
          _card(cardId)!.$2
              .copyWith(resolution: CardResolution.open, couldNotLog: true),
        );
        return false;
    }
  }

  /// The session to show after [cardId] was resolved to [lifecycle] from
  /// [from] (giving [resolved]): when a sibling was adjusted meanwhile
  /// (the shared session moved on), the resolution is applied to that newer
  /// session instead, so neither is lost (A23 D7, PA1); its pending write
  /// stores both.
  ProposalSession _rebased(
    ProposalSession from,
    ProposalSession resolved,
    String cardId,
    ProposalLifecycle lifecycle,
  ) {
    final current = _card(cardId)?.$2.session;
    if (current == null || identical(current, from)) return resolved;
    return ProposalEngine.recompute(
          current,
          ProposalSetLifecycle(cardId, lifecycle),
        ).value?.session ??
        resolved;
  }

  /// Writes a message's latest session whole (a coalesced job, A23 D7):
  /// `false` when it was refused (a newer stored revision).
  Future<bool> Function(String) _writeLatest(
    ProposalResolution resolution,
    int gen,
  ) => (messageId) async {
    if (!_current(gen)) return false;
    final session = _latestSession(messageId);
    if (session == null) return true;
    final written = await resolution.persist(session, state.membership);
    // The adjusted cards' revisions go with their holders (A66 D6).
    var revision = 1;
    for (final t in state.turns) {
      for (final c in t.cards) {
        if (identical(c.session, session) && c.revision > revision) {
          revision = c.revision;
        }
      }
    }
    if (written && revision > 1 && _current(gen)) {
      await ref
          .read(changeSetApplierProvider)
          .apply(
            ChangeSet([
              SaveCardRevision(messageId, revision),
            ], origin: Origin.system),
          );
    }
    return written;
  };

  /// The newest in-memory session of message [messageId], if any card
  /// shows it.
  ProposalSession? _latestSession(String messageId) {
    for (final turn in state.turns) {
      for (final card in turn.cards) {
        if (SessionMembership.messageOf(card.session) == messageId) {
          return card.session;
        }
      }
    }
    return null;
  }

  /// Writes every adjusted session now (A23 D8): when the sheet is
  /// dismissed or the app pauses.
  Future<void> flush() async {
    // Nothing adjusted: no write, and no use case is even read.
    if (!_lane.hasPending) return;
    final gen = _generation;
    try {
      await _lane.flush(_writeLatest(_resolution, gen));
      // Bookkeeping only; the next change schedules the write again.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Discards open card [cardId]; nothing is logged (AI-037). The discard is
  /// one undoable change set (A23 D10), a lane job like a confirm.
  Future<void> discard(String cardId) async {
    final found = _card(cardId);
    if (found == null || found.$2.resolution != CardResolution.open) {
      return;
    }
    final gen = _generation;
    if (found.$1.profileGeneration != gen) return;
    final resolution = _resolution;
    final lane = _lane;
    final clock = ref.read(clockProvider);
    try {
      await lane.run(() async {
        await lane.drain(_writeLatest(resolution, gen));
        final latest = _card(cardId)?.$2;
        if (!_current(gen) ||
            latest == null ||
            latest.resolution != CardResolution.open) {
          return;
        }
        final outcome = await resolution.discard(
          latest.session,
          cardId,
          membership: state.membership,
        );
        if (outcome == null || !_current(gen)) return;
        final turn = _turn(found.$1.userMessageId)!;
        _replaceSession(
          turn,
          _card(cardId)!.$2.session,
          _rebased(
            latest.session,
            outcome.session,
            cardId,
            ProposalLifecycle.discarded,
          ),
          null,
        );
        _setCard(
          turn.userMessageId,
          _card(cardId)!.$2.copyWith(
            resolution: CardResolution.discarded,
            undoEntryId: outcome.undoEntryId,
            resolvedFrom: latest.session,
            discardedAt: outcome.appliedAt ?? clock.nowUtc(),
          ),
        );
      });
      // A throw leaves the card open (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return;
    }
  }

  /// Rebuilds stale restored card [cardId] with the current food details
  /// from its stored answer, offline, into its own message (A23 D11, D13:
  /// "Update card"). Nothing happens without a stored answer.
  Future<void> updateCard(String cardId) async {
    final found = _card(cardId);
    if (found == null ||
        found.$2.resolution != CardResolution.open ||
        found.$1.profileGeneration != _generation) {
      return;
    }
    final gen = _generation;
    final resolution = _resolution;
    final lane = _lane;
    try {
      await lane.run(() async {
        await lane.drain(_writeLatest(resolution, gen));
        final latest = _card(cardId);
        if (!_current(gen) || latest == null) return;
        final origin = latest.$2.origin ?? _origin(latest.$1);
        if (origin.interpretation.isEmpty) return;
        final rebuilt = await resolution.rebuild(
          latest.$2.session,
          cardId,
          origin,
          membership: state.membership,
        );
        if (!_current(gen) || rebuilt == null) return;
        _onConfirmed(latest.$1, latest.$2, latest.$2.card, rebuilt);
      });
      // A failure leaves the card as it is.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Discards stored card [recordId] that couldn't be reopened (A23 D13):
  /// its row alone, undoable.
  Future<void> discardUnrestorable(String recordId) async {
    final found = _unrestorable(recordId);
    if (found == null || found.$2.discarded) return;
    final gen = _generation;
    final resolution = _resolution;
    try {
      await _lane.run(() async {
        final done = await resolution.discardRecord(found.$2.record);
        if (done == null || !_current(gen)) return;
        _setUnrestorable(
          found.$1,
          UnrestorableCard(
            record: found.$2.record,
            issue: found.$2.issue,
            undoEntryId: done.$1,
            discardedAt: done.$2,
          ),
        );
      });
      // A failure leaves the placeholder as it is.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Undoes the discard of placeholder [recordId].
  Future<void> restoreUnrestorable(String recordId) async {
    final found = _unrestorable(recordId);
    final entry = found?.$2.undoEntryId;
    if (found == null || entry == null) return;
    final gen = _generation;
    final resolution = _resolution;
    try {
      await _lane.run(() async {
        final outcome = await resolution.undo(entry);
        if (!_current(gen)) return;
        _setUnrestorable(
          found.$1,
          UnrestorableCard(
            record: found.$2.record,
            issue: found.$2.issue,
            discardedAt: outcome == UndoOutcome.undone
                ? null
                : found.$2.discardedAt,
          ),
        );
      });
      // A failure leaves the placeholder discarded.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Placeholder [recordId] and the turn that shows it (`null` for an
  /// orphan shown above the turns).
  (BuddyTurn?, UnrestorableCard)? _unrestorable(String recordId) {
    for (final card in state.orphans) {
      if (card.id == recordId) return (null, card);
    }
    for (final turn in state.turns) {
      for (final card in turn.unrestorable) {
        if (card.id == recordId) return (turn, card);
      }
    }
    return null;
  }

  void _setUnrestorable(BuddyTurn? turn, UnrestorableCard card) {
    List<UnrestorableCard> swap(List<UnrestorableCard> cards) => [
      for (final c in cards)
        if (c.id == card.id) card else c,
    ];
    if (turn == null) {
      state = state.copyWith(orphans: swap(state.orphans));
    } else {
      _update(
        turn.userMessageId,
        (t) => t.copyWith(unrestorable: swap(t.unrestorable)),
      );
    }
  }

  /// Undoes the Discard of [cardId] (backlog #142, A23 D10): its change set
  /// is reverted and the card opens again as stored.
  Future<UndoOutcome?> restoreDiscarded(String cardId) =>
      _undoResolution(cardId, CardResolution.discarded);

  /// Undoes logged card [cardId] once (D25, A23 D10): the whole confirm is
  /// reverted and the card opens again with Log it, read back from the
  /// database. Refused (a row changed since, or too late): it stays logged.
  Future<UndoOutcome?> undo(String cardId) =>
      _undoResolution(cardId, CardResolution.logged);

  Future<UndoOutcome?> _undoResolution(
    String cardId,
    CardResolution resolved,
  ) async {
    final found = _card(cardId);
    final entry = found?.$2.undoEntryId;
    if (found == null ||
        entry == null ||
        found.$2.resolution != resolved ||
        found.$1.profileGeneration != _generation) {
      return null;
    }
    final gen = _generation;
    // The use cases and lane of this generation (A33).
    final resolution = _resolution;
    final restorer = ref.read(buddyThreadRestorerProvider);
    final lane = _lane;
    final message = SessionMembership.messageOf(
      found.$2.resolvedFrom ?? found.$2.session,
    );
    final undoing = _undoing;
    if (message != null) {
      undoing.update(message, (n) => n + 1, ifAbsent: () => 1);
    }
    try {
      final outcome = await lane.run(
        () => _revert(cardId, entry, found.$1, resolution, restorer, lane, gen),
      );
      if (outcome == UndoOutcome.undone && _current(gen)) {
        await _refreshOthersSafely(cardId, gen);
      }
      return outcome;
      // A throw leaves the card resolved with its Undo (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    } finally {
      if (message != null) {
        final left = (undoing[message] ?? 0) - 1;
        if (left > 0) {
          undoing[message] = left;
        } else {
          undoing.remove(message);
        }
      }
    }
  }

  /// The lane job of an Undo: the revert, then the card read back.
  Future<UndoOutcome?> _revert(
    String cardId,
    String entry,
    BuddyTurn found,
    ProposalResolution resolution,
    BuddyThreadRestorer restorer,
    ProposalWriteLane lane,
    int gen,
  ) async {
    // A stale generation's undo touches no lane, its own or the new one's.
    if (!_current(gen)) return null;
    // Any adjustment made since is written first, so a sibling changed
    // after the resolve makes the revert refuse (A23 D7, D10).
    await lane.drain(_writeLatest(resolution, gen));
    if (!_current(gen)) return null;
    final outcome = await resolution.undo(entry);
    if (!_current(gen)) return null;
    final now = _card(cardId)!.$2;
    if (outcome != UndoOutcome.undone) {
      _setCard(
        found.userMessageId,
        BuddyCard(
          id: cardId,
          session: now.session,
          diff: now.diff,
          logged: now.logged,
          resolution: now.resolution,
          undoRefused: outcome,
          origin: now.origin,
          discardedAt: now.discardedAt,
          rebuilt: now.rebuilt,
        ),
      );
      return outcome;
    }
    // Apply all logged several cards under this one entry (AI-162): every
    // one of them opens again.
    final group = [
      for (final t in state.turns)
        for (final c in t.cards)
          if (c.undoEntryId == entry && c.id != cardId) (t, c),
    ];
    await _reopen(cardId, found, now, restorer, gen);
    for (final (t, c) in group) {
      if (!_current(gen)) break;
      await _reopen(c.id, t, c, restorer, gen);
    }
    return outcome;
  }

  /// Opens card [cardId] (shown as [now] in turn [found]) again after its
  /// confirm or discard was reverted, from the database when it can be read.
  Future<void> _reopen(
    String cardId,
    BuddyTurn found,
    BuddyCard now,
    BuddyThreadRestorer restorer,
    int gen,
  ) async {
    // The database is the truth after a revert: the card's session as
    // stored now (the card pending again).
    final message = SessionMembership.messageOf(
      now.resolvedFrom ?? now.session,
    );
    ProposalSession? stored;
    if (message != null) {
      stored = (await restorer.session(
        message,
        referenceTime: found.message.time,
      )).value;
    }
    if (!_current(gen)) return;
    // The stored rows equal the session before the resolve (it was written
    // first): when their facts can't be verified here (a food not in this
    // phone's pack), that in-memory session reopens instead.
    bool confirmable(ProposalSession? s) =>
        s?.cards.any((c) => c.id == cardId && c.canConfirm) ?? false;
    final reopened = confirmable(stored) || now.resolvedFrom == null
        ? stored
        : now.resolvedFrom;
    final turn = _turn(found.userMessageId);
    if (turn != null &&
        reopened != null &&
        reopened.cards.any(
          (c) => c.id == cardId && c.lifecycle == ProposalLifecycle.active,
        )) {
      _replaceSession(turn, now.session, reopened, null);
      _setCard(
        turn.userMessageId,
        BuddyCard(
          id: cardId,
          session: reopened,
          origin: now.origin,
          removed: now.removed,
          rebuilt: now.rebuilt,
          revision: now.revision,
        ),
      );
    }
  }

  /// [_refreshOthers], where a failure only leaves sibling previews as they
  /// were: the logged card and its Undo are already shown.
  Future<void> _refreshOthersSafely(String cardId, int gen) async {
    try {
      await _refreshOthers(cardId, gen);
      // Any failure here is only a stale preview.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Previews refresh on the next change.
    }
  }

  /// Recomputes every other open card's session with a fresh context, so
  /// its "today after this" counts confirmed intake once (D12).
  Future<void> _refreshOthers(String cardId, int gen) async {
    final seen = <ProposalSession>{};
    for (final turn in state.turns) {
      for (final card in turn.cards) {
        if (card.id == cardId || !seen.add(card.session)) continue;
        final refreshed = await _resolution.refresh(
          card.session,
          turn.message.time,
        );
        if (!_current(gen)) return;
        if (!identical(refreshed, card.session)) {
          _replaceSession(
            _turn(turn.userMessageId)!,
            card.session,
            refreshed,
            null,
          );
        }
      }
    }
  }

  CardOrigin _origin(BuddyTurn turn) => CardOrigin(
    interpretation: turn.interpretation ?? const {},
    messageId: turn.assistantMessageId ?? turn.userMessageId,
    referenceTime: turn.message.time,
  );

  BuddyTurn? _turn(String userMessageId) =>
      state.turns.where((t) => t.userMessageId == userMessageId).firstOrNull;

  (BuddyTurn, BuddyCard)? _card(String cardId) {
    for (final turn in state.turns) {
      for (final card in turn.cards) {
        if (card.id == cardId) return (turn, card);
      }
    }
    return null;
  }

  void _update(String userMessageId, BuddyTurn Function(BuddyTurn) change) {
    state = state.copyWith(
      turns: [
        for (final t in state.turns)
          if (t.userMessageId == userMessageId) change(t) else t,
      ],
    );
  }

  void _setCard(String userMessageId, BuddyCard card) => _update(
    userMessageId,
    (t) => t.copyWith(
      cards: [
        for (final c in t.cards)
          if (c.id == card.id) card else c,
      ],
    ),
  );

  /// Moves every card of [turn] owned by [from] to [to].
  void _replaceSession(
    BuddyTurn turn,
    ProposalSession from,
    ProposalSession to,
    ProposalDiff? diff,
  ) => _update(
    turn.userMessageId,
    (t) => t.copyWith(
      cards: [
        for (final c in t.cards)
          if (identical(c.session, from) &&
              to.cards.any((card) => card.id == c.id))
            c.copyWith(
              session: to,
              diff: diff,
              changeToken: diff == null ? null : Object(),
            )
          else
            c,
      ],
    ),
  );
}

/// The thread side of one running turn (A66): live display into the
/// thread, writes through the generation's use cases (bound when the turn
/// starts, so a profile switch never writes into another profile), and
/// phone tools. Everything is dropped once the generation changed.
final class _Host implements TurnHost {
  new(
    this._thread,
    this._turnId,
    this._gen, {
    required this._writer,
    required this._apply,
  });

  final BuddyThreadController _thread;
  final String _turnId;
  final int _gen;
  final AgentCardWriter _writer;
  final Future<ApplyResult> Function(ChangeSet) _apply;

  bool get _live => _thread._current(_gen);

  void _update(BuddyTurn Function(BuddyTurn) change) {
    if (_live) _thread._update(_turnId, change);
  }

  @override
  Future<void> save(TurnCheckpoint checkpoint) async {
    if (!_live) return;
    await _apply(
      ChangeSet([
        SaveTurnCheckpoint(_turnId, checkpoint.encode()),
      ], origin: Origin.system),
    );
  }

  @override
  void step(String code) => _update((t) => t.copyWith(step: code));

  @override
  void text(String chunk) =>
      _update((t) => t.copyWith(replyText: t.replyText + chunk));

  @override
  void resetText() => _update((t) => t.copyWith(replyText: ''));

  @override
  void question(String text, List<String> options) => _update(
    (t) => t.copyWith(question: BuddyQuestion(text, options.take(4).toList())),
  );

  @override
  void trace(List<TraceLine> steps) => _update(
    (t) => t.copyWith(
      trace: [
        ...t.trace,
        for (final s in steps)
          TraceStepView(
            tool: s.tool,
            args: s.args,
            resultSummary: s.resultSummary,
            ms: s.ms,
            tokens: s.tokens,
            usd: s.usd,
          ),
      ],
    ),
  );

  @override
  Future<TurnCheckpoint?> proposal(
    TurnProposal proposal,
    TurnCheckpoint Function(CheckpointCard card) withCard,
  ) async => _live
      ? await _thread._proposal(_turnId, proposal, withCard, _gen, _writer)
      : null;

  @override
  Future<void> supersede(List<String> cardIds) async {
    if (_live) await _thread._supersede(_turnId, cardIds, _gen, _writer);
  }

  @override
  ({PriorCardState status, String line, int revision})? priorCard(
    String cardId,
  ) {
    final found = _thread._card(cardId);
    if (found == null) return null;
    final card = found.$2;
    return (
      status: switch (card.resolution) {
        CardResolution.logged => PriorCardState.confirmed,
        CardResolution.discarded ||
        CardResolution.superseded => PriorCardState.discarded,
        CardResolution.open ||
        CardResolution.confirming => PriorCardState.pending,
      },
      line: AgentCardWriter.labelOf(card.card),
      revision: card.revision,
    );
  }

  @override
  Future<void> summary(String text, int revision, String watermark) =>
      _thread._summary(text, revision, watermark, _gen);

  @override
  String toString() => '_Host($_turnId)';
}
