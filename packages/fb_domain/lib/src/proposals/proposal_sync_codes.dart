/// B18 wire codes and bounds of the `chatMessage` and `proposal` sync
/// entities (`contracts/openapi/sync-entities.json`, schema version 1).
///
/// Pure constants: the server enforces the same values from its embedded copy
/// of the contract, and tests pin both to it. New closed codes are
/// server-first (TD-080); opaque engine JSON evolves by `codecVersion`.
library;

import 'package:fb_domain/src/proposals/proposal_input.dart';

/// Who wrote a chat message (`chatMessage.role`).
enum ChatMessageRole {
  /// Typed by the user.
  user('user'),

  /// Buddy's reply; the only row that carries the shared question budget.
  assistant('assistant');

  new(this.code);

  /// The stable wire and storage code.
  final String code;

  /// The role whose [code] is exactly [code], or `null` for unknown codes.
  static ChatMessageRole? fromCode(String? code) {
    for (final role in values) {
      if (role.code == code) return role;
    }
    return null;
  }
}

/// Processing state of a chat message (`chatMessage.status`, `05` §2.3).
enum ChatMessageStatus {
  /// Saved, waiting to be sent.
  queued('queued'),

  /// Saved while offline; sent on reconnect.
  pendingOffline('pending_offline'),

  /// Sent, waiting for the reply.
  processing('processing'),

  /// Answered.
  done('done'),

  /// Failed; the user can retry.
  failed('failed');

  new(this.code);

  /// The stable wire and storage code.
  final String code;

  /// The status whose [code] is exactly [code], or `null` for unknown codes.
  static ChatMessageStatus? fromCode(String? code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }
}

/// Stored proposal status (`proposal.status`, `05` §2.3).
enum ProposalStatus {
  /// Waiting for the user; the engine's `active`.
  pending('pending'),

  /// Confirmed and applied.
  confirmed('confirmed'),

  /// Discarded by the user.
  discarded('discarded'),

  /// Historical row; never confirmable. Only the application marks it.
  superseded('superseded');

  new(this.code);

  /// The stable wire and storage code.
  final String code;

  /// The status whose [code] is exactly [code], or `null` for unknown codes.
  static ProposalStatus? fromCode(String? code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }

  /// Stored status of an engine card: `active ≡ pending` (A21 D9). The engine
  /// never originates [superseded]; only the application marks a row
  /// superseded (historical).
  static ProposalStatus ofLifecycle(ProposalLifecycle lifecycle) =>
      switch (lifecycle) {
        .active => pending,
        .confirmed => confirmed,
        .discarded => discarded,
        .superseded => superseded,
      };
}

/// How a resolved proposal ended (`proposal.outcome`; `null` while pending).
enum ProposalOutcome {
  /// Confirmed as proposed.
  unchanged('unchanged'),

  /// Confirmed after the user adjusted chips.
  adjusted('adjusted'),

  /// Discarded.
  discarded('discarded');

  new(this.code);

  /// The stable wire and storage code.
  final String code;

  /// The outcome whose [code] is exactly [code], or `null` for unknown codes
  /// and for the unresolved `null` outcome.
  static ProposalOutcome? fromCode(String? code) {
    for (final outcome in values) {
      if (outcome.code == code) return outcome;
    }
    return null;
  }
}

/// Size and range bounds of both entities, in UTF-16 code units for strings
/// (the same as .NET `string.Length`; a supplementary character counts 2).
abstract final class ChatProposalSyncBounds {
  /// `budgetJson`, `interpretationJson` and `draftJson`.
  static const int json = ProposalDraftCodec.syncStringLimit;

  /// `chatMessage.text`.
  static const text = 8192;

  /// `chatMessage.language`.
  static const language = 16;

  /// `proposal.kind` (an open vocabulary, e.g. `foodLog`).
  static const kind = 32;

  /// The shared `origin` field.
  static const origin = 128;

  /// Smallest `codecVersion`.
  static const codecVersionMin = 1;

  /// Largest `codecVersion` (a signed 32-bit integer).
  static const codecVersionMax = 2147483647;
}
