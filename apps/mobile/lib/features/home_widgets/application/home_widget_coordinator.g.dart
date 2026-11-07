// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether this build feeds the home-screen widgets. On in the app; widget
/// tests of other features keep it off.

@ProviderFor(homeWidgetsEnabled)
final homeWidgetsEnabledProvider = HomeWidgetsEnabledProvider._();

/// Whether this build feeds the home-screen widgets. On in the app; widget
/// tests of other features keep it off.

final class HomeWidgetsEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this build feeds the home-screen widgets. On in the app; widget
  /// tests of other features keep it off.
  HomeWidgetsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetsEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetsEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return homeWidgetsEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$homeWidgetsEnabledHash() =>
    r'f7e28d86976e5320da8835a50aadfdae643f605b';

/// Opens a router location for a widget tap. The app wires it to the
/// router (`lib/app/app_scope.dart`); features can't import the router.

@ProviderFor(homeWidgetLinkOpener)
final homeWidgetLinkOpenerProvider = HomeWidgetLinkOpenerProvider._();

/// Opens a router location for a widget tap. The app wires it to the
/// router (`lib/app/app_scope.dart`); features can't import the router.

final class HomeWidgetLinkOpenerProvider
    extends
        $FunctionalProvider<
          Future<void> Function(String location),
          Future<void> Function(String location),
          Future<void> Function(String location)
        >
    with $Provider<Future<void> Function(String location)> {
  /// Opens a router location for a widget tap. The app wires it to the
  /// router (`lib/app/app_scope.dart`); features can't import the router.
  HomeWidgetLinkOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetLinkOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetLinkOpenerHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function(String location)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function(String location) create(Ref ref) {
    return homeWidgetLinkOpener(ref);
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

String _$homeWidgetLinkOpenerHash() =>
    r'ff8a79ac47a124da0998bbad9e8b1e95b1dacb88';

/// The app's [HomeWidgetCoordinator]: one for the app's life.

@ProviderFor(homeWidgetCoordinator)
final homeWidgetCoordinatorProvider = HomeWidgetCoordinatorProvider._();

/// The app's [HomeWidgetCoordinator]: one for the app's life.

final class HomeWidgetCoordinatorProvider
    extends
        $FunctionalProvider<
          HomeWidgetCoordinator,
          HomeWidgetCoordinator,
          HomeWidgetCoordinator
        >
    with $Provider<HomeWidgetCoordinator> {
  /// The app's [HomeWidgetCoordinator]: one for the app's life.
  HomeWidgetCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetCoordinatorHash();

  @$internal
  @override
  $ProviderElement<HomeWidgetCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeWidgetCoordinator create(Ref ref) {
    return homeWidgetCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeWidgetCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeWidgetCoordinator>(value),
    );
  }
}

String _$homeWidgetCoordinatorHash() =>
    r'12f6218d3708146f395a01a5dba89bcd31a986d8';
