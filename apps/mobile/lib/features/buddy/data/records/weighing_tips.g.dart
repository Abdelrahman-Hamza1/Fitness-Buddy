// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weighing_tips.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's weighing tips.

@ProviderFor(weighingTips)
final weighingTipsProvider = WeighingTipsProvider._();

/// The app's weighing tips.

final class WeighingTipsProvider
    extends $FunctionalProvider<WeighingTips, WeighingTips, WeighingTips>
    with $Provider<WeighingTips> {
  /// The app's weighing tips.
  WeighingTipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weighingTipsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weighingTipsHash();

  @$internal
  @override
  $ProviderElement<WeighingTips> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeighingTips create(Ref ref) {
    return weighingTips(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeighingTips value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeighingTips>(value),
    );
  }
}

String _$weighingTipsHash() => r'7e21b825f4af6fdfd73c53697b4ef2caa1a84c24';
