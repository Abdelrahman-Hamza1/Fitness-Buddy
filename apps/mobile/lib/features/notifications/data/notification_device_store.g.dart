// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_device_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [NotificationDeviceStore]; tests override it in memory.

@ProviderFor(notificationDeviceStore)
final notificationDeviceStoreProvider = NotificationDeviceStoreProvider._();

/// The app's [NotificationDeviceStore]; tests override it in memory.

final class NotificationDeviceStoreProvider
    extends
        $FunctionalProvider<
          NotificationDeviceStore,
          NotificationDeviceStore,
          NotificationDeviceStore
        >
    with $Provider<NotificationDeviceStore> {
  /// The app's [NotificationDeviceStore]; tests override it in memory.
  NotificationDeviceStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationDeviceStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationDeviceStoreHash();

  @$internal
  @override
  $ProviderElement<NotificationDeviceStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationDeviceStore create(Ref ref) {
    return notificationDeviceStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationDeviceStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationDeviceStore>(value),
    );
  }
}

String _$notificationDeviceStoreHash() =>
    r'44be21adcb068320c06d380b3d00b9a48a912e84';
