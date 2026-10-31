// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_platform.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [NotificationPlatform]; tests override it with a fake.

@ProviderFor(notificationPlatform)
final notificationPlatformProvider = NotificationPlatformProvider._();

/// The app's [NotificationPlatform]; tests override it with a fake.

final class NotificationPlatformProvider
    extends
        $FunctionalProvider<
          NotificationPlatform,
          NotificationPlatform,
          NotificationPlatform
        >
    with $Provider<NotificationPlatform> {
  /// The app's [NotificationPlatform]; tests override it with a fake.
  NotificationPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPlatformHash();

  @$internal
  @override
  $ProviderElement<NotificationPlatform> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationPlatform create(Ref ref) {
    return notificationPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPlatform>(value),
    );
  }
}

String _$notificationPlatformHash() =>
    r'e72a34b6af15bb88d93abcaefab836ea703409d7';
