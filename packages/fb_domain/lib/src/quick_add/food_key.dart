import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/food_ref.dart';

/// Usage identity, independent of pack version and amount (A09 D12).
final class FoodKey implements Comparable<FoodKey> {
  /// Stable kind and opaque identity. Estimate identities are private names.
  const new(this.kind, this.identity);

  /// Name normalization is supplied by the caller, never inferred here.
  factory of(EntryFood food, {required String Function(String) nameKey}) =>
      FoodKey(
        food.ref.kind,
        food.ref.kind == FoodRefKind.estimate
            ? nameKey(food.names.en)
            : food.ref.id!,
      );

  /// Source kind.
  final FoodRefKind kind;

  /// Opaque ID, or normalized estimate name; never log this.
  final String identity;

  /// Stable ordering token; private when derived from an estimate.
  String get key => '${kind.code}:$identity';

  @override
  int compareTo(FoodKey other) => key.compareTo(other.key);
  @override
  bool operator ==(Object other) =>
      other is FoodKey && other.kind == kind && other.identity == identity;
  @override
  int get hashCode => Object.hash(kind, identity);
  @override
  String toString() => 'FoodKey';
}
