import 'package:fb_domain/system.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/misc.dart';

/// The provider overrides that wire the app together: the compile-time
/// [config], the router as the [AppNavigator] port (S06 plan A2), the
/// system clock and ID generator (the only import of
/// `fb_domain/system.dart`) and the change-op handlers of every feature
/// (A01 §3.2: the settings handler; A06: the diary's; A13: targets; A14:
/// weigh-ins).
///
/// Used by `main` and by tests that pump the whole app.
List<Override> appOverrides(AppConfig config) => [
  appConfigProvider.overrideWithValue(config),
  appNavigatorProvider.overrideWith((ref) => ref.watch(appRouterProvider)),
  // The database attaches whichever pack the installer finds on disk (A05).
  catalogPackSourceProvider.overrideWith(
    (ref) => ref.watch(catalogPackInstallerProvider),
  ),
  clockProvider.overrideWithValue(const SystemClock()),
  idGeneratorProvider.overrideWithValue(systemUuidV7Generator()),
  changeOpHandlersProvider.overrideWithValue(
    (db) => [
      SettingsOpHandler(db.settingsKv),
      DiaryOpHandler(db),
      MealSlotOpHandler(db),
      PersonalFoodOpHandler(db),
      TargetsOpHandler(db),
      WeighInOpHandler(db),
    ],
  ),
];
