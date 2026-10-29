import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

// The targets feature's synced tables (A13 D2, TD-089). Content columns are
// the camelCase wire fields of `fb_domain`'s `TargetWireFields` in
// snake_case. Closed vocabularies and pairs are checked by
// `TargetRules.wire` on write and decoded tolerantly on read (a synced
// value from a newer app is skipped, not a constraint failure), so the
// tables carry no CHECKs beyond drift's boolean ones. Body data is
// sensitive: never log row values.

/// The profile: one natural-key row `naturalId('profile', 'self')`
/// (TD-070). No weight columns: weigh-ins are the only stored body weight
/// (TD-090, PA1).
@DataClassName('ProfileRow')
class Profiles extends Table with SyncColumns {
  @override
  String get tableName => 'profile';

  /// `male` or `female`.
  TextColumn get sex => text()();

  /// Birth year (age = evaluation year − this).
  IntColumn get birthYear => integer()();

  /// Height, cm.
  RealColumn get heightCm => real()();

  /// How the height was typed: `cm` or `ft_in` (TD-017).
  TextColumn get heightInputUnit => text()();

  /// `sedentary`, `light`, `moderate` or `high`.
  TextColumn get activity => text()();
}

/// Goal phases (TG-012), one UUIDv7 row each.
@DataClassName('GoalPhaseRow')
class GoalPhases extends Table with SyncColumns {
  /// The domain revision (≥ 1), separate from the row version.
  IntColumn get revision => integer()();

  /// The user's name, `null` for the default label. User content.
  TextColumn get name => text().nullable()();

  /// The first day, `YYYY-MM-DD`.
  TextColumn get startDate => text()();

  /// The last day, `YYYY-MM-DD`, or `null` while open.
  TextColumn get endDate => text().nullable()();

  /// `lose`, `maintain` or `gain`.
  TextColumn get goalType => text()();

  /// `targetDate`, `targetRate`, `weekly` or `monthly`; maintain is
  /// `weekly` 0.
  TextColumn get expressionKind => text()();

  /// Target weight, kg (`targetDate`, `targetRate`).
  RealColumn get targetKg => real().nullable()();

  /// Target date, `YYYY-MM-DD` (`targetDate`).
  TextColumn get targetDate => text().nullable()();

  /// kg a week: a positive speed (`targetRate`) or signed (`weekly`).
  RealColumn get kgPerWeek => real().nullable()();

  /// Signed kg over the named month (`monthly`).
  RealColumn get monthKg => real().nullable()();

  /// The named month's first day, `YYYY-MM-DD` (`monthly`).
  TextColumn get month => text().nullable()();

  /// The unit the goal's weights and rates were typed in: `kg` or `lb`
  /// (TD-017). Stored values are canonical kg.
  TextColumn get weightInputUnit => text()();
}

/// Effective-dated target settings versions (D5), one UUIDv7 row each.
/// Floors and daily targets are derived, never stored.
@DataClassName('TargetSettingsRow')
class TargetSettingsRows extends Table with SyncColumns {
  @override
  String get tableName => 'target_settings';

  /// The domain revision (≥ 1), separate from the row version.
  IntColumn get revision => integer()();

  /// The first day this version applies, `YYYY-MM-DD`.
  TextColumn get effectiveFrom => text()();

  /// `weekly` or `fixed`.
  TextColumn get mode => text()();

  /// Whether earlier intake rebalances the remaining days.
  BoolColumn get rebalancing => boolean()();

  /// The daily base, kcal (generated or manual), unrounded.
  RealColumn get baseKcal => real()();

  /// Whether the base is the user's own target.
  BoolColumn get manual => boolean()();

  /// Whether the user acknowledged a below-limit manual target (SF-012).
  BoolColumn get acknowledged => boolean()();

  /// The weight the base was computed with, kg.
  RealColumn get basisWeightKg => real()();

  /// Monday's shifting weight; `null` = 1.0 (PA5).
  RealColumn get shiftMon => real().nullable()();

  /// Tuesday's shifting weight; `null` = 1.0.
  RealColumn get shiftTue => real().nullable()();

  /// Wednesday's shifting weight; `null` = 1.0.
  RealColumn get shiftWed => real().nullable()();

  /// Thursday's shifting weight; `null` = 1.0.
  RealColumn get shiftThu => real().nullable()();

  /// Friday's shifting weight; `null` = 1.0.
  RealColumn get shiftFri => real().nullable()();

  /// Saturday's shifting weight; `null` = 1.0.
  RealColumn get shiftSat => real().nullable()();

  /// Sunday's shifting weight; `null` = 1.0.
  RealColumn get shiftSun => real().nullable()();

  /// Protein override value (with [proteinIsPercent]), or `null`.
  RealColumn get proteinValue => real().nullable()();

  /// Whether [proteinValue] is a percent of base energy.
  BoolColumn get proteinIsPercent => boolean().nullable()();

  /// Fat override value (with [fatIsPercent]), or `null`.
  RealColumn get fatValue => real().nullable()();

  /// Whether [fatValue] is a percent of base energy.
  BoolColumn get fatIsPercent => boolean().nullable()();

  /// Carbs override value (with [carbsIsPercent]), or `null`.
  RealColumn get carbsValue => real().nullable()();

  /// Whether [carbsValue] is a percent of base energy.
  BoolColumn get carbsIsPercent => boolean().nullable()();

  /// Daily fiber, g, or `null` for the default.
  RealColumn get fiberG => real().nullable()();

  /// Whether fat and carbs have no targets (TG-054).
  BoolColumn get caloriesProteinOnly => boolean()();
}

/// Sync entity of [Profiles].
const String profileEntity = 'profile';

/// Sync entity of [GoalPhases].
const String goalPhaseEntity = 'goalPhase';

/// Sync entity of [TargetSettingsRows].
const String targetSettingsEntity = 'targetSettings';
