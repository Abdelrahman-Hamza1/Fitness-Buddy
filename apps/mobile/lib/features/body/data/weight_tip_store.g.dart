// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_tip_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [WeightTipStore].

@ProviderFor(weightTipStore)
final weightTipStoreProvider = WeightTipStoreProvider._();

/// The app's [WeightTipStore].

final class WeightTipStoreProvider
    extends $FunctionalProvider<WeightTipStore, WeightTipStore, WeightTipStore>
    with $Provider<WeightTipStore> {
  /// The app's [WeightTipStore].
  WeightTipStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightTipStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightTipStoreHash();

  @$internal
  @override
  $ProviderElement<WeightTipStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeightTipStore create(Ref ref) {
    return weightTipStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeightTipStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeightTipStore>(value),
    );
  }
}

String _$weightTipStoreHash() => r'f6a7197c5bf7431683b92916010d0519bb487c84';
