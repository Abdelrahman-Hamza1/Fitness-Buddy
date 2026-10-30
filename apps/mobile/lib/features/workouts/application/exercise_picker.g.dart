// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen.

@ProviderFor(ExercisePicker)
final exercisePickerProvider = ExercisePickerProvider._();

/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen.
final class ExercisePickerProvider
    extends $NotifierProvider<ExercisePicker, ExercisePickerState> {
  /// The exercise picker (WO-001): search, chip and multi-select in order.
  /// One per picker screen.
  ExercisePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exercisePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exercisePickerHash();

  @$internal
  @override
  ExercisePicker create() => ExercisePicker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExercisePickerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExercisePickerState>(value),
    );
  }
}

String _$exercisePickerHash() => r'b6cde161231fb0864865e12f628fb4659f28e7a8';

/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen.

abstract class _$ExercisePicker extends $Notifier<ExercisePickerState> {
  ExercisePickerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExercisePickerState, ExercisePickerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExercisePickerState, ExercisePickerState>,
              ExercisePickerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
