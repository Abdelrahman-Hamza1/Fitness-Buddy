// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The workout actions.

@ProviderFor(workoutActions)
final workoutActionsProvider = WorkoutActionsProvider._();

/// The workout actions.

final class WorkoutActionsProvider
    extends $FunctionalProvider<WorkoutActions, WorkoutActions, WorkoutActions>
    with $Provider<WorkoutActions> {
  /// The workout actions.
  WorkoutActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutActionsHash();

  @$internal
  @override
  $ProviderElement<WorkoutActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkoutActions create(Ref ref) {
    return workoutActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutActions>(value),
    );
  }
}

String _$workoutActionsHash() => r'a4b8bd73adfeecfc2b8569fe55647a1de3481614';
