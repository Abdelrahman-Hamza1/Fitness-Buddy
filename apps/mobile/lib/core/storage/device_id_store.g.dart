// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_id_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [DeviceIdStore].

@ProviderFor(deviceIdStore)
final deviceIdStoreProvider = DeviceIdStoreProvider._();

/// The app's [DeviceIdStore].

final class DeviceIdStoreProvider
    extends $FunctionalProvider<DeviceIdStore, DeviceIdStore, DeviceIdStore>
    with $Provider<DeviceIdStore> {
  /// The app's [DeviceIdStore].
  DeviceIdStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdStoreHash();

  @$internal
  @override
  $ProviderElement<DeviceIdStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceIdStore create(Ref ref) {
    return deviceIdStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceIdStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceIdStore>(value),
    );
  }
}

String _$deviceIdStoreHash() => r'320c5cbff106c2e5d4350be5c0c6aff156153a12';
