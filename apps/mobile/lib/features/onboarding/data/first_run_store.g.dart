// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_run_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [FirstRunStore].

@ProviderFor(firstRunStore)
final firstRunStoreProvider = FirstRunStoreProvider._();

/// The app's [FirstRunStore].

final class FirstRunStoreProvider
    extends $FunctionalProvider<FirstRunStore, FirstRunStore, FirstRunStore>
    with $Provider<FirstRunStore> {
  /// The app's [FirstRunStore].
  FirstRunStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstRunStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstRunStoreHash();

  @$internal
  @override
  $ProviderElement<FirstRunStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirstRunStore create(Ref ref) {
    return firstRunStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirstRunStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirstRunStore>(value),
    );
  }
}

String _$firstRunStoreHash() => r'c2ce6970bb1243b3b26c8e392f1fecc7cfd0a858';
