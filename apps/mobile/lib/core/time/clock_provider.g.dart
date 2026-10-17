// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's clock (S08 D7). `fb_domain`'s `SystemClock` is wired in by the
/// composition root (`lib/app/app_scope.dart`), the only place that imports
/// `package:fb_domain/system.dart`; tests pass a `ManualClock`.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// The app's clock (S08 D7). `fb_domain`'s `SystemClock` is wired in by the
/// composition root (`lib/app/app_scope.dart`), the only place that imports
/// `package:fb_domain/system.dart`; tests pass a `ManualClock`.

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  /// The app's clock (S08 D7). `fb_domain`'s `SystemClock` is wired in by the
  /// composition root (`lib/app/app_scope.dart`), the only place that imports
  /// `package:fb_domain/system.dart`; tests pass a `ManualClock`.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'83c1f5d3d325e6105364999c8a146b19932a83b4';
