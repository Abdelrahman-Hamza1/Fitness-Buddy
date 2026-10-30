// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_food_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether search may use the server catalog (A24 D1). On in the app; test
/// phones switch it off so their exact request logs and timers stay as is.

@ProviderFor(onlineFoodSearchEnabled)
final onlineFoodSearchEnabledProvider = OnlineFoodSearchEnabledProvider._();

/// Whether search may use the server catalog (A24 D1). On in the app; test
/// phones switch it off so their exact request logs and timers stay as is.

final class OnlineFoodSearchEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether search may use the server catalog (A24 D1). On in the app; test
  /// phones switch it off so their exact request logs and timers stay as is.
  OnlineFoodSearchEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineFoodSearchEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineFoodSearchEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return onlineFoodSearchEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onlineFoodSearchEnabledHash() =>
    r'c0e4385e79e41f8e36d8f7e06ccd3e1cc1681cb2';

/// The online leg's time source.

@ProviderFor(onlineSearchTime)
final onlineSearchTimeProvider = OnlineSearchTimeProvider._();

/// The online leg's time source.

final class OnlineSearchTimeProvider
    extends
        $FunctionalProvider<
          OnlineSearchTime,
          OnlineSearchTime,
          OnlineSearchTime
        >
    with $Provider<OnlineSearchTime> {
  /// The online leg's time source.
  OnlineSearchTimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineSearchTimeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineSearchTimeHash();

  @$internal
  @override
  $ProviderElement<OnlineSearchTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OnlineSearchTime create(Ref ref) {
    return onlineSearchTime(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnlineSearchTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnlineSearchTime>(value),
    );
  }
}

String _$onlineSearchTimeHash() => r'2517f3053274284a2e5aa414c77525f1f7df6cfc';

/// Foods seen in online results during this app run (A24 D4).

@ProviderFor(onlineFoodCache)
final onlineFoodCacheProvider = OnlineFoodCacheProvider._();

/// Foods seen in online results during this app run (A24 D4).

final class OnlineFoodCacheProvider
    extends
        $FunctionalProvider<OnlineFoodCache, OnlineFoodCache, OnlineFoodCache>
    with $Provider<OnlineFoodCache> {
  /// Foods seen in online results during this app run (A24 D4).
  OnlineFoodCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineFoodCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineFoodCacheHash();

  @$internal
  @override
  $ProviderElement<OnlineFoodCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OnlineFoodCache create(Ref ref) {
    return onlineFoodCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnlineFoodCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnlineFoodCache>(value),
    );
  }
}

String _$onlineFoodCacheHash() => r'1814e11ad86e8f0b384b1664d24b8073e15fc5ea';

/// Online leg of food search over the generated client (A24 D1).

@ProviderFor(onlineFoodSearch)
final onlineFoodSearchProvider = OnlineFoodSearchProvider._();

/// Online leg of food search over the generated client (A24 D1).

final class OnlineFoodSearchProvider
    extends
        $FunctionalProvider<
          OnlineFoodSearch,
          OnlineFoodSearch,
          OnlineFoodSearch
        >
    with $Provider<OnlineFoodSearch> {
  /// Online leg of food search over the generated client (A24 D1).
  OnlineFoodSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineFoodSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineFoodSearchHash();

  @$internal
  @override
  $ProviderElement<OnlineFoodSearch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OnlineFoodSearch create(Ref ref) {
    return onlineFoodSearch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnlineFoodSearch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnlineFoodSearch>(value),
    );
  }
}

String _$onlineFoodSearchHash() => r'aa66c638cb98f09ae175dc9d08988c046b6d55cb';
