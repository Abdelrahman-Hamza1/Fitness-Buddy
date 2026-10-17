import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';

/// Day and slot totals (A06 D12, TD-048): the sum of the entries' stored
/// snapshots (core five, and an extra only when every entry has it), at
/// storage precision. Snapshots are whole hundredths, so the rounding only
/// removes floating-point noise and a total doesn't depend on the order.
///
/// Display rounding stays `DisplayRounding`'s: round the total, never sum
/// rounded values.
abstract final class DiaryTotals {
  /// The total of [entries], the live entries of one day.
  static Nutrients day(Iterable<DiaryEntry> entries) =>
      Nutrients.sum(entries.map((entry) => entry.snapshot)).rounded();

  /// The total of the [entries] in [slotId].
  static Nutrients slot(Iterable<DiaryEntry> entries, String slotId) =>
      day(entries.where((entry) => entry.slotId == slotId));

  /// The total of each slot that has entries, by slot ID.
  static Map<String, Nutrients> bySlot(Iterable<DiaryEntry> entries) {
    final groups = <String, List<DiaryEntry>>{};
    for (final entry in entries) {
      (groups[entry.slotId] ??= []).add(entry);
    }
    return Map.unmodifiable(groups.map((id, list) => MapEntry(id, day(list))));
  }
}
