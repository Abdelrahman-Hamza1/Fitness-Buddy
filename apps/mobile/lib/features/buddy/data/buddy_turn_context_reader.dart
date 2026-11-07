import 'package:fb_api_client/fb_api_client.dart' hide LocalDate;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/buddy/data/buddy_summary_repository.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_repository.dart';
import 'package:fb_mobile/features/buddy/data/memory_repository.dart';
import 'package:fb_mobile/features/buddy/data/memory_slice.dart';
import 'package:fb_mobile/features/buddy/data/open_batches.dart';
import 'package:fb_mobile/features/buddy/data/personal_slice.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/buddy/data/proposal_repository.dart';
import 'package:fb_mobile/features/diary/diary.dart' show DiaryReads;
import 'package:fb_mobile/features/foods/foods.dart'
    show PersonalFoodMappingError, personalFoodOf;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_turn_context_reader.g.dart';

/// An open card the snapshot lists (≤ 5, newest last): its local ID, its
/// kind, the revision the phone shows and its label.
typedef OpenCardRef = ({
  String cardId,
  String kind,
  int revision,
  String label,
});

/// Today's Ramadan state for a turn (A68 D7, B26 D12): a fasting day, its
/// fajr and maghrib as device-local "HH:mm" (when a city is chosen), and the
/// meal slots in use (suhoor/iftar on a fasting day).
typedef TurnRamadan = ({
  bool fasting,
  String? fajr,
  String? maghrib,
  SlotMode slots,
});

/// The start request's bounds (`06` §3.1, the contract).
abstract final class TurnBounds {
  /// History entries.
  static const history = 12;

  /// Evicted entries in one compaction.
  static const evicted = 24;

  /// Outcomes per history entry.
  static const outcomes = 6;

  /// History text, UTF-16 units.
  static const historyText = 1000;

  /// Outcome labels.
  static const label = 120;

  /// Open cards.
  static const openCards = 5;

  /// Open card summaries.
  static const openCardSummary = 200;

  /// Slots.
  static const slots = 12;

  /// Messages read to build history and compaction.
  static const read = 240;
}

/// Builds a turn's start body (A66 D10, `06` §3.1, TD-126) from one
/// read-only snapshot: history with card outcomes, compaction past the
/// summary's watermark, the personal slice, the profile and the snapshot.
/// No IDs other than local row IDs, no account data (AC-041). Holds user
/// content: never logged.
final class BuddyTurnContextReader {
  /// Reads [_db].
  const new(this._db, this._loader);

  final AppDatabase _db;
  final ProposalInputLoader _loader;

