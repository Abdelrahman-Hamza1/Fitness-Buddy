// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_tip.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weight card's suggestion state (WB-012, A14 D10). A preference that
/// can't be read or written never blocks the card: it reads as never shown,
/// and a failed write is dropped (the suggestion may show once more).

@ProviderFor(WeightTipController)
final weightTipControllerProvider = WeightTipControllerProvider._();

/// The weight card's suggestion state (WB-012, A14 D10). A preference that
/// can't be read or written never blocks the card: it reads as never shown,
/// and a failed write is dropped (the suggestion may show once more).
final class WeightTipControllerProvider
    extends $AsyncNotifierProvider<WeightTipController, CadenceTipState> {
  /// The weight card's suggestion state (WB-012, A14 D10). A preference that
  /// can't be read or written never blocks the card: it reads as never shown,
  /// and a failed write is dropped (the suggestion may show once more).
  WeightTipControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightTipControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightTipControllerHash();

  @$internal
  @override
  WeightTipController create() => WeightTipController();
}

String _$weightTipControllerHash() =>
    r'bc9929ec2517f28de8fc1c24b43188bf22242d64';

/// The weight card's suggestion state (WB-012, A14 D10). A preference that
/// can't be read or written never blocks the card: it reads as never shown,
/// and a failed write is dropped (the suggestion may show once more).

abstract class _$WeightTipController extends $AsyncNotifier<CadenceTipState> {
  FutureOr<CadenceTipState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CadenceTipState>, CadenceTipState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CadenceTipState>, CadenceTipState>,
              AsyncValue<CadenceTipState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
