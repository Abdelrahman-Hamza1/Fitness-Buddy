// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_run_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the first run may show at all: off in device and widget tests
/// that start the whole app for something else (TD-110).

@ProviderFor(firstRunEnabled)
final firstRunEnabledProvider = FirstRunEnabledProvider._();

/// Whether the first run may show at all: off in device and widget tests
/// that start the whole app for something else (TD-110).

final class FirstRunEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the first run may show at all: off in device and widget tests
  /// that start the whole app for something else (TD-110).
  FirstRunEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstRunEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstRunEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return firstRunEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$firstRunEnabledHash() => r'03287b3301474bbdc0770d9d59a972416320da85';

/// The app's [FirstRunGate].

@ProviderFor(firstRunGate)
final firstRunGateProvider = FirstRunGateProvider._();

/// The app's [FirstRunGate].

final class FirstRunGateProvider
    extends $FunctionalProvider<FirstRunGate, FirstRunGate, FirstRunGate>
    with $Provider<FirstRunGate> {
  /// The app's [FirstRunGate].
  FirstRunGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstRunGateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstRunGateHash();

  @$internal
  @override
  $ProviderElement<FirstRunGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirstRunGate create(Ref ref) {
    return firstRunGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirstRunGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirstRunGate>(value),
    );
  }
}

String _$firstRunGateHash() => r'1ac2c7dc4f06acc48b92ba9bdbe2b4c8d4fa2630';
