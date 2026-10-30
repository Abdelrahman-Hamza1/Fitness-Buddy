// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adaptive_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-owned: the check-in runs outside any screen.

@ProviderFor(adaptiveActions)
final adaptiveActionsProvider = AdaptiveActionsProvider._();

/// Session-owned: the check-in runs outside any screen.

final class AdaptiveActionsProvider
    extends
        $FunctionalProvider<AdaptiveActions, AdaptiveActions, AdaptiveActions>
    with $Provider<AdaptiveActions> {
  /// Session-owned: the check-in runs outside any screen.
  AdaptiveActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adaptiveActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adaptiveActionsHash();

  @$internal
  @override
  $ProviderElement<AdaptiveActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdaptiveActions create(Ref ref) {
    return adaptiveActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdaptiveActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdaptiveActions>(value),
    );
  }
}

String _$adaptiveActionsHash() => r'a9dd5e2ebcdf4c5983261773235552e8100bd894';

/// Runs this week's check-in while Progress shows (A38 D4), again when the
/// day changes (a new week may have started). Local only; the result is
/// informational.

@ProviderFor(weeklyCheckIn)
final weeklyCheckInProvider = WeeklyCheckInProvider._();

/// Runs this week's check-in while Progress shows (A38 D4), again when the
/// day changes (a new week may have started). Local only; the result is
/// informational.

final class WeeklyCheckInProvider
    extends
        $FunctionalProvider<
          AsyncValue<CheckInRun>,
          CheckInRun,
          FutureOr<CheckInRun>
        >
    with $FutureModifier<CheckInRun>, $FutureProvider<CheckInRun> {
  /// Runs this week's check-in while Progress shows (A38 D4), again when the
  /// day changes (a new week may have started). Local only; the result is
  /// informational.
  WeeklyCheckInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyCheckInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyCheckInHash();

  @$internal
  @override
  $FutureProviderElement<CheckInRun> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CheckInRun> create(Ref ref) {
    return weeklyCheckIn(ref);
  }
}

String _$weeklyCheckInHash() => r'34986ff6b71149a36c6ce6c24014f81fb42e248c';
