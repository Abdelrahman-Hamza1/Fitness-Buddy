import 'package:fb_domain/src/math/rounding.dart';

/// Estimated one-rep max by the Epley formula (WO-041, WO-042):
/// `kg × (1 + reps / 30)`, and exactly [kg] for a single.
double epleyE1rm(double kg, int reps) {
  if (!kg.isFinite || kg < 0 || reps < 1) {
    throw ArgumentError('e1RM needs a finite weight and at least one rep');
  }
  return reps == 1 ? kg : kg * (1 + reps / 30);
}

/// One weighted set for records: the load in kg and its reps. Callers pass
/// weight × reps sets and the added load of bodyweight sets; assisted sets
/// aren't records (less assistance is better, A36 D3).
typedef LiftedSet = ({double kg, int reps});

/// A kind of personal record (WO-042).
enum PrKind {
  /// Heaviest weight lifted.
  heaviest,

  /// Best estimated one-rep max.
  e1rm,

  /// Most reps at a given weight.
  repsAtWeight,
}

/// One exercise's personal records, derived from its sets, never stored
/// (WO-042, A36 D3). Adding sets never lowers a record.
final class PersonalRecords {
  new _(this.heaviestKg, this.bestE1rm, Map<double, int> repsByKg)
    : mostRepsByKg = Map.unmodifiable(repsByKg);

  /// No records yet.
  static final PersonalRecords none = PersonalRecords._(null, null, const {});

  /// The records over [sets] (sets with a weight of 0 count only for reps).
  static PersonalRecords of(Iterable<LiftedSet> sets) =>
      sets.fold(none, (records, set) => records.add(set));

  /// The heaviest kg, or `null` before any loaded set.
  final double? heaviestKg;

  /// The best Epley e1RM in kg, or `null` before any loaded set.
  final double? bestE1rm;

  /// Most reps per weight, keyed by kg on a 0.25 kg grid (so 80 kg and
  /// 176.37 lb meet).
  final Map<double, int> mostRepsByKg;

  /// The weight key [kg] is recorded under.
  static double keyOf(double kg) => roundHalfAwayFromZero(kg * 4, 0) / 4;

  /// These records with [set] added.
  PersonalRecords add(LiftedSet set) {
    final kinds = newRecords(set);
    if (kinds.isEmpty) return this;
    final key = keyOf(set.kg);
    return PersonalRecords._(
      kinds.contains(PrKind.heaviest) ? set.kg : heaviestKg,
      kinds.contains(PrKind.e1rm) ? epleyE1rm(set.kg, set.reps) : bestE1rm,
      {...mostRepsByKg, if (kinds.contains(PrKind.repsAtWeight)) key: set.reps},
    );
  }

  /// The records [set] would beat (a plain marker for the logged card,
  /// WO-042). The very first set of an exercise beats them all; ties don't.
  Set<PrKind> newRecords(LiftedSet set) {
    final e1rm = epleyE1rm(set.kg, set.reps);
    final heaviest = heaviestKg;
    final best = bestE1rm;
    final reps = mostRepsByKg[keyOf(set.kg)];
    return {
      if (set.kg > 0 && (heaviest == null || set.kg > heaviest))
        PrKind.heaviest,
      if (set.kg > 0 && (best == null || e1rm > best)) PrKind.e1rm,
      if (reps == null || set.reps > reps) PrKind.repsAtWeight,
    };
  }
}
