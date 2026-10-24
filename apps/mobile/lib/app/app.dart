import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/bootstrap/app_bootstrap.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/app/theme/app_theme.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/settings.dart';
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
  /// Whether the first frame is done. The theme setting is read only after
  /// it (UX-001: no storage before the first frame), so that frame uses the
  /// system theme.
  bool _firstFrameDone = false;

  /// Whether the first stored theme has been applied. It applies without the
  /// theme animation (D6); later changes animate.
  bool _themeSettled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _firstFrameDone = true);
      unawaited(ref.read(appBootstrapProvider).afterFirstFrame());
    });
  }

  ThemeMode _themeMode() {
    if (!_firstFrameDone) return ThemeMode.system;
    final preference = ref.watch(themePreferenceProvider);
    if (preference.hasValue && !_themeSettled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _themeSettled = true);
    }
    return switch (preference.value) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.system || null => ThemeMode.system,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider).config,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // The stored choice (UX-040); the system's until it is read.
      themeMode: _themeMode(),
      themeAnimationDuration: _themeSettled
          ? kThemeAnimationDuration
          : Duration.zero,
      localizationsDelegates: FitnessBuddyApp.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
