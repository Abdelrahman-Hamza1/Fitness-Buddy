import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';

/// A saved snapshot, independent of subsequent food edits (DY-031).
final class SavedMealItem {
  /// Stored identity, order and exact snapshot; no nutrient recalculation.
  const new({
    required this.id,
    required this.version,
    required this.sortOrder,
    required this.food,
    required this.amount,
    required this.snapshot,
  });

  /// Row identity.
  final String id;

  /// Observed row version.
  final int version;

  /// Position in the saved meal.
  final int sortOrder;

  /// Food snapshot, including edited-by-user provenance.
  final EntryFood food;

  /// Original input and canonical amount.
  final EntryAmount amount;

  /// Stored nutrient values.
  final Nutrients snapshot;

  @override
  String toString() => 'SavedMealItem';
}

/// A live saved meal with its live items, including empty meals (DY-031).
final class SavedMeal {
  /// Defensively copies and orders items by position then identity.
  new({
    required this.id,
    required this.version,
    required this.name,
    required Iterable<SavedMealItem> items,
  }) : items = List.unmodifiable(
         items.toList()..sort((a, b) {
           final order = a.sortOrder.compareTo(b.sortOrder);
           return order != 0 ? order : a.id.compareTo(b.id);
         }),
       );

  /// Row identity.
  final String id;

  /// Observed row version.
  final int version;

  /// Private display name.
  final String name;

  /// Live snapshots in stored order.
  final List<SavedMealItem> items;

  /// Totals at storage precision, preserving unknown extras.
  Nutrients get totals => Nutrients.sum(items.map((i) => i.snapshot)).rounded();

  /// Exact source guard, or null when logging an empty meal is unavailable.
  SavedMealVersions? get versions => items.isEmpty
      ? null
      : SavedMealVersions(
          meal: VersionedId(id, version),
          items: items.map((i) => VersionedId(i.id, i.version)),
        );

  @override
  String toString() => 'SavedMeal';
}
