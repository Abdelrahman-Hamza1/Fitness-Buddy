// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which palette variant the app wears (A02 D16). Always [FbPaletteVariant.a]
/// until the design preview (dev flavor only) switches it; in memory, never
/// persisted: the pick is temporary by design (A02 D3).
///
/// Lives in `core/` rather than `app/theme/` so that `app/app.dart` can watch
/// it and the design preview feature can set it: features may not import
/// `app/` (app_check rule 5).

@ProviderFor(ThemeVariant)
final themeVariantProvider = ThemeVariantProvider._();

/// Which palette variant the app wears (A02 D16). Always [FbPaletteVariant.a]
/// until the design preview (dev flavor only) switches it; in memory, never
/// persisted: the pick is temporary by design (A02 D3).
///
/// Lives in `core/` rather than `app/theme/` so that `app/app.dart` can watch
/// it and the design preview feature can set it: features may not import
/// `app/` (app_check rule 5).
final class ThemeVariantProvider
    extends $NotifierProvider<ThemeVariant, FbPaletteVariant> {
  /// Which palette variant the app wears (A02 D16). Always [FbPaletteVariant.a]
  /// until the design preview (dev flavor only) switches it; in memory, never
  /// persisted: the pick is temporary by design (A02 D3).
  ///
  /// Lives in `core/` rather than `app/theme/` so that `app/app.dart` can watch
  /// it and the design preview feature can set it: features may not import
  /// `app/` (app_check rule 5).
  ThemeVariantProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeVariantProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeVariantHash();

  @$internal
  @override
  ThemeVariant create() => ThemeVariant();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FbPaletteVariant value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FbPaletteVariant>(value),
    );
  }
}

String _$themeVariantHash() => r'bb4765e68de68dc8674f359cad6a9cffa07ab251';

/// Which palette variant the app wears (A02 D16). Always [FbPaletteVariant.a]
/// until the design preview (dev flavor only) switches it; in memory, never
/// persisted: the pick is temporary by design (A02 D3).
///
/// Lives in `core/` rather than `app/theme/` so that `app/app.dart` can watch
/// it and the design preview feature can set it: features may not import
/// `app/` (app_check rule 5).

abstract class _$ThemeVariant extends $Notifier<FbPaletteVariant> {
  FbPaletteVariant build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FbPaletteVariant, FbPaletteVariant>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FbPaletteVariant, FbPaletteVariant>,
              FbPaletteVariant,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Light, dark or follow the system (UX-040). [ThemeMode.system] until the
/// design preview switches it; in memory, never persisted.

@ProviderFor(ThemeModeSetting)
final themeModeProvider = ThemeModeSettingProvider._();

/// Light, dark or follow the system (UX-040). [ThemeMode.system] until the
/// design preview switches it; in memory, never persisted.
final class ThemeModeSettingProvider
    extends $NotifierProvider<ThemeModeSetting, ThemeMode> {
  /// Light, dark or follow the system (UX-040). [ThemeMode.system] until the
  /// design preview switches it; in memory, never persisted.
  ThemeModeSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeSettingHash();

  @$internal
  @override
  ThemeModeSetting create() => ThemeModeSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeSettingHash() => r'4cf1be071b801987e66c764ecd777a42207f80a1';

/// Light, dark or follow the system (UX-040). [ThemeMode.system] until the
/// design preview switches it; in memory, never persisted.

abstract class _$ThemeModeSetting extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
