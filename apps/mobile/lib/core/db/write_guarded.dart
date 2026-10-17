import 'package:drift/drift.dart';

/// A database whose every statement goes through `WriteGuard` (A01 D11):
/// what the row writer and the applier require, so they can't be handed a
/// connection without the guard (whose read barrier their batching needs,
/// see `RowWriteSession`). Mixed in only by a database whose constructor
/// wraps its executor with `interceptWith(WriteGuard())`.
///
/// Its own file, not `write_guard.dart`: that one opens write scopes and is
/// imported only inside `core/db/` (`tools/app_check` rule 11).
mixin WriteGuarded on DatabaseConnectionUser;