  /// The start body of turn [turnId] (the user row) with [text] at [now].
  Future<BuddyTurnStart> start({
    required String turnId,
    required String text,
    required EntryTime now,
    required List<OpenCardRef> openCards,
    required UnitSystem units,
    required bool halal,
    required bool trace,
    TurnRamadan? ramadan,
  }) async {
    final context = await _loader.refreshContext(referenceTime: now);
    return await _db.readSnapshot(() async {
      final messages = ChatMessageRepository(_db);
      final summary = await BuddySummaryRepository(_db).current();
      final rows = await messages.recent(TurnBounds.read);
      final before = [
        for (final m in rows)
          if (m.id != turnId) m,
      ];
      final entries = await _entries(before);
      final window = entries.length > TurnBounds.history
          ? entries.sublist(entries.length - TurnBounds.history)
          : entries;
      final older = entries.sublist(0, entries.length - window.length);
      final mark = summary == null
          ? -1
          : older.indexWhere((e) => e.messageId == summary.watermark);
      // Everything older than the window after the watermark (all of it
      // when the watermark is older than what was read, or there is none).
      final evicted = older.sublist(mark + 1);
      final slots = await DiaryReads(_db).slots();
      final foods = await _personalFoods();
      final memory = await MemoryRepository(_db).all();
      final meals = await DiaryReads(_db).savedMeals();
      final batches = await openBatches(_db, foods, now.occurredAtUtc);
      final previous = before.reversed
          .where(
            (m) =>
                m.role == ChatMessageRole.user &&
                m.status == ChatMessageStatus.done,
          )
          .firstOrNull;
      return BuddyTurnStart(
        turnId: turnId,
        mode: BuddyTurnMode.chat,
        message: BuddyTurnMessage(text: text, image: null),
        history: window,
        summary: summary == null
            ? null
            : BuddyConversationSummary(
                text: summary.text,
                revision: summary.revision,
                watermark: summary.watermark,
              ),
        compact: evicted.isEmpty
            ? null
            : BuddyCompaction(
                evicted: evicted.length > TurnBounds.evicted
                    ? evicted.sublist(evicted.length - TurnBounds.evicted)
                    : evicted,
                previousRevision: summary?.revision ?? 0,
              ),
        personal: PersonalSlice.match(
          text,
          foods,
          savedMeals: meals,
          batches: batches,
        ),
        profile: BuddyTurnProfile(
          memory: MemorySlice.profile(memory),
          defaults: MemorySlice.habits(memory),
          halal: halal,
          units: BuddyUnits(
            mass: units == UnitSystem.imperial
                ? BuddyMassUnit.lb
                : BuddyMassUnit.kg,
            length: units == UnitSystem.imperial
                ? BuddyLengthUnit.valueIn
                : BuddyLengthUnit.cm,
            energy: BuddyEnergyUnit.kcal,
          ),
          ramadan: BuddyRamadan(
            active: ramadan?.fasting ?? context?.dayContext?.ramadan ?? false,
            fajr: ramadan?.fasting ?? false ? ramadan!.fajr : null,
            maghrib: ramadan?.fasting ?? false ? ramadan!.maghrib : null,
          ),
        ),
        snapshot: BuddyTurnSnapshot(
          now: now.occurredAtUtc,
          tzOffsetMin: now.tzOffsetMin,
          slots: [
            for (final slot in slots)
              if (slot.active &&
                  slot.mode == (ramadan?.slots ?? SlotMode.normal))
                ?_slot(slot),
          ].take(TurnBounds.slots).toList(),
          today: _today(context, now.localDate),
          openCards: [
            for (final c in openCards.reversed.take(TurnBounds.openCards))
              BuddyOpenCard(
                kind: c.kind,
                proposalId: c.cardId,
                revision: c.revision,
                summary: _cut(c.label, TurnBounds.openCardSummary),
              ),
          ].reversed.toList(),
        ),
        ackTurn: previous == null
            ? null
            : BuddyTurnReference(turnId: previous.id),
        priorAttempt: null,
        trace: trace,
      );
    });
  }

  /// The history entries of [rows] (display order): each user message,
  /// then its turn's Buddy entry (the reply text, or the card labels) with
  /// the turn's card outcomes. Card holder rows (assistant rows with a
  /// budget) aren't entries of their own.
  Future<List<BuddyHistoryEntry>> _entries(List<ChatMessage> rows) async {
    final holders = <String, List<ChatMessage>>{};
    final replies = <String, ChatMessage>{};
    for (final m in rows) {
      final to = m.replyToMessageId;
      if (m.role != ChatMessageRole.assistant || to == null) continue;
      if (m.budgetJson != null) {
        (holders[to] ??= []).add(m);
      } else {
        replies[to] ??= m;
      }
    }
    final records = await ProposalRepository(
      _db,
    ).byOrigins({for (final list in holders.values) ...list.map((m) => m.id)});
    final labels = {
      for (final list in holders.values)
        for (final m in list) m.id: m.text,
    };
    final out = <BuddyHistoryEntry>[];
    for (final m in rows) {
      if (m.role != ChatMessageRole.user) continue;
      out.add(
        BuddyHistoryEntry(
          messageId: m.id,
          role: BuddyHistoryRole.user,
          text: _cut(m.text, TurnBounds.historyText),
          outcomes: const [],
        ),
      );
      final cards = holders[m.id] ?? const [];
      final reply = replies[m.id];
      if (reply == null && cards.isEmpty) continue;
      final origins = {for (final c in cards) c.id};
      final outcomes = [
        for (final r in records)
          if (origins.contains(r.originMessageId))
            BuddyOutcome(
              kind: r.kind,
              proposalId: r.id,
              status: switch (r.status) {
                ProposalStatus.pending => BuddyOutcomeStatus.pending,
                ProposalStatus.confirmed =>
                  r.outcome == ProposalOutcome.adjusted
                      ? BuddyOutcomeStatus.edited
                      : BuddyOutcomeStatus.confirmed,
                ProposalStatus.discarded ||
                ProposalStatus.superseded => BuddyOutcomeStatus.discarded,
              },
              label: _cut(
                labels[r.originMessageId] ?? 'Meal',
                TurnBounds.label,
              ),
            ),
      ];
      final text = reply?.text ?? cards.map((c) => c.text).join('; ');
      if (text.trim().isEmpty) continue;
      out.add(
        BuddyHistoryEntry(
          messageId: reply?.id ?? cards.first.id,
          role: BuddyHistoryRole.buddy,
          text: _cut(text, TurnBounds.historyText),
          outcomes: outcomes.take(TurnBounds.outcomes).toList(),
        ),
      );
    }
    return out;
  }

