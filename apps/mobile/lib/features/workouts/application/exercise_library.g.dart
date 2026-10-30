// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The pack's exercises with their names, re-read on every pack swap.

@ProviderFor(builtInExercises)
final builtInExercisesProvider = BuiltInExercisesProvider._();

/// The pack's exercises with their names, re-read on every pack swap.

final class BuiltInExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryExercise>>,
          List<LibraryExercise>,
          Stream<List<LibraryExercise>>
        >
    with
        $FutureModifier<List<LibraryExercise>>,
        $StreamProvider<List<LibraryExercise>> {
  /// The pack's exercises with their names, re-read on every pack swap.
  BuiltInExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'builtInExercisesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$builtInExercisesHash();

  @$internal
  @override
  $StreamProviderElement<List<LibraryExercise>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LibraryExercise>> create(Ref ref) {
    return builtInExercises(ref);
  }
}

String _$builtInExercisesHash() => r'd40fad3b74c6efed8b0438986e7d0303d4556dec';

/// The live custom exercises.

@ProviderFor(customExercises)
final customExercisesProvider = CustomExercisesProvider._();

/// The live custom exercises.

final class CustomExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Stored<CustomExerciseDraft>>>,
          List<Stored<CustomExerciseDraft>>,
          Stream<List<Stored<CustomExerciseDraft>>>
        >
    with
        $FutureModifier<List<Stored<CustomExerciseDraft>>>,
        $StreamProvider<List<Stored<CustomExerciseDraft>>> {
  /// The live custom exercises.
  CustomExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customExercisesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customExercisesHash();

  @$internal
  @override
  $StreamProviderElement<List<Stored<CustomExerciseDraft>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Stored<CustomExerciseDraft>>> create(Ref ref) {
    return customExercises(ref);
  }
}

String _$customExercisesHash() => r'bdaa83ad6bc268e31c4c0a250beb42d65ba2a236';

/// Built-ins and live custom exercises (A37 §3.5).

@ProviderFor(exerciseLibrary)
final exerciseLibraryProvider = ExerciseLibraryProvider._();

/// Built-ins and live custom exercises (A37 §3.5).

final class ExerciseLibraryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExerciseLibrary>,
          ExerciseLibrary,
          FutureOr<ExerciseLibrary>
        >
    with $FutureModifier<ExerciseLibrary>, $FutureProvider<ExerciseLibrary> {
  /// Built-ins and live custom exercises (A37 §3.5).
  ExerciseLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseLibraryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseLibraryHash();

  @$internal
  @override
  $FutureProviderElement<ExerciseLibrary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExerciseLibrary> create(Ref ref) {
    return exerciseLibrary(ref);
  }
}

String _$exerciseLibraryHash() => r'5061ddbd673baaf94db33889a1e8770a314623a7';
