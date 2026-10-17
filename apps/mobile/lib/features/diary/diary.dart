/// The diary feature. Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/diary_providers.dart';
export 'data/diary_op_handler.dart' show DiaryOpHandler;
export 'data/diary_repository.dart';
