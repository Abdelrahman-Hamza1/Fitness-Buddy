// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_meals.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live saved snapshots, including empty meals for the detail empty state.

@ProviderFor(savedMeals)
final savedMealsProvider = SavedMealsProvider._();

/// Live saved snapshots, including empty meals for the detail empty state.

final class SavedMealsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedMeal>>,
          List<SavedMeal>,
          Stream<List<SavedMeal>>
        >
    with $FutureModifier<List<SavedMeal>>, $StreamProvider<List<SavedMeal>> {
  /// Live saved snapshots, including empty meals for the detail empty state.
  SavedMealsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedMealsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedMealsHash();

  @$internal
  @override
  $StreamProviderElement<List<SavedMeal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SavedMeal>> create(Ref ref) {
    return savedMeals(ref);
  }
}

String _$savedMealsHash() => r'a6409b4709c73531ee7a8e567bfacdc67187592d';

/// Authoritative source at the observed version; null after deletion.

@ProviderFor(savedMeal)
final savedMealProvider = SavedMealFamily._();

/// Authoritative source at the observed version; null after deletion.

final class SavedMealProvider
    extends
        $FunctionalProvider<
          AsyncValue<SavedMeal?>,
          SavedMeal?,
          Stream<SavedMeal?>
        >
    with $FutureModifier<SavedMeal?>, $StreamProvider<SavedMeal?> {
  /// Authoritative source at the observed version; null after deletion.
  SavedMealProvider._({
    required SavedMealFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'savedMealProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedMealHash();

  @override
  String toString() {
    return r'savedMealProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SavedMeal?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SavedMeal?> create(Ref ref) {
    final argument = this.argument as String;
    return savedMeal(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedMealProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedMealHash() => r'43ba8f1bf09a5b5311242a99445f0c0c85e5d4cd';

/// Authoritative source at the observed version; null after deletion.

final class SavedMealFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SavedMeal?>, String> {
  SavedMealFamily._()
    : super(
        retry: null,
        name: r'savedMealProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Authoritative source at the observed version; null after deletion.

  SavedMealProvider call(String id) =>
      SavedMealProvider._(argument: id, from: this);

  @override
  String toString() => r'savedMealProvider';
}

/// The meals a saved meal can be logged into (active, normal mode, in
/// order), for the detail screen's Meal chip.

@ProviderFor(savedMealSlots)
final savedMealSlotsProvider = SavedMealSlotsProvider._();

/// The meals a saved meal can be logged into (active, normal mode, in
/// order), for the detail screen's Meal chip.

final class SavedMealSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MealSlot>>,
          List<MealSlot>,
          Stream<List<MealSlot>>
        >
    with $FutureModifier<List<MealSlot>>, $StreamProvider<List<MealSlot>> {
  /// The meals a saved meal can be logged into (active, normal mode, in
  /// order), for the detail screen's Meal chip.
  SavedMealSlotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedMealSlotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedMealSlotsHash();

  @$internal
  @override
  $StreamProviderElement<List<MealSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MealSlot>> create(Ref ref) {
    return savedMealSlots(ref);
  }
}

String _$savedMealSlotsHash() => r'496cd918eec317c0a20064c1c929c3cd521f2d23';
