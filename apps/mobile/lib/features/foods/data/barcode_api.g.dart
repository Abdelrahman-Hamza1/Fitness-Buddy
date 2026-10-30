// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The barcode client over the app's API.

@ProviderFor(barcodeApi)
final barcodeApiProvider = BarcodeApiProvider._();

/// The barcode client over the app's API.

final class BarcodeApiProvider
    extends $FunctionalProvider<BarcodeApi, BarcodeApi, BarcodeApi>
    with $Provider<BarcodeApi> {
  /// The barcode client over the app's API.
  BarcodeApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'barcodeApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$barcodeApiHash();

  @$internal
  @override
  $ProviderElement<BarcodeApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BarcodeApi create(Ref ref) {
    return barcodeApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BarcodeApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BarcodeApi>(value),
    );
  }
}

String _$barcodeApiHash() => r'285a2dd741b2b908127b9c312d2681a48076a646';
