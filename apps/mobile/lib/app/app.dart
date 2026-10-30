import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/bootstrap/app_bootstrap.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/app/theme/app_theme.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
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
  /// setting's default: light (D-083, TD-107), like the Android launch
  /// window.
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
    // Not read yet, loading or unreadable: the default (light), never storage.
    if (!_firstFrameDone) return _modeOf(AppSettings.theme.defaultValue);
    final preference = ref.watch(themePreferenceProvider);
    if (preference.hasValue && !_themeSettled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _themeSettled = true);
    }
    return _modeOf(preference.value ?? AppSettings.theme.defaultValue);
  }

  static ThemeMode _modeOf(ThemePreference preference) => switch (preference) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system => ThemeMode.system,
  };

  /// The system bars follow the app's theme, not the phone's (A44 D8): the
  /// native window is light (TD-107), and Today has no app bar to set them.
  /// The status bar is transparent. Below Android 15 the app isn't
  /// edge-to-edge, so the navigation bar gets the theme's bottom-bar colour
  /// (a transparent one would show the light window behind Dark's light
  /// icons); Android 15+ ignores the colour. Icons contrast with the theme.
  static Widget _systemBars(BuildContext context, Widget? child) =>
      AccountBusyScope(child: _bars(context, child));

  static Widget _bars(BuildContext context, Widget? child) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000),
        systemNavigationBarColor:
            theme.navigationBarTheme.backgroundColor ??
            theme.colorScheme.surfaceContainer,
        statusBarIconBrightness: icons,
        systemNavigationBarIconBrightness: icons,
        // iOS reads the bar's background brightness instead.
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // A33 re-check 3: a profile switch starts a new generation; the whole
      // tree (routes, sheets, open drafts) is rebuilt for it, so no form
      // opened for the old profile survives to save into the new one.
      key: ValueKey(ref.watch(profileGenerationProvider)),
      routerConfig: ref.watch(appRouterProvider).config,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // The stored choice (UX-040); the default (light) until it is read.
      themeMode: _themeMode(),
      themeAnimationDuration: _themeSettled
          ? kThemeAnimationDuration
          : Duration.zero,
      localizationsDelegates: FitnessBuddyApp.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: _systemBars,
    );
  }
}