  Future<List<PersonalFood>> _personalFoods() async {
    final rows = await (_db.select(
      _db.personalFoods,
    )..where((t) => t.deletedAt.isNull())).get();
    final foods = <PersonalFood>[];
    for (final row in rows) {
      try {
        foods.add(personalFoodOf(row));
      } on PersonalFoodMappingError {
        // An unreadable food is never sent.
      }
    }
    return foods;
  }

  /// Today's confirmed totals and targets, from the engine's day context.
  static BuddyDayTotals _today(ProposalContext? context, LocalDate today) {
    final day = context?.dayContext;
    final eaten = day?.confirmed[today]?.sum;
    final settings = day?.weightKg == null ? null : day?.history?.at(today);
    final target = settings
        ?.plan(ramadanActive: day!.ramadan)
        .day(
          date: today,
          weightKg: day.weightKg!,
          earlierIntake: day.earlierIntake.where(
            (i) =>
                i.date.isBefore(today) &&
                !i.date.isBefore(day.calendar.weekStartOf(today)),
          ),
          calendar: day.calendar,
        );
    return BuddyDayTotals(
      kcal: eaten?.kcal ?? 0,
      proteinG: eaten?.protein ?? 0,
      carbsG: eaten?.carbs ?? 0,
      fatG: eaten?.fat ?? 0,
      fiberG: eaten?.fiber ?? 0,
      targets: target == null
          ? null
          : BuddyDayTargets(
              kcal: target.kcal,
              proteinG: target.macros.proteinGrams,
              carbsG: target.macros.carbsGrams,
              fatG: target.macros.fatGrams,
              fiberG: target.macros.fiberGrams,
            ),
    );
  }

  static BuddySlot? _slot(MealSlot slot) {
    final name = (slot.name ?? slot.defaultKey ?? '').trim();
    if (name.isEmpty || name.length > 200) return null;
    return BuddySlot(
      id: slot.id,
      name: name,
      window: switch (slot.window) {
        final w? => '${_hhmm(w.startMin)}-${_hhmm(w.endMin)}',
        null => null,
      },
    );
  }

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  /// [value] cut to [limit] UTF-16 units, never inside a surrogate pair.
  static String _cut(String value, int limit) {
    if (value.length <= limit) return value;
    var end = limit;
    final unit = value.codeUnitAt(end - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) end--;
    return value.substring(0, end);
  }

  @override
  String toString() => 'BuddyTurnContextReader';
}

/// The turn context reader of the open profile.
@Riverpod(keepAlive: true)
BuddyTurnContextReader buddyTurnContextReader(Ref ref) =>
    BuddyTurnContextReader(
      ref.watch(appDatabaseProvider),
      ref.watch(proposalInputLoaderProvider),
    );
