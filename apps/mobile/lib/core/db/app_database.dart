import 'dart:io';

import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';
import 'package:fb_mobile/core/db/catalog/catalog_pack_source.dart';
import 'package:fb_mobile/core/db/migrations/from_10_to_11.dart';
import 'package:fb_mobile/core/db/migrations/from_1_to_2.dart';
import 'package:fb_mobile/core/db/migrations/from_2_to_3.dart';
import 'package:fb_mobile/core/db/migrations/from_3_to_4.dart';
import 'package:fb_mobile/core/db/migrations/from_4_to_5.dart';
import 'package:fb_mobile/core/db/migrations/from_5_to_6.dart';
import 'package:fb_mobile/core/db/migrations/from_6_to_7.dart';
import 'package:fb_mobile/core/db/migrations/from_7_to_8.dart';
import 'package:fb_mobile/core/db/migrations/from_8_to_9.dart';
import 'package:fb_mobile/core/db/migrations/from_9_to_10.dart';
import 'package:fb_mobile/core/db/seeds/default_slots_seed.dart';
import 'package:fb_mobile/core/db/synced_tables.dart';
import 'package:fb_mobile/core/db/tables/body_tables.dart';
import 'package:fb_mobile/core/db/tables/chat_tables.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
import 'package:fb_mobile/core/db/tables/food_tables.dart';
import 'package:fb_mobile/core/db/tables/settings_tables.dart';
import 'package:fb_mobile/core/db/tables/sync_tables.dart';
import 'package:fb_mobile/core/db/tables/target_tables.dart';
import 'package:fb_mobile/core/db/tables/workout_tables.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/db/write_guarded.dart';

part 'app_database.g.dart';

/// Reports a catalog pack that couldn't be attached. Gets the error only,
/// never row values.
typedef CatalogErrorHandler = void Function(Object error, StackTrace stack);

/// The profile's local database, `user.db` (A01 D13-D15, `05` §1-3).
///
/// Every write statement goes through [WriteGuard]: only the single writer
/// (`core/db/write/`, inside `runAuthorizedWrite`) gets through.
///
/// Schema changes: change the tables, bump [schemaVersion], run
/// `make db-migrations`, and write the step in
/// `migrations/from_<n>_to_<n+1>.dart` (A01 D15). Shipped dumps and steps are
/// frozen (`tools/scripts/check-frozen-migrations.sh`).
@DriftDatabase(
  tables: [
    SyncState,
    SyncOutbox,
    SettingsKv,
    MealSlots,
    DishGroups,
    DiaryEntries,
    DayMarks,
    SavedMeals,
    SavedMealItems,
    PersonalFoods,
    Profiles,
    GoalPhases,
    TargetSettingsRows,
    WeighIns,
    MeasurementTypes,
    Measurements,
    ChatMessages,
    Proposals,
    CustomExercises,
    WorkoutSessions,
    SessionExercises,
    WorkoutSets,
    WorkoutTemplates,
    WorkoutTemplateItems,
    WeeklyPlanDays,
  ],
  include: {
    'sync_triggers.drift',
    'diary.drift',
    'targets.drift',
    'body.drift',
    'chat.drift',
    'workout.drift',
  },
)
final class AppDatabase extends _$AppDatabase with WriteGuarded {
  /// The database over [executor], guarded by [WriteGuard]. [catalog] says
  /// which pack to attach read-only when it opens; `onCatalogError` hears
  /// about a pack that couldn't be attached (the database still opens, the
  /// catalog is just absent).
  new(
    QueryExecutor executor, {
    this.catalog = const NoCatalogPack(),
    this._onCatalogError,
  }) : super(executor.interceptWith(WriteGuard()));

  /// The schema name of the attached catalog pack (A01 D14).
  static const String catalogSchema = 'catalog';

  /// Where the catalog pack is.
  final CatalogPackSource catalog;

  final CatalogErrorHandler? _onCatalogError;

