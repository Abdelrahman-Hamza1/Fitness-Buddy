/// Buddy: the chat transcript, its storage and (A22a) the chat sheet with
/// its proposal cards.
library;

export 'application/buddy_thread_controller.dart'
    show BuddyThreadController, buddyThreadControllerProvider;
export 'data/chat_message_op_handler.dart';
export 'data/chat_message_repository.dart';
export 'data/proposal_op_handler.dart';
export 'data/proposal_repository.dart';
export 'presentation/buddy_sheet.dart' show showBuddySheet;
