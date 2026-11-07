import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/data/memory_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_memory.g.dart';

/// Everything Buddy remembers, newest first ("Buddy remembers", AI-082).
@riverpod
Stream<List<MemoryItem>> buddyMemoryItems(Ref ref) =>
    ref.watch(memoryRepositoryProvider).watch();

/// "Buddy remembers" commands (A67 D14): forget one item or everything,
/// each one change set with an Undo. Direct actions, never a proposal.
final class BuddyMemoryActions {
  /// Over the single writer and the undo stack.
  const new(this._apply, this._undo);

  final Future<ApplyResult> Function(ChangeSet) _apply;
  final UndoStack _undo;

  /// Forgets [item]; its undo entry, or `null` when refused.
  Future<String?> forget(MemoryItem item) =>
      _run(DeleteMemoryItem(item.id, item.version));

  /// Forgets everything; its undo entry, or `null`.
  Future<String?> clearAll() => _run(const ClearMemoryItems());

  Future<String?> _run(MemoryItemOp op) async {
    final result = await _apply(ChangeSet([op], origin: Origin.direct));
    if (result is! Applied || result.inverse.isEmpty) return null;
    return _undo.record(result, UndoLabel('memoryForgotten')).id;
  }

  @override
  String toString() => 'BuddyMemoryActions';
}

/// The app's memory commands.
@Riverpod(keepAlive: true)
BuddyMemoryActions buddyMemoryActions(Ref ref) => BuddyMemoryActions(
  ref.watch(changeSetApplierProvider).apply,
  ref.watch(undoStackProvider),
);