  /// The tables that sync, with their entity wire names (A01 D16).
  late final List<SyncedTable<Table, Object?>> syncedTables = [
    SyncedTable<$PersonalFoodsTable, PersonalFoodRow>(
      personalFoods,
      personalFoodEntity,
    ),
    SyncedTable<$SettingsKvTable, SettingRow>(settingsKv, settingEntity),
    SyncedTable<$MealSlotsTable, MealSlotRow>(mealSlots, mealSlotEntity),
    SyncedTable<$DishGroupsTable, DishGroupRow>(dishGroups, dishGroupEntity),
    SyncedTable<$DiaryEntriesTable, DiaryEntryRow>(
      diaryEntries,
      diaryEntryEntity,
    ),
    SyncedTable<$DayMarksTable, DayMarkRow>(dayMarks, dayMarkEntity),
    SyncedTable<$SavedMealsTable, SavedMealRow>(savedMeals, savedMealEntity),
    SyncedTable<$SavedMealItemsTable, SavedMealItemRow>(
      savedMealItems,
      savedMealItemEntity,
    ),
    SyncedTable<$ProfilesTable, ProfileRow>(profiles, profileEntity),
    SyncedTable<$GoalPhasesTable, GoalPhaseRow>(goalPhases, goalPhaseEntity),
    SyncedTable<$TargetSettingsRowsTable, TargetSettingsRow>(
      targetSettingsRows,
      targetSettingsEntity,
    ),
    SyncedTable<$WeighInsTable, WeighInRow>(weighIns, weighInEntity),
    SyncedTable<$MeasurementTypesTable, MeasurementTypeRow>(
      measurementTypes,
      measurementTypeEntity,
    ),
    SyncedTable<$MeasurementsTable, MeasurementRow>(
      measurements,
      measurementEntity,
    ),
    SyncedTable<$ChatMessagesTable, ChatMessageRow>(
      chatMessages,
      chatMessageEntity,
    ),
    SyncedTable<$ProposalsTable, ProposalRow>(proposals, proposalEntity),
    SyncedTable<$CustomExercisesTable, CustomExerciseRow>(
      customExercises,
      customExerciseEntity,
    ),
    SyncedTable<$WorkoutSessionsTable, WorkoutSessionRow>(
      workoutSessions,
      workoutSessionEntity,
    ),
    SyncedTable<$SessionExercisesTable, SessionExerciseRow>(
      sessionExercises,
      sessionExerciseEntity,
    ),
    SyncedTable<$WorkoutSetsTable, WorkoutSetRow>(
      workoutSets,
      workoutSetEntity,
    ),
    SyncedTable<$WorkoutTemplatesTable, WorkoutTemplateRow>(
      workoutTemplates,
      workoutTemplateEntity,
    ),
    SyncedTable<$WorkoutTemplateItemsTable, WorkoutTemplateItemRow>(
      workoutTemplateItems,
      workoutTemplateItemEntity,
    ),
    SyncedTable<$WeeklyPlanDaysTable, WeeklyPlanDayRow>(
      weeklyPlanDays,
      weeklyPlanDayEntity,
    ),
  ];

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaultSlots(this, mealSlots);
    },
    onUpgrade: stepByStep(
      from1To2: from1To2,
      from2To3: from2To3,
      from3To4: from3To4,
      from4To5: from4To5,
      from5To6: from5To6,
      from6To7: from6To7,
      from7To8: from7To8,
      from8To9: from8To9,
      from9To10: from9To10,
      from10To11: from10To11,
    ),
    beforeOpen: (details) async {
      // drift runs this on the executor it's opening, below the guard (the
      // token is set anyway, so it never depends on that).
      await runAuthorizedWrite(() async {
        // Capture is on whenever the database opens: '0' is only ever set
        // inside one transaction (seeds, A34's remote apply).
        await customStatement(
          "INSERT INTO sync_state (key, value) VALUES ('outbox.capture', '1') "
          "ON CONFLICT (key) DO UPDATE SET value = '1' WHERE value IS NOT '1'",
        );
        // A pack that can't be attached never stops the diary from opening
        // (local-first): it's reported and the catalog is just absent.
        try {
          final pack = await catalog.currentPackPath();
          if (pack != null) await _attachCatalog(pack);
        } on Exception catch (error, stack) {
          _onCatalogError?.call(error, stack);
        }
      });
    },
  );

  /// Consistent multi-query reads without granting the writer's zone token.
  /// WriteGuard rejects writes unless the caller is already inside
  /// runAuthorizedWrite: the transaction's forked zone inherits that token.
  Future<T> readSnapshot<T>(Future<T> Function() read) => transaction(read);

  /// Whether a catalog pack is attached as [catalogSchema].
  Future<bool> isCatalogAttached() async {
    final rows = await customSelect(
      'SELECT 1 FROM pragma_database_list WHERE name = ?',
      variables: [Variable.withString(catalogSchema)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Swaps the attached pack for the one at [packPath] (`null`: detach only),
  /// for A05/A24's atomic pack swap. Must run outside any transaction. A
  /// pack that can't be attached throws (and leaves none attached).
  Future<void> reattachCatalog(String? packPath) =>
      runAuthorizedWrite(() async {
        if (await isCatalogAttached()) {
          await customStatement('DETACH DATABASE $catalogSchema');
        }
        try {
          if (packPath != null) await _attachCatalog(packPath);
        } finally {
          // A read-model invalidation, not user data: A07 refreshes catalog
          // vocabulary off the keystroke path after a swap or failed attach.
          notifyUpdates({const TableUpdate('catalog_pack')});
        }
      });

  /// Attaches [packPath] read-only and immutable (A01 D14). The connection
  /// is opened with URI filenames on (`connection.dart`), else SQLite would
  /// refuse the `file:` name. Throws [CatalogAttachException] for a path
  /// that isn't absolute (SQLite would take it as a plain, writable file
  /// name, ignoring `mode=ro`) or a file that doesn't exist.
  Future<void> _attachCatalog(String packPath) async {
    final uri = '${Uri.file(packPath)}';
    if (!uri.startsWith('file:///')) {
      throw const CatalogAttachException('the pack path is not absolute');
    }
    if (!File(packPath).existsSync()) {
      throw const CatalogAttachException('the pack file does not exist');
    }
    await customStatement('ATTACH DATABASE ? AS $catalogSchema', [
      '$uri?mode=ro&immutable=1',
    ]);
  }
}
