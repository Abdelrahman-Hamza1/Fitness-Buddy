import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/diary/totals.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';

/// Deterministic read model: orphan slots and groups retain food (DY-020).
final class DayLayout {
  new _(this.sections, this.totals, this.entryCount);

  /// Builds from live rows. Historical slots follow the active mode's slots.
  factory build(
    Iterable<MealSlot> slots,
    Iterable<DishGroup> groups,
    Iterable<DiaryEntry> entries, {
    SlotMode mode = SlotMode.normal,
  }) {
    final all = entries.toList();
    final bySlot = <String, List<DiaryEntry>>{};
    for (final entry in all) {
      (bySlot[entry.slotId] ??= []).add(entry);
    }
    final ordered = slots.toList()
      ..sort((a, b) {
        final aActive = a.active && a.mode == mode;
        final bActive = b.active && b.mode == mode;
        if (aActive != bActive) return aActive ? -1 : 1;
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    final groupMap = {for (final group in groups) group.id: group};
    final sections = <SlotSection>[];
    for (final slot in ordered) {
      final rows = bySlot.remove(slot.id) ?? [];
      if ((slot.active && slot.mode == mode) || rows.isNotEmpty) {
        sections.add(SlotSection._(slot, rows, groupMap));
      }
    }
    if (bySlot.isNotEmpty) {
      sections.add(
        SlotSection._(null, bySlot.values.expand((v) => v).toList(), groupMap),
      );
    }
    return DayLayout._(
      List.unmodifiable(sections),
      DiaryTotals.day(all),
      all.length,
    );
  }

  /// Ordered sections, including empty active slots.
  final List<SlotSection> sections;

  /// Stored sums, rounded only after summation.
  final Nutrients totals;

  /// Number of live entries, counting group members once.
  final int entryCount;

  /// Whether there is any food on this day.
  bool get isEmpty => entryCount == 0;
}

/// A slot's ordered food and totals; null slot means the orphan fallback.
final class SlotSection {
  new _(this.slot, List<DiaryEntry> entries, Map<String, DishGroup> groups)
    : totals = DiaryTotals.day(entries) {
    entries.sort(_compareEntries);
    final grouped = <String, List<DiaryEntry>>{};
    final result = <DiaryItem>[];
    for (final entry in entries) {
      final group = groups[entry.dishGroupId];
      if (group == null) {
        result.add(EntryItem(entry));
      } else {
        (grouped[group.id] ??= []).add(entry);
      }
    }
    for (final group in grouped.entries) {
      result.add(GroupItem(groups[group.key]!, group.value));
    }
    result.sort((a, b) {
      final order = a.firstEntry.time.localDateTime.time.compareTo(
        b.firstEntry.time.localDateTime.time,
      );
      return order != 0 ? order : a.key.compareTo(b.key);
    });
    items = List.unmodifiable(result);
  }

  /// Null for entries whose slot no longer exists.
  final MealSlot? slot;

  /// Stable section identity, without display text.
  String get key => slot?.id ?? 'other';

  /// Ordered entries and dish groups.
  late final List<DiaryItem> items;

  /// Stored snapshot sums for this section.
  final Nutrients totals;

  /// Content names; presentation supplies separators and truncation.
  List<String> get summaryNames => List.unmodifiable(
    items.map(
      (item) => switch (item) {
        EntryItem(:final entry) => entry.food.names.en,
        GroupItem(:final group) => group.name,
      },
    ),
  );
}

/// One item in a section (DY-024).
sealed class DiaryItem {
  const new();

  /// Identity within a section.
  String get key;

  /// First member determines chronological placement.
  DiaryEntry get firstEntry;
}

/// An ungrouped entry, including a member of a missing group.
final class EntryItem extends DiaryItem {
  /// Wraps a live row.
  const new(this.entry);

  /// The authoritative snapshot.
  final DiaryEntry entry;
  @override
  String get key => entry.id;
  @override
  DiaryEntry get firstEntry => entry;
}

/// A dish's members in this section; split groups appear in each slot.
final class GroupItem extends DiaryItem {
  /// Members must be nonempty and already in chronological order.
  new(this.group, Iterable<DiaryEntry> members)
    : members = List.unmodifiable(members),
      totals = DiaryTotals.day(members);

  /// The dish header.
  final DishGroup group;

  /// Members belonging to this section only.
  final List<DiaryEntry> members;

  /// Stored member sums.
  final Nutrients totals;
  @override
  String get key => group.id;
  @override
  DiaryEntry get firstEntry => members.first;
}

int _compareEntries(DiaryEntry a, DiaryEntry b) {
  final time = a.time.localDateTime.time.compareTo(b.time.localDateTime.time);
  return time != 0 ? time : a.id.compareTo(b.id);
}
