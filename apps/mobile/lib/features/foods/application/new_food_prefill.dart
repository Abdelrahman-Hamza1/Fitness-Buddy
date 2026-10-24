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
