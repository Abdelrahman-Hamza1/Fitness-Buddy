// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_exercise_form.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The custom exercise form's view model: edits, Save and Delete as direct
/// actions with undo (through [WorkoutActions]).

@ProviderFor(CustomExerciseForm)
final customExerciseFormProvider = CustomExerciseFormFamily._();

/// The custom exercise form's view model: edits, Save and Delete as direct
/// actions with undo (through [WorkoutActions]).
final class CustomExerciseFormProvider
    extends
        $AsyncNotifierProvider<CustomExerciseForm, CustomExerciseFormState> {
  /// The custom exercise form's view model: edits, Save and Delete as direct
  /// actions with undo (through [WorkoutActions]).
  CustomExerciseFormProvider._({
    required CustomExerciseFormFamily super.from,
    required CustomExerciseKey super.argument,
  }) : super(
         retry: null,
         name: r'customExerciseFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customExerciseFormHash();

  @override
  String toString() {
    return r'customExerciseFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CustomExerciseForm create() => CustomExerciseForm();

  @override
  bool operator ==(Object other) {
    return other is CustomExerciseFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customExerciseFormHash() =>
    r'd2e642fefb58f51212e29fe2b8947b2647e3b767';

/// The custom exercise form's view model: edits, Save and Delete as direct
/// actions with undo (through [WorkoutActions]).

final class CustomExerciseFormFamily extends $Family
    with
        $ClassFamilyOverride<
          CustomExerciseForm,
          AsyncValue<CustomExerciseFormState>,
          CustomExerciseFormState,
          FutureOr<CustomExerciseFormState>,
          CustomExerciseKey
        > {
  CustomExerciseFormFamily._()
    : super(
        retry: null,
        name: r'customExerciseFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The custom exercise form's view model: edits, Save and Delete as direct
  /// actions with undo (through [WorkoutActions]).

  CustomExerciseFormProvider call(CustomExerciseKey key) =>
      CustomExerciseFormProvider._(argument: key, from: this);

  @override
  String toString() => r'customExerciseFormProvider';
}

/// The custom exercise form's view model: edits, Save and Delete as direct
/// actions with undo (through [WorkoutActions]).

abstract class _$CustomExerciseForm
    extends $AsyncNotifier<CustomExerciseFormState> {
  late final _$args = ref.$arg as CustomExerciseKey;
  CustomExerciseKey get key => _$args;

  FutureOr<CustomExerciseFormState> build(CustomExerciseKey key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CustomExerciseFormState>,
              CustomExerciseFormState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CustomExerciseFormState>,
                CustomExerciseFormState
              >,
              AsyncValue<CustomExerciseFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The exercises sessions or templates use (D15).

@ProviderFor(_exerciseReferences)
final _exerciseReferencesProvider = _ExerciseReferencesProvider._();

/// The exercises sessions or templates use (D15).

final class _ExerciseReferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// The exercises sessions or templates use (D15).
  _ExerciseReferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_exerciseReferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_exerciseReferencesHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return _exerciseReferences(ref);
  }
}

String _$_exerciseReferencesHash() =>
    r'b6980e2cfc7bcc2d56326a57fb00f34adf27167f';
