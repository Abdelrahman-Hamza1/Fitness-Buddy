import 'package:fb_domain/system.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/sync/restore_version.dart';
import 'package:fb_mobile/core/sync/sync_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/misc.dart';

/// The provider overrides that wire the app together: the compile-time
/// [config], the router as the [AppNavigator] port (S06 plan A2), the
/// system clock and ID generator (the only import of
/// `fb_domain/system.dart`) and the change-op handlers of every feature
/// (A01 §3.2: the settings handler; A06: the diary's; A13: targets; A14:
/// weigh-ins; A22: chat messages; A23: proposals; A34: earlier versions)
/// and the sync codecs (A34).
///
/// Used by `main` and by tests that pump the whole app.
List<Override> appOverrides(AppConfig config) => [
  appConfigProvider.overrideWithValue(config),
  appNavigatorProvider.overrideWith((ref) => ref.watch(appRouterProvider)),
  // A notification's deep link is a router location (A40 D9).
  notificationLinkOpenerProvider.overrideWith(
    (ref) =>
        (location) => ref.read(appRouterProvider).openLocation(location),
  ),
  // The database attaches whichever pack the installer finds on disk (A05).
  catalogPackSourceProvider.overrideWith(
    (ref) => ref.watch(catalogPackInstallerProvider),
  ),
  // A33 D3/§6: the database opens the registry's active profile lazily,
  // after crash recovery of any interrupted account transition.
  activeProfileResolverProvider.overrideWith(
    (ref) => ref.read(accountTransitionsProvider).resolveActiveProfile,
  ),
  profileWriteGateProvider.overrideWith(
    (ref) => ref.watch(accountWriteGateProvider),
  ),
  clockProvider.overrideWithValue(const SystemClock()),
  idGeneratorProvider.overrideWithValue(systemUuidV7Generator()),
  // A34 D16: chat messages and proposals sync through their own mappers.
  syncCodecFactoryProvider.overrideWithValue(
    (db) => {...columnSyncCodecs(db.syncedTables), ...buddySyncCodecs(db)},
  ),
  changeOpHandlersProvider.overrideWithValue(
    (db) => [
      SettingsOpHandler(db.settingsKv),
      DiaryOpHandler(db),
      MealSlotOpHandler(db),
      PersonalFoodOpHandler(db),
      TargetsOpHandler(db),
      WeighInOpHandler(db),
      MeasurementOpHandler(db),
      ChatMessageOpHandler(db),
      ProposalOpHandler(db),
      WorkoutOpHandler(db),
      // A34 D14: restoring an earlier version (G7).
      RestoreVersionHandler(db, _syncCodecs(db)),
    ],
  ),
];

/// Every entity's sync codec (A34 D16): the generic column codecs, with
/// chat messages and proposals through their feature mappers.
Map<String, SyncEntityCodec> _syncCodecs(AppDatabase db) => {
  ...columnSyncCodecs(db.syncedTables),
  ...buddySyncCodecs(db),
};
