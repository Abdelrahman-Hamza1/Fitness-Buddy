import 'package:fb_domain/fb_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_food_prefill.g.dart';

/// Private one-shot handoff. Names never enter route parameters (A09 D9).
@Riverpod(keepAlive: true)
class NewFoodPrefill extends _$NewFoodPrefill {
  @override
  String? build() => null;

  /// Search's current query, trimmed and bounded before opening the form.
  void put(String query) {
    final trimmed = query.trim();
    // Do not split a UTF-16 surrogate pair at the field boundary.
    var end = trimmed.length.clamp(0, PersonalFoodBounds.name);
    if (end > 0 &&
        end < trimmed.length &&
        trimmed.codeUnitAt(end - 1) >= 0xd800 &&
        trimmed.codeUnitAt(end - 1) <= 0xdbff) {
      end--;
    }
    state = trimmed.substring(0, end);
  }

  /// Consumes even an empty prefill; later forms start clean.
  String? take() {
    final value = state;
    state = null;
    return value;
  }
}

/// A new food prepared somewhere else (A67 D8: a Buddy card): the [draft]
/// the form opens with, and the ops its save adds to the same change set
/// ([also], given whether the user changed the draft) with [origin]. The
/// foods feature doesn't know who made it.
final class FoodFormPrefill {
  /// The prefill.
  const new({
    required this.draft,
    required this.also,
    required this.origin,
    this.perServingWithoutSize = false,
  });

  /// The draft's figures are per serving and its size is unknown: the form
  /// opens per serving with the size empty and can't save without it.
  final bool perServingWithoutSize;

  /// What the form opens with.
  final PersonalFoodDraft draft;

  /// The extra ops of the save.
  final List<ChangeOp> Function({required bool adjusted}) also;

  /// The save's origin.
  final Origin origin;

  @override
  String toString() => 'FoodFormPrefill';
}

/// One-shot handoff of a [FoodFormPrefill] to the next new-food form.
@Riverpod(keepAlive: true)
class PreparedFoodPrefill extends _$PreparedFoodPrefill {
  @override
  FoodFormPrefill? build() => null;

  /// Sets the prefill for the next form.
  // A command on the notifier, like NewFoodPrefill.put.
  // ignore: use_setters_to_change_properties
  void put(FoodFormPrefill prefill) => state = prefill;

  /// Consumes the prefill.
  FoodFormPrefill? take() {
    final value = state;
    state = null;
    return value;
  }
}
