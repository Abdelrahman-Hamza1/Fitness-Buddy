// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_route.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one [StartRouteHolder]; it outlives profile switches.

@ProviderFor(startRouteHolder)
final startRouteHolderProvider = StartRouteHolderProvider._();

/// The one [StartRouteHolder]; it outlives profile switches.

final class StartRouteHolderProvider
    extends
        $FunctionalProvider<
          StartRouteHolder,
          StartRouteHolder,
          StartRouteHolder
        >
    with $Provider<StartRouteHolder> {
  /// The one [StartRouteHolder]; it outlives profile switches.
  StartRouteHolderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startRouteHolderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startRouteHolderHash();

  @$internal
  @override
  $ProviderElement<StartRouteHolder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StartRouteHolder create(Ref ref) {
    return startRouteHolder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartRouteHolder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartRouteHolder>(value),
    );
  }
}

String _$startRouteHolderHash() => r'364414bfee768aa0d780b914ccf903a7a5cfd5eb';
