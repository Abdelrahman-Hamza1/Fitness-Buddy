import 'package:fb_domain/system.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_riverpod/misc.dart';

/// The provider overrides that wire the app together: the compile-time
/// [config], the router as the [AppNavigator] port (S06 plan A2) and the
/// system ID generator (the only import of `fb_domain/system.dart`).
///
/// Used by `main` and by tests that pump the whole app.
List<Override> appOverrides(AppConfig config) => [
  appConfigProvider.overrideWithValue(config),
  appNavigatorProvider.overrideWith((ref) => ref.watch(appRouterProvider)),
  idGeneratorProvider.overrideWithValue(systemUuidV7Generator()),
];
