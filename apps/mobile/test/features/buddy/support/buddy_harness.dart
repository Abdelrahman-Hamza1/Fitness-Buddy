import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/proposal_persistence_contributor.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/buddy/data/buddy_api.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_reader.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart';
import '../../../core/changes/support/test_db.dart'
    show ScriptHandler, ScriptOp;
import '../../../core/db/support/db_support.dart';
import '../../../helpers/fake_http.dart';

export '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    show food, intent, item, message;
export '../../../core/changes/support/test_db.dart' show ScriptOp;
export '../../../helpers/fake_http.dart';

/// The fixed reply templates.
const texts = BuddyReplyTexts(
  cards: 'Here is your meal.',
  medical: 'MEDICAL-TEMPLATE',
  notFood: 'NOT-FOOD-TEMPLATE',
  noCard: 'NO-CARD-TEMPLATE',
  unsupported: 'UNSUPPORTED-TEMPLATE',
);

/// Two cards: breakfast (an egg) and lunch (an egg).
Map<String, Object?> twoMeals({String language = 'english'}) =>
    {
      ...message([
        intent([item()], slot: 'breakfast'),
        intent([item()], slot: 'lunch'),
      ]),
    }..update(
      'intents',
      (v) => [
        for (final i in v! as List<Object?>)
          {...i! as Map<String, Object?>, 'language': language},
      ],
    );

/// A contributor whose hooks return the given ops (and record their calls).
final class TestContributor extends ProposalPersistenceContributor {
  /// Returns [reply] / [confirm] / [discard] ops.
  new({
    this.reply = const [],
    this.confirm = const [],
    this.discard = const [],
  });

  final List<ChangeOp> reply;
  final List<ChangeOp> confirm;
  final List<ChangeOp> discard;
  final calls = <String>[];

  @override
  List<ChangeOp> onReply(ProposalSession session, String assistantMessageId) {
    calls.add('reply');
    return reply;
  }

  @override
  List<ChangeOp> onConfirm(ProposalCard card, ProposalSession session) {
    calls.add('confirm');
    return confirm;
  }

  @override
  List<ChangeOp> onDiscard(ProposalCard card, ProposalSession session) {
    calls.add('discard');
    return discard;
  }
}

/// A navigator that records what was pushed.
final class RecordingAppNavigator implements AppNavigator {
  /// Every pushed route, in order.
  final List<AppRoute> pushed = [];

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) => pushed.add(route);

  @override
  void pop() {}
}

/// The real applier, database, send path, resolution and thread controller
/// over a fake transport, at 2026-10-17 08:00 UTC.
final class BuddyHarness {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [
        ChatMessageOpHandler(db),
        DiaryOpHandler(db),
        MealSlotOpHandler(db),
        PersonalFoodOpHandler(db),
        const ScriptHandler(),
      ],
      clock: clock,
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
    final catalog = OfflineCatalog(db);
    addTearDown(catalog.dispose);
    loader = ProposalInputLoader(
      db,
      catalog: catalog,
      config: () => configThrows
          ? throw StateError('config unreadable (test)')
          : ClientConfigRepository.defaults,
    );
    undo = UndoStack(revert: applier.revert, clock: clock);
    addTearDown(undo.dispose);
    Future<ApplyResult> apply(ChangeSet set) {
      if (throwOnApply?.call(set) ?? false) {
        throw StateError('applier failed (test)');
      }
      applied.add(set);
      return applier.apply(set);
    }

    send = SendBuddyMessage(
      apply: apply,
      ids: ids,
      clock: clock,
      api: BuddyApi(
        createApiDio(
          baseUrl: Uri.parse('https://api.test'),
          adapter: adapter,
          interceptors: [],
        ),
      ),
      reader: InterpretRequestReader(db),
      loader: loader,
      messages: ChatMessageRepository(db),
      contributors: contributors,
      report: issues.add,
    );
    resolution = ProposalResolution(
      apply: apply,
      undo: undo,
      loader: loader,
      ids: ids,
      contributors: contributors,
      report: issues.add,
    );
    container = ProviderContainer.test(
      overrides: [
        sendBuddyMessageProvider.overrideWithValue(send),
        proposalResolutionProvider.overrideWithValue(resolution),
        // What the sheet and cards read.
        appDatabaseProvider.overrideWithValue(db),
        unitSystemProvider.overrideWith(
          (ref) => Stream.value(UnitSystem.metric),
        ),
        appNavigatorProvider.overrideWithValue(navigator),
        undoStackProvider.overrideWithValue(undo),
        domainEventBusProvider.overrideWithValue(bus),
        clockProvider.overrideWithValue(clock),
      ],
    );
  }

  final AppDatabase db = memoryDatabase();

  /// The contributors the send path and resolution call; tests add to it.
  final List<ProposalPersistenceContributor> contributors = [];
  final DomainEventBus bus = DomainEventBus();
  final ManualClock clock = ManualClock(DateTime.utc(2026, 10, 17, 8));
  late final UuidV7Generator ids = UuidV7Generator(clock, Random(5));
  final FakeHttpAdapter adapter = FakeHttpAdapter();
  final List<BuddyIssue> issues = [];
  final List<ChangeSet> applied = [];

  /// The loader's config read throws an Error (not an Exception).
  bool configThrows = false;

  /// The applier throws for the change sets this matches.
  bool Function(ChangeSet)? throwOnApply;

  /// Routes the sheet pushed (food search).
  final RecordingAppNavigator navigator = RecordingAppNavigator();
  late final ChangeSetApplier<AppDatabase> applier;
  late final ProposalInputLoader loader;
  late final UndoStack undo;
  late final SendBuddyMessage send;
  late final ProposalResolution resolution;
  late final ProviderContainer container;

  /// The thread controller.
  BuddyThreadController get thread =>
      container.read(buddyThreadControllerProvider.notifier);

  /// The thread state.
  BuddyThread get state => container.read(buddyThreadControllerProvider);

  /// Answers interpret calls with [body] (200).
  void answer(Map<String, Object?> body) => adapter.respond = json(body);

  /// Every chat row, oldest first.
  Future<List<ChatMessageRow>> chat() => (db.select(
    db.chatMessages,
  )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();

  /// Every chat row as a domain message, ordered by role (user first).
  Future<ChatMessageRow> row(String id) =>
      (db.select(db.chatMessages)..where((t) => t.id.equals(id))).getSingle();

  /// The interpret request bodies sent, as JSON text.
  List<String> get bodies => [
    for (final r in adapter.requests) jsonEncode(r.data),
  ];

  /// The Idempotency-Key headers sent.
  List<Object?> get keys => [
    for (final r in adapter.requests) r.headers['Idempotency-Key'],
  ];

  /// An op that inserts a settings row [n] (proves the transaction).
  ScriptOp settingOp(String n) => ScriptOp.rows([
    InsertRow(
      db.settingsKv,
      SettingsKvCompanion(id: Value('a22-$n'), valueJson: const Value('1')),
    ),
  ]);

  /// An op that rejects its change set.
  static ScriptOp failingOp() =>
      ScriptOp((_, _) async => throw const ChangeRejected(InvalidOp('test')));

  /// The diary entries.
  Future<List<DiaryEntryRow>> entries() => db.select(db.diaryEntries).get();
}
