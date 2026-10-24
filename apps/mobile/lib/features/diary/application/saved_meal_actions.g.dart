// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_meal_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-owned pending commands survive route disposal.

@ProviderFor(savedMealActions)
final savedMealActionsProvider = SavedMealActionsProvider._();

/// Session-owned pending commands survive route disposal.

final class SavedMealActionsProvider
    extends
        $FunctionalProvider<
          SavedMealActions,
          SavedMealActions,
          SavedMealActions
        >
    with $Provider<SavedMealActions> {
  /// Session-owned pending commands survive route disposal.
  SavedMealActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedMealActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedMealActionsHash();

  @$internal
  @override
  $ProviderElement<SavedMealActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SavedMealActions create(Ref ref) {
    return savedMealActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedMealActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedMealActions>(value),
    );
  }
}

String _$savedMealActionsHash() => r'29330855b10822ac84c4a5c0cf4e0c2540e42c6e';
