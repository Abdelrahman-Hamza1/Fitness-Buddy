// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-owned commands survive the source day being evicted (D14).

@ProviderFor(QuickAddController)
final quickAddControllerProvider = QuickAddControllerProvider._();

/// Session-owned commands survive the source day being evicted (D14).
final class QuickAddControllerProvider
    extends $NotifierProvider<QuickAddController, Set<String>> {
  /// Session-owned commands survive the source day being evicted (D14).
  QuickAddControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddControllerHash();

  @$internal
  @override
  QuickAddController create() => QuickAddController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$quickAddControllerHash() =>
    r'3b09134d8f107eba414c08c25940c17155b2ba86';

/// Session-owned commands survive the source day being evicted (D14).

abstract class _$QuickAddController extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Session-owned LogFood dependencies for a command that outlives its row.

@ProviderFor(quickAddLogFood)
final quickAddLogFoodProvider = QuickAddLogFoodProvider._();

/// Session-owned LogFood dependencies for a command that outlives its row.

final class QuickAddLogFoodProvider
    extends $FunctionalProvider<LogFood, LogFood, LogFood>
    with $Provider<LogFood> {
  /// Session-owned LogFood dependencies for a command that outlives its row.
  QuickAddLogFoodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddLogFoodProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddLogFoodHash();

  @$internal
  @override
  $ProviderElement<LogFood> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogFood create(Ref ref) {
    return quickAddLogFood(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogFood value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogFood>(value),
    );
  }
}

String _$quickAddLogFoodHash() => r'b75b079610aa1d01313a8f04377b0439d89d597f';
