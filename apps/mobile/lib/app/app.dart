import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/bootstrap/app_bootstrap.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/app/theme/app_theme.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/theme/theme_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The root widget: theme, localization and the router.
///
/// After its first frame it starts the deferred work (`AppBootstrap`):
/// nothing before the first frame touches the network or storage (UX-001).
class FitnessBuddyApp extends ConsumerStatefulWidget {
  /// Creates the app. Needs the overrides of `appOverrides` above it.
  const new({super.key});

  /// The delegates the app uses (S06 plan D15, LC-002). The Material, Cupertino
  /// and widgets delegates come from material_ui: the generated
  /// `AppLocalizations.localizationsDelegates` lists flutter_localizations'
  /// classes, which material_ui widgets don't read. `FbLocalizations` holds
  /// the design system's built-in strings (A02 D5).
  static const localizationsDelegates = <LocalizationsDelegate<Object?>>[
    AppLocalizations.delegate,
    FbLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ];

  @override
  ConsumerState<FitnessBuddyApp> createState() => _FitnessBuddyAppState();
}

class _FitnessBuddyAppState extends ConsumerState<FitnessBuddyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(appBootstrapProvider).afterFirstFrame());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider).config,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // ThemeMode.system by default: light/dark follows the system setting
      // (UX-040).
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: FitnessBuddyApp.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
