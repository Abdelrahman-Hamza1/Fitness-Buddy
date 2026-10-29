// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'targets_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-owned: a pending command survives route changes.

@ProviderFor(targetsActions)
final targetsActionsProvider = TargetsActionsProvider._();

/// Session-owned: a pending command survives route changes.

final class TargetsActionsProvider
    extends $FunctionalProvider<TargetsActions, TargetsActions, TargetsActions>
    with $Provider<TargetsActions> {
  /// Session-owned: a pending command survives route changes.
  TargetsActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetsActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetsActionsHash();

  @$internal
  @override
  $ProviderElement<TargetsActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TargetsActions create(Ref ref) {
    return targetsActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TargetsActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TargetsActions>(value),
    );
  }
}

String _$targetsActionsHash() => r'214c1c76aa215bab5d7d1f6d56d594e73120481a';
