// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen: [scope] is the screen's own key, so pickers open
/// in two tabs (or a picker and an "All exercises" list) never share state.

@ProviderFor(ExercisePicker)
final exercisePickerProvider = ExercisePickerFamily._();

/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen: [scope] is the screen's own key, so pickers open
/// in two tabs (or a picker and an "All exercises" list) never share state.
final class ExercisePickerProvider
    extends $NotifierProvider<ExercisePicker, ExercisePickerState> {
  /// The exercise picker (WO-001): search, chip and multi-select in order.
  /// One per picker screen: [scope] is the screen's own key, so pickers open
  /// in two tabs (or a picker and an "All exercises" list) never share state.
  ExercisePickerProvider._({
    required ExercisePickerFamily super.from,
    required Object super.argument,
  }) : super(
         retry: null,
         name: r'exercisePickerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exercisePickerHash();

  @override
  String toString() {
    return r'exercisePickerProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is ExercisePickerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exercisePickerHash() => r'597f9dece6da0b72389d6e829e0d8b5e8d8772be';

/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen: [scope] is the screen's own key, so pickers open
/// in two tabs (or a picker and an "All exercises" list) never share state.

final class ExercisePickerFamily extends $Family
    with
        $ClassFamilyOverride<
          ExercisePicker,
          ExercisePickerState,
          ExercisePickerState,
          ExercisePickerState,
          Object
        > {
  ExercisePickerFamily._()
    : super(
        retry: null,
        name: r'exercisePickerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The exercise picker (WO-001): search, chip and multi-select in order.
  /// One per picker screen: [scope] is the screen's own key, so pickers open
  /// in two tabs (or a picker and an "All exercises" list) never share state.

  ExercisePickerProvider call(Object scope) =>
      ExercisePickerProvider._(argument: scope, from: this);

  @override
  String toString() => r'exercisePickerProvider';
}

/// The exercise picker (WO-001): search, chip and multi-select in order.
/// One per picker screen: [scope] is the screen's own key, so pickers open
/// in two tabs (or a picker and an "All exercises" list) never share state.

abstract class _$ExercisePicker extends $Notifier<ExercisePickerState> {
  late final _$args = ref.$arg as Object;
  Object get scope => _$args;

  ExercisePickerState build(Object scope);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
