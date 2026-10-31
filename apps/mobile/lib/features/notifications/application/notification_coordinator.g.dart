// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether this build plans and schedules notifications. On in the app;
/// widget tests of other features keep it off (like the catalog update)
/// and the notification tests opt in.

@ProviderFor(notificationSchedulingEnabled)
final notificationSchedulingEnabledProvider =
    NotificationSchedulingEnabledProvider._();

/// Whether this build plans and schedules notifications. On in the app;
/// widget tests of other features keep it off (like the catalog update)
/// and the notification tests opt in.

final class NotificationSchedulingEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this build plans and schedules notifications. On in the app;
  /// widget tests of other features keep it off (like the catalog update)
  /// and the notification tests opt in.
  NotificationSchedulingEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSchedulingEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSchedulingEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return notificationSchedulingEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$notificationSchedulingEnabledHash() =>
    r'1f0da51edaf80ddfe5035902885c2463cb155f7f';

/// Opens a notification's deep link (a go_router location, NT-024). The
/// app wires it to the router (`lib/app/app_scope.dart`); features can't
/// import the router.

@ProviderFor(notificationLinkOpener)
final notificationLinkOpenerProvider = NotificationLinkOpenerProvider._();

/// Opens a notification's deep link (a go_router location, NT-024). The
/// app wires it to the router (`lib/app/app_scope.dart`); features can't
/// import the router.

final class NotificationLinkOpenerProvider
    extends
        $FunctionalProvider<
          Future<void> Function(String location),
          Future<void> Function(String location),
          Future<void> Function(String location)
        >
    with $Provider<Future<void> Function(String location)> {
  /// Opens a notification's deep link (a go_router location, NT-024). The
  /// app wires it to the router (`lib/app/app_scope.dart`); features can't
  /// import the router.
  NotificationLinkOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationLinkOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationLinkOpenerHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function(String location)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function(String location) create(Ref ref) {
    return notificationLinkOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function(String location) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<void> Function(String location)>(value),
    );
  }
}

String _$notificationLinkOpenerHash() =>
    r'245b7b6eff9053b50521be9c51449787df01f41e';

/// The app's [NotificationCoordinator]: one for the app's life. A profile
/// switch (sign-in, sign-out, account deletion, A33/A35) purges the old
/// profile's notifications; the inputs then re-read the new profile.

@ProviderFor(notificationCoordinator)
final notificationCoordinatorProvider = NotificationCoordinatorProvider._();

/// The app's [NotificationCoordinator]: one for the app's life. A profile
/// switch (sign-in, sign-out, account deletion, A33/A35) purges the old
/// profile's notifications; the inputs then re-read the new profile.

final class NotificationCoordinatorProvider
    extends
        $FunctionalProvider<
          NotificationCoordinator,
          NotificationCoordinator,
          NotificationCoordinator
        >
    with $Provider<NotificationCoordinator> {
  /// The app's [NotificationCoordinator]: one for the app's life. A profile
  /// switch (sign-in, sign-out, account deletion, A33/A35) purges the old
  /// profile's notifications; the inputs then re-read the new profile.
  NotificationCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationCoordinatorHash();

  @$internal
  @override
  $ProviderElement<NotificationCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationCoordinator create(Ref ref) {
    return notificationCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationCoordinator>(value),
    );
  }
}

String _$notificationCoordinatorHash() =>
    r'9f150b4ef6a15e0245a43ca003512bf9aa1297ee';

/// Whether Android lets the app show notifications (the Notifications
/// screen's banner). False when it can't tell.

@ProviderFor(notificationsAllowed)
final notificationsAllowedProvider = NotificationsAllowedProvider._();

/// Whether Android lets the app show notifications (the Notifications
/// screen's banner). False when it can't tell.

final class NotificationsAllowedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether Android lets the app show notifications (the Notifications
  /// screen's banner). False when it can't tell.
  NotificationsAllowedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsAllowedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsAllowedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return notificationsAllowed(ref);
  }
}

String _$notificationsAllowedHash() =>
    r'3ae982c2adcc5e167d0e03163a1b12cb1b6905a4';

/// The app's [NotificationPermission].

@ProviderFor(notificationPermission)
final notificationPermissionProvider = NotificationPermissionProvider._();

/// The app's [NotificationPermission].

final class NotificationPermissionProvider
    extends
        $FunctionalProvider<
          NotificationPermission,
          NotificationPermission,
          NotificationPermission
        >
    with $Provider<NotificationPermission> {
  /// The app's [NotificationPermission].
  NotificationPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPermissionHash();

  @$internal
  @override
  $ProviderElement<NotificationPermission> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationPermission create(Ref ref) {
    return notificationPermission(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPermission>(value),
    );
  }
}

String _$notificationPermissionHash() =>
    r'c6bbb92e5f06f6aa9e1fa7e70135fd6e35e597dd';
