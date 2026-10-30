// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'targets_screens.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today in the device zone, read once per screen (the `SetupFlow` rule;
/// the targets feature doesn't import Today's date provider).

@ProviderFor(targetsToday)
final targetsTodayProvider = TargetsTodayProvider._();

/// Today in the device zone, read once per screen (the `SetupFlow` rule;
/// the targets feature doesn't import Today's date provider).

final class TargetsTodayProvider
    extends $FunctionalProvider<LocalDate, LocalDate, LocalDate>
    with $Provider<LocalDate> {
  /// Today in the device zone, read once per screen (the `SetupFlow` rule;
  /// the targets feature doesn't import Today's date provider).
  TargetsTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetsTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetsTodayHash();

  @$internal
  @override
  $ProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalDate create(Ref ref) {
    return targetsToday(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate>(value),
    );
  }
}

String _$targetsTodayHash() => r'ba5597fae6b31850977130c5a64dd54c9258dc24';

/// The live [ProfileGoalView], or null before setup.

@ProviderFor(profileGoalView)
final profileGoalViewProvider = ProfileGoalViewProvider._();

/// The live [ProfileGoalView], or null before setup.

final class ProfileGoalViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProfileGoalView?>,
          ProfileGoalView?,
          FutureOr<ProfileGoalView?>
        >
    with $FutureModifier<ProfileGoalView?>, $FutureProvider<ProfileGoalView?> {
  /// The live [ProfileGoalView], or null before setup.
  ProfileGoalViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileGoalViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileGoalViewHash();

  @$internal
  @override
  $FutureProviderElement<ProfileGoalView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProfileGoalView?> create(Ref ref) {
    return profileGoalView(ref);
  }
}

String _$profileGoalViewHash() => r'3cb28c81dc1427e90cfc2517195a6324f6861031';

/// The live [TargetsView], or null before setup (or when today's targets
/// can't be computed from the stored rows).

@ProviderFor(targetsView)
final targetsViewProvider = TargetsViewProvider._();

/// The live [TargetsView], or null before setup (or when today's targets
/// can't be computed from the stored rows).

final class TargetsViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<TargetsView?>,
          TargetsView?,
          FutureOr<TargetsView?>
        >
    with $FutureModifier<TargetsView?>, $FutureProvider<TargetsView?> {
  /// The live [TargetsView], or null before setup (or when today's targets
  /// can't be computed from the stored rows).
  TargetsViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetsViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetsViewHash();

  @$internal
  @override
  $FutureProviderElement<TargetsView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TargetsView?> create(Ref ref) {
    return targetsView(ref);
  }
}

String _$targetsViewHash() => r'975a4384d8bc8532a407b865227ef52200685dca';
