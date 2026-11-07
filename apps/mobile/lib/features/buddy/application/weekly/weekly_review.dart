import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/buddy/application/turn/turn_ramadan.dart';
import 'package:fb_mobile/features/buddy/data/buddy_phone_reads.dart';
import 'package:fb_mobile/features/buddy/data/buddy_turn_api.dart';
import 'package:fb_mobile/features/buddy/data/buddy_turn_context_reader.dart';
import 'package:fb_mobile/features/buddy/data/phone_tools.dart';
import 'package:fb_mobile/features/buddy/data/turn/buddy_turn_runner.dart';
import 'package:fb_mobile/features/buddy/data/turn/turn_checkpoint.dart';
import 'package:fb_mobile/features/buddy/data/weekly_review_body.dart';
import 'package:fb_mobile/features/settings/settings.dart' show AppSettings;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weekly_review.g.dart';

/// Buddy's review of the week from [weekStart] (AI-130–132, A68 D6), as
/// stored, now and on each change; null until one was written.
@riverpod
Stream<String?> weeklyReview(Ref ref, LocalDate weekStart) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.weeklyReview(weekStart));

/// Where writing a week's review stands in this profile session.
enum WeeklyReviewWriting {
  /// Not tried yet.
  idle,

  /// Buddy is writing it.
  writing,

  /// Written and stored.
  written,

  /// It couldn't be written or stored (offline, unavailable, limit,
  /// quota): only Try again asks again.
  failed,
}

/// Writes the review of the week from its [build] argument at most once
/// per profile session unless the user taps Try again (A68 D6): a
/// `weeklyReview` turn with the week's aggregates only, through the turn
/// runner (no phone tools, no cards). Only an `answered` review is stored,
/// per week in a synced setting (`Origin.system`, no undo: it isn't the
/// user's data to edit). Kept alive for the profile session (reopening the
/// screen never asks again); a profile switch resets it and stops a
/// running turn. The local tiles never wait for it. Nothing here logs.
@Riverpod(keepAlive: true)
class WeeklyReviewWriter extends _$WeeklyReviewWriter {
  BuddyTurnRunner? _runner;
  int _attempt = 0;

  @override
  WeeklyReviewWriting build(LocalDate weekStart) {
    ref.watch(profileGenerationProvider);
    _attempt++;
    ref.onDispose(() {
      _runner?.stop();
      _runner = null;
    });
    return WeeklyReviewWriting.idle;
  }

  /// Writes the review of [summary] (this writer's week) unless it was
  /// already tried this session; [fromKcal]/[toKcal] is this week's pending
  /// check-in (TG-034), attached as facts. [retry] (Try again) asks again
  /// after a failure.
  Future<void> write(
    WeeklySummary summary, {
    double? fromKcal,
    double? toKcal,
    bool retry = false,
  }) async {
    if (summary.start != weekStart || summary.isEmpty) return;
    final allowed =
        state == WeeklyReviewWriting.idle ||
        (retry && state == WeeklyReviewWriting.failed);
    if (!allowed) return;
    final attempt = _attempt;
    bool live() => ref.mounted && attempt == _attempt;
    state = WeeklyReviewWriting.writing;
    var stored = false;
    try {
      final text = await _run(
        summary,
        live: live,
        fromKcal: fromKcal,
        toKcal: toKcal,
      );
      if (text != null && live()) {
        final result = await ref
            .read(settingsStoreProvider)
            .put(
              AppSettings.weeklyReview(weekStart),
              text,
              origin: Origin.system,
            );
        stored = result is Applied;
      }
      // Any failure is "couldn't write it" with Try again.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      stored = false;
    }
    if (!live()) return;
    state = stored ? WeeklyReviewWriting.written : WeeklyReviewWriting.failed;
  }

  /// Runs the review turn while [live] holds (this attempt, this profile):
  /// checked after every await before the request is sent, so a profile
  /// switch during preparation never sends (or pays for) a review.
  Future<String?> _run(
    WeeklySummary summary, {
    required bool Function() live,
    double? fromKcal,
    double? toKcal,
  }) async {
    final turnId = ref.read(idGeneratorProvider).next();
    final clock = ref.read(clockProvider);
    final now = EntryTime.now(clock);
    final settings = ref.read(settingsStoreProvider);
    final reader = ref.read(buddyTurnContextReaderProvider);
    final units = await settings.read(AppSettings.unitSystem);
    if (!live()) return null;
    final halal = await settings.read(AppSettings.halal);
    if (!live()) return null;
    final ramadan = await turnRamadan(ref, now.localDate);
    if (!live()) return null;
    final chat = await reader.start(
      turnId: turnId,
      text: weeklyReviewMessage,
      now: now,
      openCards: const [],
      units: units,
      halal: halal,
      trace: false,
      ramadan: ramadan,
    );
    if (!live()) return null;
    final host = _ReviewHost();
    final runner = BuddyTurnRunner(
      host,
      api: ref.read(buddyTurnApiProvider),
      // No phone tools in this mode (06 §4.2): none are answered.
      tools: PhoneTools(ref.read(buddyPhoneReadsProvider)),
      today: now.localDate,
    );
    _runner = runner;
    final end = await runner.run(
      TurnCheckpoint.start(
        turnId,
        weeklyReviewBody(chat, summary, fromKcal: fromKcal, toKcal: toKcal),
        createdAtMs: clock.nowUtc().millisecondsSinceEpoch,
      ),
    );
    if (identical(_runner, runner)) _runner = null;
    final text = host.written.trim();
    // Only a review Buddy finished: a limit or quota end may carry just a
    // header or a template, which would hide Try again for good.
    return end.kind == TurnEndKind.done &&
            end.reason == 'answered' &&
            text.isNotEmpty
        ? (text.length > 4000 ? text.substring(0, 4000) : text)
        : null;
  }
}

/// The in-memory side of a review turn: only the guarded text is kept.
final class _ReviewHost implements TurnHost {
  final StringBuffer _text = StringBuffer();

  /// The reply text so far.
  String get written => _text.toString();

  @override
  Future<void> save(TurnCheckpoint checkpoint) async {}

  @override
  void step(String code) {}

  @override
  void text(String chunk) => _text.write(chunk);

  @override
  void resetText() => _text.clear();

  @override
  void question(String text, List<String> options) {}

  @override
  void trace(List<TraceLine> steps) {}

  @override
  void links(List<QueryLink> links) {}

  @override
  Future<TurnCheckpoint?> proposal(
    TurnProposal proposal,
    TurnCheckpoint Function(CheckpointCard card) withCard,
  ) async => null;

  @override
  Future<void> supersede(List<String> cardIds) async {}

  @override
  ({PriorCardState status, String line, int revision})? priorCard(
    String cardId,
  ) => null;

  @override
  Future<void> summary(String text, int revision, String watermark) async {}

  @override
  String toString() => '_ReviewHost';
}
