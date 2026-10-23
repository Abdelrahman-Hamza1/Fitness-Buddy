import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/entry_measures.dart';
import 'package:fb_domain/src/food/food_state.dart';
import 'package:fb_domain/src/ids/hlc.dart';
import 'package:fb_domain/src/nutrition/sanity.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// Latest snapshot and usage aggregate for a food (FD-023, A07 PA4).
/// [food] retains the stored ref version and full provenance; nullable pack
/// metadata must stay absent for retired IDs or before pack installation.
final class FoodHistoryItem {
  /// The latest log's snapshot and input, plus aggregate usage.
  const new({
    required this.food,
    required this.amount,
    required this.uses,
    required this.lastUsedHlc,
    this.editedByUser = false,
    this.state,
    this.brand,
    this.yieldGroup,
    this.sanity,
  });

  /// Stored ref, names, nutrients (including extras), and full provenance.
  final EntryFood food;

  /// Original input and canonical amount on its stored basis.
  final EntryAmount amount;

  /// Count of live entries for this food.
  final int uses;

  /// Latest live entry's HLC.
  final Hlc lastUsedHlc;

  /// Whether the latest entry's values were overridden.
  final bool editedByUser;

  /// Known pack state; never inferred from the snapshot's name.
  final FoodState? state;

  /// Known pack brand.
  final String? brand;

  /// Known pack yield group.
  final String? yieldGroup;

  /// Known pack sanity level.
  final SanityLevel? sanity;

  /// A portion reconstructed from the snapshot in its original g/ml basis.
  /// Generic inputs matching the stored amount need no reconstructed portion.
  ServingUnit? get derivedServing => reconstructedServingOf(amount);
}
