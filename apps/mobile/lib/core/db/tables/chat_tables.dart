// The `.check(column…)` idiom reads the getter being declared, which the
// analyzer takes for recursion; drift evaluates it lazily, so it's fine.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

/// Buddy's chat transcript (A22 D3, `05` §2.3), synced as `chatMessage` v1.
///
/// Exactly the contract's content fields: no attachment column (A28/A29 add
/// a local-only one in their own migration; the sync mapper is an explicit
/// allowlist, so it can't leak). Role and status mirror the closed wire
/// codes; text, language and budget bounds are UTF-16 rules the op handler
/// enforces (SQLite's `length()` counts code points). The budget pair isn't
/// a table constraint: the server checks no pairing within a row, so a
/// synced row may hold one without the other.
@DataClassName('ChatMessageRow')
class ChatMessages extends Table with SyncColumns {
  /// `user` or `assistant`.
  TextColumn get role => text().check(role.isIn(const ['user', 'assistant']))();

  /// The message text (`chatMessage.text`; a column named `text` would
  /// shadow drift's `text()`). User content: never logged.
  TextColumn get messageText => text()();

  /// `queued`, `pending_offline`, `processing`, `done` or `failed`.
  TextColumn get status => text().check(
    status.isIn(const [
      'queued',
      'pending_offline',
      'processing',
      'done',
      'failed',
    ]),
  )();

  /// A short language tag (`en`, `ar`, `ar-Latn`) or `null`.
  TextColumn get language => text().nullable()();

  /// The user message an assistant row answers.
  TextColumn get replyToMessageId => text().nullable()();

  /// Version of [budgetJson]'s engine format.
  IntColumn get codecVersion => integer().nullable()();

  /// The shared question budget, on the assistant row only. Bounded JSON.
  TextColumn get budgetJson => text().nullable()();

  /// Local-only (TD-102, A23 D4): the frozen interpret request of a user row
  /// while it waits (A23b), nulled at a terminal status. Never synced or
  /// logged; exported as the user's own data.
  TextColumn get requestJson => text().nullable()();

  /// Local-only (TD-102, A23 D14): the raw interpret answer of an assistant
  /// row, so a stale restored card rebuilds offline; nulled once no card of
  /// the message is pending. Never synced or logged; exported.
  TextColumn get answerJson => text().nullable()();
}

/// Sync registry name (`chatMessage` v1, B18).
const chatMessageEntity = 'chatMessage';

/// One Buddy card per meal (A23 D4, `05` §2.3), synced as `proposal` v1.
///
/// Exactly the contract's content fields. Status and outcome mirror the
/// closed wire codes; there are no pairing CHECKs (the server checks none),
/// the op handler enforces them locally. The JSON fields hold the full local
/// draft, which may exceed the 32768-unit sync bound (the mapper parks such a
/// row, A23 D15). User content: never logged.
@DataClassName('ProposalRow')
class Proposals extends Table with SyncColumns {
  /// The open kind vocabulary (`foodLog`).
  TextColumn get kind => text()();

  /// `pending`, `confirmed`, `discarded` or `superseded`.
  TextColumn get status => text().check(
    status.isIn(const ['pending', 'confirmed', 'discarded', 'superseded']),
  )();

  /// `unchanged`, `adjusted`, `discarded`, or `null` while pending.
  TextColumn get outcome => text().nullable().check(
    outcome.isIn(const ['unchanged', 'adjusted', 'discarded']),
  )();

  /// When it was resolved, UTC ms; `null` while pending.
  IntColumn get resolvedAt => integer().nullable()();

  /// The creating assistant message; immutable.
  TextColumn get originMessageId => text().nullable()();

  /// The assistant message whose budget the card belongs to now.
  TextColumn get budgetMessageId => text().nullable()();

  /// Version of the engine JSON format.
  IntColumn get codecVersion => integer()();

  /// This card's normalized intents.
  TextColumn get interpretationJson => text().nullable()();

  /// The compact card draft.
  TextColumn get draftJson => text()();
}

/// Sync registry name (`proposal` v1, B18).
const proposalEntity = 'proposal';
