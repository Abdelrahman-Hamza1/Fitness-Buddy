import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/db/tables/chat_tables.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_mappers.dart';
import 'package:fb_mobile/features/buddy/data/proposal_mappers.dart';

/// The written columns of [row] restricted to [keep] (the wire's columns).
Map<String, Expression<Object>> _columns(
  Insertable<Object?> row,
  Set<String> keep,
) => {
  for (final MapEntry(:key, :value) in row.toColumns(false).entries)
    if (keep.contains(key)) key: value,
};

/// Placeholder envelope for the mappers: the store writes the real one.
const _hlc = '0000000000000-00000-00000000-0000-7000-8000-000000000000';
const _device = '00000000-0000-7000-8000-000000000000';

/// `chatMessage` v1 (B18, A23): the A22/A23 mappers' allowlist, so the
/// local-only `request_json` and `answer_json` never leave the phone and
/// are never overwritten by a pull; a pulled tombstone clears them (A23
/// handoff). An unscrubbed tombstone is parked, never pushed (A23 D16).
final class ChatMessageSyncCodec implements SyncEntityCodec {
  /// The codec over [_db]'s `chat_messages`.
  new(this._db);

  final AppDatabase _db;

  static const Set<String> _wireColumns = {
    'created_at',
    'origin',
    'edited_by_user',
    'role',
    'message_text',
    'status',
    'language',
    'reply_to_message_id',
    'codec_version',
    'budget_json',
  };

  @override
  String get entity => chatMessageEntity;

  @override
  int get uploadVersion => 1;

  @override
  Map<String, Object?> encode(Map<String, Object?> sqlRow) {
    try {
      return chatMessageSyncPayload(_db.chatMessages.map(sqlRow));
    } on ChatMessageMappingError {
      throw const SyncEncodeRefused('unscrubbedTombstone');
    }
  }

  @override
  Map<String, Expression<Object>> decode(
    Map<String, Object?> payload, {
    required String id,
    required bool deleted,
  }) {
    try {
      return _columns(
        chatMessageRowOfSync(
          payload,
          id: id,
          updatedHlc: _hlc,
          version: 1,
          deviceId: _device,
        ),
        _wireColumns,
      );
    } on ChatMessageMappingError {
      throw const SyncDecodeFailure();
    }
  }

  @override
  Map<String, Expression<Object>> get tombstoneLocalColumns => const {
    'request_json': Variable<String>(null),
    'answer_json': Variable<String>(null),
  };
}

/// `proposal` v1 (B18, A23): the A23 mappers. A row too large for the wire
/// or an unscrubbed tombstone is parked, never pushed (A23 D15/D16).
final class ProposalSyncCodec implements SyncEntityCodec {
  /// The codec over [_db]'s `proposals`.
  new(this._db);

  final AppDatabase _db;

  static const Set<String> _wireColumns = {
    'created_at',
    'origin',
    'edited_by_user',
    'kind',
    'status',
    'outcome',
    'resolved_at',
    'origin_message_id',
    'budget_message_id',
    'codec_version',
    'interpretation_json',
    'draft_json',
  };

  @override
  String get entity => proposalEntity;

  @override
  int get uploadVersion => 1;

  @override
  Map<String, Object?> encode(Map<String, Object?> sqlRow) {
    try {
      return proposalToSync(_db.proposals.map(sqlRow));
    } on ProposalMappingError catch (error) {
      throw SyncEncodeRefused(switch (error) {
        ProposalMappingError.tooLarge => 'tooLarge',
        ProposalMappingError.unscrubbedTombstone => 'unscrubbedTombstone',
        _ => 'encodeFailed',
      });
    }
  }

  @override
  Map<String, Expression<Object>> decode(
    Map<String, Object?> payload, {
    required String id,
    required bool deleted,
  }) {
    try {
      return _columns(
        proposalRowOfSync(
          payload,
          id: id,
          updatedHlc: _hlc,
          version: 1,
          deviceId: _device,
        ),
        _wireColumns,
      );
    } on ProposalMappingError {
      throw const SyncDecodeFailure();
    }
  }

  @override
  Map<String, Expression<Object>> get tombstoneLocalColumns => const {};
}

/// The Buddy feature's sync codecs, by entity (composed by
/// `app/app_scope.dart`).
Map<String, SyncEntityCodec> buddySyncCodecs(AppDatabase db) => {
  chatMessageEntity: ChatMessageSyncCodec(db),
  proposalEntity: ProposalSyncCodec(db),
};
