import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/application/diary_view_state.dart';

/// Flat sliver row description; no widgets or formatted text.
sealed class DayRow {
  const new();
}

/// Day totals.
final class NumbersRow extends DayRow {
  /// Stored totals with what is known (A62).
  const new(this.intake);

  /// Header totals, knowledge-aware: "~" and "—" follow it.
  final IntakeTotals intake;
}

/// Empty-state kind; presentation owns the hint.
final class EmptyHintRow extends DayRow {
  /// Distinguishes today from history.
  const new({required this.isToday});

  /// Whether Buddy's today hint applies.
  final bool isToday;
}

/// A past day with nothing logged and no day estimate (A62 E2 A, DY-006):
/// "Didn't log {weekday}?" with "about ___ kcal".
final class DayEstimatePromptRow extends DayRow {
  /// The prompt for a day whose mark (if any) is [mark].
  const new(this.mark);

  /// The day's live mark as shown (its version guards the save), or null.
  final DayMark? mark;
}

/// The day's own estimate (DY-006, A62 D16): "~2,300". [superseded] when
/// the day also has food (two offline devices, D13): food wins, the row is
/// dimmed and only offers to clear it.
final class DayEstimateRow extends DayRow {
  /// The estimate held by [mark].
  const new(this.mark, {required this.superseded});

  /// The day's mark, with its estimate and version.
  final DayMark mark;

  /// Whether the day's food replaces it in every total.
  final bool superseded;
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
  ///
  /// A past day without food offers a day estimate, or shows the one its
  /// [mark] holds, which then is the day's intake (A62 D9, D16); a day with
  /// food and an estimate shows it superseded (D13).
  static List<DayRow> of(
    DayLayout layout,
    DiaryViewChoices viewState, {
    required bool isToday,
    DayMark? mark,
  }) {
    final estimate = mark?.estimateKcal;
    final rows = <DayRow>[
      NumbersRow(
        layout.isEmpty && estimate != null
            ? IntakeTotals.ofDayEstimate(estimate)
            : layout.intake,
      ),
      if (estimate != null)
        DayEstimateRow(mark!, superseded: !layout.isEmpty)
      else if (layout.isEmpty && isToday)
        const EmptyHintRow(isToday: true)
      else if (layout.isEmpty)
        DayEstimatePromptRow(mark),
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
