// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One running search + one replaceable pending request, without debounce.
///
/// After local results for a query are on screen, an online search for the
/// same query runs after [onlineDelay] and its new foods are appended (A24
/// D1/D2). Local results never wait for it; a failed online leg changes
/// nothing.

@ProviderFor(FoodSearchController)
final foodSearchControllerProvider = FoodSearchControllerProvider._();

/// One running search + one replaceable pending request, without debounce.
///
/// After local results for a query are on screen, an online search for the
/// same query runs after [onlineDelay] and its new foods are appended (A24
/// D1/D2). Local results never wait for it; a failed online leg changes
/// nothing.
final class FoodSearchControllerProvider
    extends $NotifierProvider<FoodSearchController, FoodSearchState> {
  /// One running search + one replaceable pending request, without debounce.
  ///
  /// After local results for a query are on screen, an online search for the
  /// same query runs after [onlineDelay] and its new foods are appended (A24
  /// D1/D2). Local results never wait for it; a failed online leg changes
  /// nothing.
  FoodSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodSearchControllerHash();

  @$internal
  @override
  FoodSearchController create() => FoodSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodSearchState>(value),
    );
  }
}

String _$foodSearchControllerHash() =>
    r'f4615832ac736ae8c7fbd77a597e4caf384ea64d';

/// One running search + one replaceable pending request, without debounce.
///
/// After local results for a query are on screen, an online search for the
/// same query runs after [onlineDelay] and its new foods are appended (A24
/// D1/D2). Local results never wait for it; a failed online leg changes
/// nothing.

abstract class _$FoodSearchController extends $Notifier<FoodSearchState> {
  FoodSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FoodSearchState, FoodSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FoodSearchState, FoodSearchState>,
              FoodSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
