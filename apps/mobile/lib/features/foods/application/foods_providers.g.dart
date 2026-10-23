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

String _$foodSearchServiceHash() => r'5e58926fbe13bba7570be33a04e3dde5e26e293b';

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

String _$foodChoiceHash() => r'8eb8b86bb05b62e8f8325924f7f8240169da5984';

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

/// Active normal meal slots for the amount sheet.

@ProviderFor(foodSlots)
final foodSlotsProvider = FoodSlotsProvider._();

/// Active normal meal slots for the amount sheet.

final class FoodSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MealSlot>>,
          List<MealSlot>,
          Stream<List<MealSlot>>
        >
    with $FutureModifier<List<MealSlot>>, $StreamProvider<List<MealSlot>> {
  /// Active normal meal slots for the amount sheet.
  FoodSlotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodSlotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodSlotsHash();

  @$internal
  @override
  $StreamProviderElement<List<MealSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MealSlot>> create(Ref ref) {
    return foodSlots(ref);
  }
}

String _$foodSlotsHash() => r'643277c2f250336ab8782998c5fb7a4fbdb84335';

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
