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
}

/// Sync registry name (`chatMessage` v1, B18).
const chatMessageEntity = 'chatMessage';
