import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/buddy/data/memory_repository.dart';
import 'package:fb_mobile/features/diary/diary.dart' show DiaryReads;
import 'package:fb_text/fb_text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weighing_tips.g.dart';

/// The occasional weighing nudge (AI-084, D-077, A67 D12): an estimated or
/// assumed-portion food logged at least [minLogs] times in [window] gets
/// one tip, at most once per food per [every]; the tip shown is a learned
/// `nudge` memory item (shown and deletable, AI-082).
final class WeighingTips {
  /// Over [_db], writing through [_apply].
  const new(this._db, this._apply);

  final AppDatabase _db;
  final Future<ApplyResult> Function(ChangeSet) _apply;

  /// Logs that make a food "often" (about weekly or more).
  static const minLogs = 4;

  /// The days counted.
  static const window = 28;

  /// The least time between two tips for one food.
  static const every = Duration(days: 30);

  /// The food (its normalized key and name) of the tip for logged [card]
  /// at [now], recorded as shown; `null` for none.
  Future<({String key, String name})?> tipFor(
    ProposalCard card,
    EntryTime now,
  ) async {
    final today = now.localDate;
    final candidates = {
      for (final l in card.lines)
        if (l.componentOf == null &&
            (l.entry.food.provenance.isEstimate || l.amountAssumed))
          normalizeKey(l.entry.food.names.en): l.entry.food.names.en,
    }..removeWhere((k, _) => k.isEmpty || k.length > MemoryItemOp.maxText);
    if (candidates.isEmpty) return null;
    final entries = await DiaryReads(_db)
        .entriesBetween(today.plusDays(-(window - 1)), today);
    final memory = await MemoryRepository(_db).all();
    for (final MapEntry(:key, value: name) in candidates.entries) {
      final logs = entries
          .where((e) => normalizeKey(e.food.names.en) == key)
          .length;
      if (logs < minLogs) continue;
      final shown = memory
          .where((m) => m.kind == MemoryKinds.nudge && m.key == key)
          .firstOrNull;
      final last = shown == null ? null : LocalDate.tryParse(shown.value);
      if (last != null && last.daysUntil(today) < every.inDays) continue;
      final result = await _apply(
        ChangeSet([
          SaveMemoryItem(
            kind: MemoryKinds.nudge,
            key: key,
            value: '$today',
            origin: MemoryOrigin.learned,
          ),
        ], origin: Origin.system),
      );
      if (result is! Applied) return null;
      return (key: key, name: name);
    }
    return null;
  }

  @override
  String toString() => 'WeighingTips';
}

/// The app's weighing tips.
@Riverpod(keepAlive: true)
WeighingTips weighingTips(Ref ref) => WeighingTips(
  ref.watch(appDatabaseProvider),
  ref.watch(changeSetApplierProvider).apply,
);
