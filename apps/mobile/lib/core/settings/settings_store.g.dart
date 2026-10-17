// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open profile's settings.

@ProviderFor(settingsStore)
final settingsStoreProvider = SettingsStoreProvider._();

/// The open profile's settings.

final class SettingsStoreProvider
    extends $FunctionalProvider<SettingsStore, SettingsStore, SettingsStore>
    with $Provider<SettingsStore> {
  /// The open profile's settings.
  SettingsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStoreHash();

  @$internal
  @override
  $ProviderElement<SettingsStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsStore create(Ref ref) {
    return settingsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsStore>(value),
    );
  }
}

String _$settingsStoreHash() => r'2f01f46f3752b9164702521502d478e79eb3fb30';
