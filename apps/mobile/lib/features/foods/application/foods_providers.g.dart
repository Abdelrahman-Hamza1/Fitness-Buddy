// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foods_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Offline read port over the attached pack.

@ProviderFor(foodCatalogRepository)
final foodCatalogRepositoryProvider = FoodCatalogRepositoryProvider._();

/// Offline read port over the attached pack.

final class FoodCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          FoodCatalogRepository,
          FoodCatalogRepository,
          FoodCatalogRepository
        >
    with $Provider<FoodCatalogRepository> {
  /// Offline read port over the attached pack.
  FoodCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodCatalogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodCatalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<FoodCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FoodCatalogRepository create(Ref ref) {
    return foodCatalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodCatalogRepository>(value),
    );
  }
}

String _$foodCatalogRepositoryHash() =>
    r'9fdb3288b9749eb1b3806ad1080eeee8451885b9';

/// Search session with reactive history and background fuzzy builds.

@ProviderFor(foodSearchService)
final foodSearchServiceProvider = FoodSearchServiceProvider._();

/// Search session with reactive history and background fuzzy builds.

final class FoodSearchServiceProvider
    extends
        $FunctionalProvider<
          FoodSearchService,
          FoodSearchService,
          FoodSearchService
        >
    with $Provider<FoodSearchService> {
  /// Search session with reactive history and background fuzzy builds.
  FoodSearchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodSearchServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodSearchServiceHash();

  @$internal
  @override
  $ProviderElement<FoodSearchService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FoodSearchService create(Ref ref) {
    return foodSearchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodSearchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodSearchService>(value),
    );
  }
}

String _$foodSearchServiceHash() => r'fc73d7dcd8c6342829753e309dff5281b35630fc';

/// Loads the selected food using fresh history and current metadata.

@ProviderFor(foodChoice)
final foodChoiceProvider = FoodChoiceFamily._();

/// Loads the selected food using fresh history and current metadata.

