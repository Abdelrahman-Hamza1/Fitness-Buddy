// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_food_prefill.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Private one-shot handoff. Names never enter route parameters (A09 D9).

@ProviderFor(NewFoodPrefill)
final newFoodPrefillProvider = NewFoodPrefillProvider._();

/// Private one-shot handoff. Names never enter route parameters (A09 D9).
final class NewFoodPrefillProvider
    extends $NotifierProvider<NewFoodPrefill, String?> {
  /// Private one-shot handoff. Names never enter route parameters (A09 D9).
  NewFoodPrefillProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newFoodPrefillProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newFoodPrefillHash();

  @$internal
  @override
  NewFoodPrefill create() => NewFoodPrefill();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$newFoodPrefillHash() => r'e1481e11bb1735c93c40a88e093c6912a297a3ae';

/// Private one-shot handoff. Names never enter route parameters (A09 D9).

abstract class _$NewFoodPrefill extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
