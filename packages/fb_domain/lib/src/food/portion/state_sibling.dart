import 'package:fb_domain/src/food/food_state.dart';

/// Pack food metadata used for a safe stated-state switch (FD-060, PA12).
final class StateSibling<T> {
  /// [nameKey] is a strict identity key, retaining ratios and qualifiers.
  const new({
    required this.id,
    required this.nameKey,
    required this.state,
    required this.yieldGroup,
    required this.payload,
  });

  /// Stable food identity.
  final String id;

  /// Caller-normalized English identity key.
  final String nameKey;

  /// Pack state.
  final FoodState state;

  /// Pack yield group, or null if absent.
  final String? yieldGroup;

  /// Food represented by this metadata.
  final T payload;

  /// Compatible foods in [stated], ordered by name length then identity.
  /// The caller additionally checks the group's yield factor is available.
  static List<T> choose<T>({
    required StateSibling<T> picked,
    required Iterable<StateSibling<T>> groupFoods,
    required FoodState stated,
  }) {
    if (picked.yieldGroup == null || picked.state == stated) return [];
    final key = _withoutState(picked.nameKey);
    if (key.isEmpty) return [];
    final siblings =
        groupFoods
            .where(
              (food) =>
                  food.id != picked.id &&
                  food.state == stated &&
                  food.yieldGroup == picked.yieldGroup &&
                  _withoutState(food.nameKey) == key,
            )
            .toList()
          ..sort((a, b) {
            final length = a.nameKey.runes.length.compareTo(
              b.nameKey.runes.length,
            );
            return length != 0 ? length : a.id.compareTo(b.id);
          });
    return siblings.map((food) => food.payload).toList();
  }
}

String _withoutState(String key) =>
    key.split(' ').where((word) => !_stateWords.contains(word)).join(' ');

const _stateWords = {
  'raw',
  'cooked',
  'dry',
  'boiled',
  'roasted',
  'braised',
  'grilled',
  'broiled',
  'pan',
  'fried',
  'baked',
  'drained',
};