final class FoodChoiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<FoodChoice?>,
          FoodChoice?,
          FutureOr<FoodChoice?>
        >
    with $FutureModifier<FoodChoice?>, $FutureProvider<FoodChoice?> {
  /// Loads the selected food using fresh history and current metadata.
  FoodChoiceProvider._({
    required FoodChoiceFamily super.from,
    required FoodChoiceRef super.argument,
  }) : super(
         retry: null,
         name: r'foodChoiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodChoiceHash();

  @override
  String toString() {
    return r'foodChoiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FoodChoice?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FoodChoice?> create(Ref ref) {
    final argument = this.argument as FoodChoiceRef;
    return foodChoice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FoodChoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodChoiceHash() => r'ec92183e1a0a890c0fb4726605e8f6087e18bf62';

/// Loads the selected food using fresh history and current metadata.

final class FoodChoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FoodChoice?>, FoodChoiceRef> {
  FoodChoiceFamily._()
    : super(
        retry: null,
        name: r'foodChoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the selected food using fresh history and current metadata.

  FoodChoiceProvider call(FoodChoiceRef choice) =>
      FoodChoiceProvider._(argument: choice, from: this);

  @override
  String toString() => r'foodChoiceProvider';
}

/// Structured command used to submit through the applier.

@ProviderFor(logFood)
final logFoodProvider = LogFoodProvider._();

/// Structured command used to submit through the applier.

final class LogFoodProvider
    extends $FunctionalProvider<LogFood, LogFood, LogFood>
    with $Provider<LogFood> {
  /// Structured command used to submit through the applier.
  LogFoodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logFoodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logFoodHash();

  @$internal
  @override
  $ProviderElement<LogFood> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogFood create(Ref ref) {
    return logFood(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogFood value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogFood>(value),
    );
  }
}

String _$logFoodHash() => r'7a36100d2eb9fc79a7fa52a27113a1a7b94a5e59';

/// The meal slots the amount sheet offers on [date] (DY-012, A41a D6): the
/// day's mode (Ramadan on a fasting day) with its windows, removed ones
/// included (a sheet open on one drops it).
/// Every slot in the list is of the day's mode ([slotModeOf]).

@ProviderFor(foodSlots)
final foodSlotsProvider = FoodSlotsFamily._();

/// The meal slots the amount sheet offers on [date] (DY-012, A41a D6): the
/// day's mode (Ramadan on a fasting day) with its windows, removed ones
/// included (a sheet open on one drops it).
/// Every slot in the list is of the day's mode ([slotModeOf]).

final class FoodSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MealSlot>>,
          List<MealSlot>,
          Stream<List<MealSlot>>
        >
    with $FutureModifier<List<MealSlot>>, $StreamProvider<List<MealSlot>> {
  /// The meal slots the amount sheet offers on [date] (DY-012, A41a D6): the
  /// day's mode (Ramadan on a fasting day) with its windows, removed ones
  /// included (a sheet open on one drops it).
  /// Every slot in the list is of the day's mode ([slotModeOf]).
  FoodSlotsProvider._({
    required FoodSlotsFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'foodSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodSlotsHash();

  @override
  String toString() {
    return r'foodSlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MealSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MealSlot>> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return foodSlots(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FoodSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodSlotsHash() => r'11344cccfd005c33a97c7560bcfde64b2b3fb276';

/// The meal slots the amount sheet offers on [date] (DY-012, A41a D6): the
/// day's mode (Ramadan on a fasting day) with its windows, removed ones
/// included (a sheet open on one drops it).
/// Every slot in the list is of the day's mode ([slotModeOf]).

final class FoodSlotsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MealSlot>>, LocalDate> {
  FoodSlotsFamily._()
    : super(
        retry: null,
        name: r'foodSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The meal slots the amount sheet offers on [date] (DY-012, A41a D6): the
  /// day's mode (Ramadan on a fasting day) with its windows, removed ones
  /// included (a sheet open on one drops it).
  /// Every slot in the list is of the day's mode ([slotModeOf]).

  FoodSlotsProvider call(LocalDate date) =>
      FoodSlotsProvider._(argument: date, from: this);

  @override
  String toString() => r'foodSlotsProvider';
}

/// Replace-mode command with the same applier and undo history.

@ProviderFor(replaceEntryFood)
final replaceEntryFoodProvider = ReplaceEntryFoodProvider._();

/// Replace-mode command with the same applier and undo history.

final class ReplaceEntryFoodProvider
    extends
        $FunctionalProvider<
          ReplaceEntryFood,
          ReplaceEntryFood,
          ReplaceEntryFood
        >
    with $Provider<ReplaceEntryFood> {
  /// Replace-mode command with the same applier and undo history.
  ReplaceEntryFoodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'replaceEntryFoodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$replaceEntryFoodHash();

  @$internal
  @override
  $ProviderElement<ReplaceEntryFood> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReplaceEntryFood create(Ref ref) {
    return replaceEntryFood(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReplaceEntryFood value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReplaceEntryFood>(value),
    );
  }
}

String _$replaceEntryFoodHash() => r'68bffbc4d040303e9e2ea48812dca97c3209c7bd';

/// Live search/form definitions.

@ProviderFor(personalFoods)
final personalFoodsProvider = PersonalFoodsProvider._();

/// Live search/form definitions.

final class PersonalFoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PersonalFood>>,
          List<PersonalFood>,
          Stream<List<PersonalFood>>
        >
    with
        $FutureModifier<List<PersonalFood>>,
        $StreamProvider<List<PersonalFood>> {
  /// Live search/form definitions.
  PersonalFoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalFoodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalFoodsHash();

  @$internal
  @override
  $StreamProviderElement<List<PersonalFood>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PersonalFood>> create(Ref ref) {
    return personalFoods(ref);
  }
}

String _$personalFoodsHash() => r'fcd79add619889c61fa10008ab4b7a4a11c92cb6';

/// How many live personal foods can't be read (#100).

@ProviderFor(unreadablePersonalFoodCount)
final unreadablePersonalFoodCountProvider =
    UnreadablePersonalFoodCountProvider._();

/// How many live personal foods can't be read (#100).

final class UnreadablePersonalFoodCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// How many live personal foods can't be read (#100).
  UnreadablePersonalFoodCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadablePersonalFoodCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadablePersonalFoodCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return unreadablePersonalFoodCount(ref);
  }
}

String _$unreadablePersonalFoodCountHash() =>
    r'029c82b062e22852e146512599547aa6bc18f04a';

/// Row observed by a disposable edit form.

@ProviderFor(personalFood)
final personalFoodProvider = PersonalFoodFamily._();

/// Row observed by a disposable edit form.

final class PersonalFoodProvider
    extends
        $FunctionalProvider<
          AsyncValue<PersonalFood?>,
          PersonalFood?,
          Stream<PersonalFood?>
        >
    with $FutureModifier<PersonalFood?>, $StreamProvider<PersonalFood?> {
  /// Row observed by a disposable edit form.
  PersonalFoodProvider._({
    required PersonalFoodFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'personalFoodProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personalFoodHash();

  @override
  String toString() {
    return r'personalFoodProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<PersonalFood?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PersonalFood?> create(Ref ref) {
    final argument = this.argument as String;
    return personalFood(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PersonalFoodProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personalFoodHash() => r'f1eb644ab89eca51de079e66b26ea173cecdd2a4';

/// Row observed by a disposable edit form.

final class PersonalFoodFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PersonalFood?>, String> {
  PersonalFoodFamily._()
    : super(
        retry: null,
        name: r'personalFoodProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Row observed by a disposable edit form.

  PersonalFoodProvider call(String id) =>
      PersonalFoodProvider._(argument: id, from: this);

  @override
  String toString() => r'personalFoodProvider';
}

/// Commands retain pending keys across route changes.

@ProviderFor(personalFoodActions)
final personalFoodActionsProvider = PersonalFoodActionsProvider._();

/// Commands retain pending keys across route changes.

final class PersonalFoodActionsProvider
    extends
        $FunctionalProvider<
          PersonalFoodActions,
          PersonalFoodActions,
          PersonalFoodActions
        >
    with $Provider<PersonalFoodActions> {
  /// Commands retain pending keys across route changes.
  PersonalFoodActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalFoodActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalFoodActionsHash();

  @$internal
  @override
  $ProviderElement<PersonalFoodActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PersonalFoodActions create(Ref ref) {
    return personalFoodActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonalFoodActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonalFoodActions>(value),
    );
  }
}

String _$personalFoodActionsHash() =>
    r'1dfc2b4cc4d9af6fa991832d1944cfaf065f5ced';
