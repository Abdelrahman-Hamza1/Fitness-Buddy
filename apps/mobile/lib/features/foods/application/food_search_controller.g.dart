// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One running search + one replaceable pending request, without debounce.

@ProviderFor(FoodSearchController)
final foodSearchControllerProvider = FoodSearchControllerProvider._();

/// One running search + one replaceable pending request, without debounce.
final class FoodSearchControllerProvider
    extends $NotifierProvider<FoodSearchController, FoodSearchState> {
  /// One running search + one replaceable pending request, without debounce.
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
    r'872d3d4bc8721dbdcbfdc671aadbd9df5be90691';

/// One running search + one replaceable pending request, without debounce.

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
