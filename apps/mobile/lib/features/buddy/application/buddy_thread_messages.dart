import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_thread_messages.g.dart';

/// The saved rows of this process's thread by ID (A22 D11), live: the sheet
/// renders text and status from storage, never from memory.
@riverpod
Stream<Map<String, ChatMessage>> buddyThreadMessages(Ref ref) {
  final key = ref.watch(
    buddyThreadControllerProvider.select(
      (thread) => [
        for (final turn in thread.turns) ...[
          turn.userMessageId,
          ?turn.assistantMessageId,
        ],
      ].join(','),
    ),
  );
  if (key.isEmpty) return Stream.value(const {});
  return ref
      .watch(chatMessageRepositoryProvider)
      .watchByIds(key.split(','))
      .map((messages) => {for (final m in messages) m.id: m});
}
