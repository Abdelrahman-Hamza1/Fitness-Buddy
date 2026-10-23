/// The diary feature. Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/day_rows.dart';
export 'application/day_view.dart';
export 'application/diary_actions.dart';
export 'application/diary_providers.dart';
export 'application/diary_view_state.dart';
export 'data/diary_op_handler.dart' show DiaryOpHandler;
export 'data/diary_repository.dart';
export 'presentation/entry_details.dart';
export 'presentation/entry_row.dart';
export 'presentation/group_rows.dart';
export 'presentation/move_to_slot_sheet.dart';
export 'presentation/slot_header_row.dart';
