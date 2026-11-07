import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_buddy_message.g.dart';

/// A user message saved before dispatch (UX-052): its row ID (also the
/// turn ID and Idempotency-Key, A66), the sanitized [text] and when it was
/// sent. Holds user content: never logged.
final class SavedBuddyMessage {
  /// Message [id] with [text] at [time].
  const new({required this.id, required this.text, required this.time});

  /// The user row's ID (UUIDv7).
  final String id;

  /// What was saved and is sent.
  final String text;

  /// The send time; the engine's reference time and the request's `now`.
  final EntryTime time;

  @override
  String toString() => 'SavedBuddyMessage($id)';
}

/// Engine IDs from the app's UUIDv7 generator.
final class GeneratorProposalIds implements ProposalIdSource {
  /// IDs from [_ids].
  const new(this._ids);

  final IdGenerator _ids;

  @override
  String next() => _ids.next();
}

/// The first step of sending (A22 D6): the user message is saved as
/// `queued` in its own committed change set before anything is sent, so
/// nothing typed is lost (UX-052). The agent turn that follows is the
/// thread's (A66). Saving a chat message has no undo (D5, PA9). Texts are
/// never logged.
final class SendBuddyMessage {
  /// The save step over its ports.
  const new({required this._apply, required this._ids, required this._clock});

  final Future<ApplyResult> Function(ChangeSet) _apply;
  final IdGenerator _ids;
  final Clock _clock;

  /// Saves [raw] as a `queued` user message (sanitized to the composer's
  /// 1000 UTF-16 units). `null` for blank text or a rejected write.
  Future<SavedBuddyMessage?> save(String raw) async {
    final text = ChatText.sanitize(raw, limit: ChatText.composerLimit);
    if (text.trim().isEmpty) return null;
    final id = _ids.next();
    final result = await _apply(
      ChangeSet([
        CreateChatMessage(
          id,
          ChatMessageDraft(
            role: ChatMessageRole.user,
            text: text,
            status: ChatMessageStatus.queued,
          ),
        ),
      ], origin: Origin.direct),
    );
    if (result is! Applied) return null;
    return SavedBuddyMessage(id: id, text: text, time: EntryTime.now(_clock));
  }

  @override
  String toString() => 'SendBuddyMessage';
}

/// The app's save step.
@Riverpod(keepAlive: true)
SendBuddyMessage sendBuddyMessage(Ref ref) => SendBuddyMessage(
  apply: ref.watch(changeSetApplierProvider).apply,
  ids: ref.watch(idGeneratorProvider),
  clock: ref.watch(clockProvider),
);
