// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The timer autosave debounces with.

@ProviderFor(workoutAutosaveTimer)
final workoutAutosaveTimerProvider = WorkoutAutosaveTimerProvider._();

/// The timer autosave debounces with.

final class WorkoutAutosaveTimerProvider
    extends $FunctionalProvider<AutosaveTimer, AutosaveTimer, AutosaveTimer>
    with $Provider<AutosaveTimer> {
  /// The timer autosave debounces with.
  WorkoutAutosaveTimerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutAutosaveTimerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutAutosaveTimerHash();

  @$internal
  @override
  $ProviderElement<AutosaveTimer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AutosaveTimer create(Ref ref) {
    return workoutAutosaveTimer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutosaveTimer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutosaveTimer>(value),
    );
  }
}

String _$workoutAutosaveTimerHash() =>
    r'0059364c1035a6040970b2e244e6c891089224f1';

/// The single writer's apply for the log form; injectable so tests can make
/// a write fail or wait.

@ProviderFor(workoutApply)
final workoutApplyProvider = WorkoutApplyProvider._();

/// The single writer's apply for the log form; injectable so tests can make
/// a write fail or wait.

final class WorkoutApplyProvider
    extends
        $FunctionalProvider<
          Future<ApplyResult> Function(ChangeSet),
          Future<ApplyResult> Function(ChangeSet),
          Future<ApplyResult> Function(ChangeSet)
        >
    with $Provider<Future<ApplyResult> Function(ChangeSet)> {
  /// The single writer's apply for the log form; injectable so tests can make
  /// a write fail or wait.
  WorkoutApplyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutApplyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutApplyHash();

  @$internal
  @override
  $ProviderElement<Future<ApplyResult> Function(ChangeSet)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<ApplyResult> Function(ChangeSet) create(Ref ref) {
    return workoutApply(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<ApplyResult> Function(ChangeSet) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<ApplyResult> Function(ChangeSet)>(value),
    );
  }
}

String _$workoutApplyHash() => r'7ad9059e8bf52fde17f0a4eff9743cff3c8b838d';

/// The single writer's revert for the log form (putting back a session the
/// final delete removed while a set was checked again); injectable so
/// tests can make it fail.

@ProviderFor(workoutRevert)
final workoutRevertProvider = WorkoutRevertProvider._();

/// The single writer's revert for the log form (putting back a session the
/// final delete removed while a set was checked again); injectable so
/// tests can make it fail.

final class WorkoutRevertProvider
    extends
        $FunctionalProvider<
          Future<ApplyResult> Function(InverseChangeSet),
          Future<ApplyResult> Function(InverseChangeSet),
          Future<ApplyResult> Function(InverseChangeSet)
        >
    with $Provider<Future<ApplyResult> Function(InverseChangeSet)> {
  /// The single writer's revert for the log form (putting back a session the
  /// final delete removed while a set was checked again); injectable so
  /// tests can make it fail.
  WorkoutRevertProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutRevertProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutRevertHash();

  @$internal
  @override
  $ProviderElement<Future<ApplyResult> Function(InverseChangeSet)>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Future<ApplyResult> Function(InverseChangeSet) create(Ref ref) {
    return workoutRevert(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Future<ApplyResult> Function(InverseChangeSet) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<ApplyResult> Function(InverseChangeSet)>(
            value,
          ),
    );
  }
}

String _$workoutRevertHash() => r'7c80507d8936a86a655903f58dd849d995153c94';

/// The log form (WO-034, A37 D7-D9, PA1-PA3): its cards and set rows,
/// "saves as you type" through the applier (debounced, one write in flight,
/// coalescing to the newest form), one Undo per visit as a compensating
/// change set, and a conflict state that stops autosave until Reload or
/// Keep mine. Every write is a change set (`ChangeSetApplier`).

@ProviderFor(WorkoutLogController)
final workoutLogControllerProvider = WorkoutLogControllerFamily._();

/// The log form (WO-034, A37 D7-D9, PA1-PA3): its cards and set rows,
/// "saves as you type" through the applier (debounced, one write in flight,
/// coalescing to the newest form), one Undo per visit as a compensating
/// change set, and a conflict state that stops autosave until Reload or
/// Keep mine. Every write is a change set (`ChangeSetApplier`).
final class WorkoutLogControllerProvider
    extends $AsyncNotifierProvider<WorkoutLogController, LogFormState> {
  /// The log form (WO-034, A37 D7-D9, PA1-PA3): its cards and set rows,
  /// "saves as you type" through the applier (debounced, one write in flight,
  /// coalescing to the newest form), one Undo per visit as a compensating
  /// change set, and a conflict state that stops autosave until Reload or
  /// Keep mine. Every write is a change set (`ChangeSetApplier`).
  WorkoutLogControllerProvider._({
    required WorkoutLogControllerFamily super.from,
    required LogLaunch super.argument,
  }) : super(
         retry: null,
         name: r'workoutLogControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutLogControllerHash();

  @override
  String toString() {
    return r'workoutLogControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkoutLogController create() => WorkoutLogController();

  @override
  bool operator ==(Object other) {
    return other is WorkoutLogControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutLogControllerHash() =>
    r'd40ad2da6f82df2a44815bb024d911588de4beb2';

/// The log form (WO-034, A37 D7-D9, PA1-PA3): its cards and set rows,
/// "saves as you type" through the applier (debounced, one write in flight,
/// coalescing to the newest form), one Undo per visit as a compensating
/// change set, and a conflict state that stops autosave until Reload or
/// Keep mine. Every write is a change set (`ChangeSetApplier`).

final class WorkoutLogControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkoutLogController,
          AsyncValue<LogFormState>,
          LogFormState,
          FutureOr<LogFormState>,
          LogLaunch
        > {
  WorkoutLogControllerFamily._()
    : super(
        retry: null,
        name: r'workoutLogControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The log form (WO-034, A37 D7-D9, PA1-PA3): its cards and set rows,
  /// "saves as you type" through the applier (debounced, one write in flight,
  /// coalescing to the newest form), one Undo per visit as a compensating
  /// change set, and a conflict state that stops autosave until Reload or
  /// Keep mine. Every write is a change set (`ChangeSetApplier`).

  WorkoutLogControllerProvider call(LogLaunch launch) =>
      WorkoutLogControllerProvider._(argument: launch, from: this);

  @override
  String toString() => r'workoutLogControllerProvider';
}

/// The log form (WO-034, A37 D7-D9, PA1-PA3): its cards and set rows,
/// "saves as you type" through the applier (debounced, one write in flight,
/// coalescing to the newest form), one Undo per visit as a compensating
/// change set, and a conflict state that stops autosave until Reload or
/// Keep mine. Every write is a change set (`ChangeSetApplier`).

abstract class _$WorkoutLogController extends $AsyncNotifier<LogFormState> {
  late final _$args = ref.$arg as LogLaunch;
  LogLaunch get launch => _$args;

  FutureOr<LogFormState> build(LogLaunch launch);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LogFormState>, LogFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LogFormState>, LogFormState>,
              AsyncValue<LogFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
