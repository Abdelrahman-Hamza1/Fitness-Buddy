/// The state a food's nutrient values (or a stated amount) refer to. A yield
/// factor converts amounts between two states (FD-060).
enum FoodState {
  /// Raw (meat, fish, vegetables).
  raw('raw'),

  /// Cooked (boiled, grilled, baked).
  cooked('cooked'),

  /// Dry (rice, pasta, lentils before cooking).
  dry('dry'),

  /// Drained (canned beans, tuna).
  drained('drained'),

  /// Fried.
  fried('fried'),

  /// As sold (packaged food as it comes).
  asSold('as_sold');

  new(this.code);

  /// The stable code used in stored data and the catalog.
  final String code;

  /// The state whose [code] is exactly [code], or `null`.
  static FoodState? fromCode(String code) {
    for (final state in values) {
      if (state.code == code) return state;
    }
    return null;
  }
}
