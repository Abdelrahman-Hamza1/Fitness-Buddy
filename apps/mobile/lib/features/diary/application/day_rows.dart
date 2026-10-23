import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/application/diary_view_state.dart';

/// Flat sliver row description; no widgets or formatted text.
sealed class DayRow {
  const new();
}

/// Day totals.
final class NumbersRow extends DayRow {
  /// Stored totals.
  const new(this.totals);

  /// Header nutrients.
  final Nutrients totals;
}

/// Empty-state kind; presentation owns the hint.
final class EmptyHintRow extends DayRow {
  /// Distinguishes today from history.
  const new({required this.isToday});

  /// Whether Buddy's today hint applies.
  final bool isToday;
}

/// Slot disclosure and summary.
final class SlotHeaderRow extends DayRow {
  /// Section plus disclosure state.
  const new(this.section, {required this.expanded});

  /// Display model.
  final SlotSection section;

  /// Whether its children follow.
  final bool expanded;
}

/// Macro line inside an open slot.
final class SlotMacrosRow extends DayRow {
  /// Section totals.
  const new(this.section);

  /// Display model.
  final SlotSection section;
}

/// Dish disclosure, open by default.
final class GroupHeaderRow extends DayRow {
  /// Dish within a slot.
  const new(this.item, {required this.slotKey, required this.expanded});

  /// Identity of the section containing this part of the dish.
  final String slotKey;

  /// Section-specific members and total.
  final GroupItem item;

  /// Whether members follow.
  final bool expanded;
}

/// Ungrouped food row.
final class EntryRow extends DayRow {
  /// Live entry snapshot.
  const new(this.entry);

  /// Shown version for commands.
  final DiaryEntry entry;
}

/// Indented food row beneath an open dish (DY-024).
final class GroupMemberRow extends DayRow {
  /// Live member and its header identity.
  const new(this.entry, this.groupId);

  /// Shown version for commands.
  final DiaryEntry entry;

  /// Parent dish identity.
  final String groupId;
}

/// Read-only details beneath the single expanded entry.
final class EntryDetailsRow extends DayRow {
  /// Full stored snapshot.
  const new(this.entry);

  /// Details source.
  final DiaryEntry entry;
}

/// Produces only visible rows, with no widget work (D16).
abstract final class DayRows {
  /// Opening a slot exposes grouped and plain items equally (UX-013).
  static List<DayRow> of(
    DayLayout layout,
    DiaryViewChoices viewState, {
    required bool isToday,
  }) {
    final rows = <DayRow>[
      NumbersRow(layout.totals),
      if (layout.isEmpty) EmptyHintRow(isToday: isToday),
    ];
    void addEntry(DiaryEntry entry, {String? groupId}) {
      rows.add(
        groupId == null ? EntryRow(entry) : GroupMemberRow(entry, groupId),
      );
      if (viewState.expandedEntry == (date: entry.localDate, id: entry.id)) {
        rows.add(EntryDetailsRow(entry));
      }
    }

    for (final section in layout.sections) {
      final expanded = viewState.expandedSlotIds.contains(section.key);
      rows.add(SlotHeaderRow(section, expanded: expanded));
      if (!expanded) continue;
      rows.add(SlotMacrosRow(section));
      for (final item in section.items) {
        switch (item) {
          case EntryItem(:final entry):
            addEntry(entry);
          case GroupItem():
            final open = !viewState.collapsedGroupIds.contains(item.group.id);
            rows.add(
              GroupHeaderRow(item, slotKey: section.key, expanded: open),
            );
            if (open) {
              for (final member in item.members) {
                addEntry(member, groupId: item.group.id);
              }
            }
        }
      }
    }
    return List.unmodifiable(rows);
  }
}
