import 'package:fb_domain/fb_domain.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_picker.g.dart';

/// The picker's query, chip and selection in pick order (WO-001, A37 D12).
@immutable
final class ExercisePickerState {
  /// A picker state.
  new({
    this.query = '',
    this.filter = ExerciseFilter.all,
    Iterable<String> selected = const [],
  }) : selected = List.unmodifiable(selected);

  /// The search text.
  final String query;

  /// The chip.
  final ExerciseFilter filter;

  /// The picked exercise IDs, in the order picked.
  final List<String> selected;

  /// The pick position of [id] (1-based), or `null`.
  int? positionOf(String id) {
    final i = selected.indexOf(id);
    return i < 0 ? null : i + 1;
  }

  /// This state with some fields changed.
  ExercisePickerState copyWith({
    String? query,
    ExerciseFilter? filter,
    Iterable<String>? selected,
  }) => ExercisePickerState(
    query: query ?? this.query,
    filter: filter ?? this.filter,
    selected: selected ?? this.selected,
  );
}

/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen: [scope] is the screen's own key, so pickers open
/// in two tabs (or a picker and an "All exercises" list) never share state.
@riverpod
class ExercisePicker extends _$ExercisePicker {
  @override
  ExercisePickerState build(Object scope) => ExercisePickerState();

  /// The search text changed.
  void search(String query) => state = state.copyWith(query: query);

  /// A chip was tapped.
  void filterBy(ExerciseFilter filter) =>
      state = state.copyWith(filter: filter);

  /// Picks [id], or unpicks it if picked.
  void toggle(String id) => state = state.copyWith(
    selected: state.selected.contains(id)
        ? state.selected.where((s) => s != id)
        : [...state.selected, id],
  );

  /// Picks [id] (a just-created custom exercise), keeping it picked.
  void pick(String id) {
    if (!state.selected.contains(id)) {
      state = state.copyWith(selected: [...state.selected, id]);
    }
  }
}
