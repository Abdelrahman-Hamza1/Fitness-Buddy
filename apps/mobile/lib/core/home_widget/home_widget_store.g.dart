// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [HomeWidgetStore]; tests override it.

@ProviderFor(homeWidgetStore)
final homeWidgetStoreProvider = HomeWidgetStoreProvider._();

/// The app's [HomeWidgetStore]; tests override it.

final class HomeWidgetStoreProvider
    extends
        $FunctionalProvider<HomeWidgetStore, HomeWidgetStore, HomeWidgetStore>
    with $Provider<HomeWidgetStore> {
  /// The app's [HomeWidgetStore]; tests override it.
  HomeWidgetStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetStoreHash();

  @$internal
  @override
  $ProviderElement<HomeWidgetStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeWidgetStore create(Ref ref) {
    return homeWidgetStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeWidgetStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeWidgetStore>(value),
    );
  }
}

String _$homeWidgetStoreHash() => r'911061cca55f7bd28948713e135e3110eb3bec9b';

/// The open profile's widget tag (A71 D5), re-read on every profile switch;
/// `local` before any switch (like the notification tag).

@ProviderFor(homeWidgetProfile)
final homeWidgetProfileProvider = HomeWidgetProfileProvider._();

/// The open profile's widget tag (A71 D5), re-read on every profile switch;
/// `local` before any switch (like the notification tag).

final class HomeWidgetProfileProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The open profile's widget tag (A71 D5), re-read on every profile switch;
  /// `local` before any switch (like the notification tag).
  HomeWidgetProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetProfileHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return homeWidgetProfile(ref);
  }
}

String _$homeWidgetProfileHash() => r'39782326e4b84aec9a979e71311503a3797baea2';
