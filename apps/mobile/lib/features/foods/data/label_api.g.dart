// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The label route on the app dio.

@ProviderFor(labelApi)
final labelApiProvider = LabelApiProvider._();

/// The label route on the app dio.

final class LabelApiProvider
    extends $FunctionalProvider<LabelApi, LabelApi, LabelApi>
    with $Provider<LabelApi> {
  /// The label route on the app dio.
  LabelApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelApiHash();

  @$internal
  @override
  $ProviderElement<LabelApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LabelApi create(Ref ref) {
    return labelApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabelApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabelApi>(value),
    );
  }
}

String _$labelApiHash() => r'5f9502b76b2b4cff768e4c264d20eb04005dcb5e';
