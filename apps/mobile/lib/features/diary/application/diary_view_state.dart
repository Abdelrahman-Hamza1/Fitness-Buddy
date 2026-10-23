import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'diary_view_state.g.dart';

/// Date prevents a neighbouring day's emission from collapsing details.
typedef ExpandedEntry = ({LocalDate date, String id});

/// Session choices, independent of cached days (PA4/PA5).
final class DiaryViewChoices {
  /// Slots closed by default, dish groups open by default (UX-013).
  new({
    Iterable<String> expandedSlotIds = const [],
    Iterable<String> collapsedGroupIds = const [],
    this.expandedEntry,
  }) : expandedSlotIds = Set.unmodifiable(expandedSlotIds),
       collapsedGroupIds = Set.unmodifiable(collapsedGroupIds);

  /// Open slots survive day changes.
  final Set<String> expandedSlotIds;

  /// User-collapsed dishes survive day changes.
  final Set<String> collapsedGroupIds;

  /// At most one entry's details are open.
  final ExpandedEntry? expandedEntry;
}

/// Owns expansion for the app session.
@Riverpod(keepAlive: true)
class DiaryViewState extends _$DiaryViewState {
  String? _expandedSlotId;
  @override
  DiaryViewChoices build() => DiaryViewChoices();

  /// Toggles a slot without changing the other choices.
  void toggleSlot(String id) {
    final slots = {...state.expandedSlotIds};
    if (!slots.remove(id)) slots.add(id);
    state = DiaryViewChoices(
      expandedSlotIds: slots,
      collapsedGroupIds: state.collapsedGroupIds,
      expandedEntry: state.expandedEntry,
    );
  }

  /// Dish members are visible until explicitly collapsed.
  void toggleGroup(String id) {
    final groups = {...state.collapsedGroupIds};
    if (!groups.remove(id)) groups.add(id);
    state = DiaryViewChoices(
      expandedSlotIds: state.expandedSlotIds,
      collapsedGroupIds: groups,
      expandedEntry: state.expandedEntry,
    );
  }

  /// Opens just this entry, or closes it when tapped again.
  void toggleEntry(DiaryEntry entry) {
    final key = (date: entry.localDate, id: entry.id);
    _expandedSlotId = entry.slotId;
    state = DiaryViewChoices(
      expandedSlotIds: state.expandedSlotIds,
      collapsedGroupIds: state.collapsedGroupIds,
      expandedEntry: state.expandedEntry == key ? null : key,
    );
  }

  /// Only its own raw day clears details; slot moves open the destination.
  void onRaw(LocalDate date, DiaryDay raw) {
    final key = state.expandedEntry;
    if (key == null || key.date != date) return;
    final entry = raw.entries.where((e) => e.id == key.id).firstOrNull;
    final moved = entry != null && entry.slotId != _expandedSlotId;
    _expandedSlotId = entry?.slotId;
    if (entry == null || moved) {
      state = DiaryViewChoices(
        expandedSlotIds: {
          ...state.expandedSlotIds,
          if (entry != null) entry.slotId,
        },
        collapsedGroupIds: state.collapsedGroupIds,
        expandedEntry: entry == null ? null : key,
      );
    }
  }
}
