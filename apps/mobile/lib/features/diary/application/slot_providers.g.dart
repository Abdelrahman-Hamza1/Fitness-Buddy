// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every normal meal with the version a sheet renders, in order, live (A10
/// D12). Includes removed (inactive) meals, so a sheet open on one can say
/// so; lists show [activeSlotRecords].

@ProviderFor(slotRecords)
final slotRecordsProvider = SlotRecordsProvider._();

/// Every normal meal with the version a sheet renders, in order, live (A10
/// D12). Includes removed (inactive) meals, so a sheet open on one can say
/// so; lists show [activeSlotRecords].

final class SlotRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SlotRecord>>,
          List<SlotRecord>,
          Stream<List<SlotRecord>>
        >
    with $FutureModifier<List<SlotRecord>>, $StreamProvider<List<SlotRecord>> {
  /// Every normal meal with the version a sheet renders, in order, live (A10
  /// D12). Includes removed (inactive) meals, so a sheet open on one can say
  /// so; lists show [activeSlotRecords].
  SlotRecordsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slotRecordsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slotRecordsHash();

  @$internal
  @override
  $StreamProviderElement<List<SlotRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SlotRecord>> create(Ref ref) {
    return slotRecords(ref);
  }
}

String _$slotRecordsHash() => r'f2d0451d71323b88dff0ab2fdb4af0b71e243ff1';

/// The meals in use, in order, with their versions.

@ProviderFor(activeSlotRecords)
final activeSlotRecordsProvider = ActiveSlotRecordsProvider._();

/// The meals in use, in order, with their versions.

final class ActiveSlotRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SlotRecord>>,
          AsyncValue<List<SlotRecord>>,
          AsyncValue<List<SlotRecord>>
        >
    with $Provider<AsyncValue<List<SlotRecord>>> {
  /// The meals in use, in order, with their versions.
  ActiveSlotRecordsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSlotRecordsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSlotRecordsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<SlotRecord>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<SlotRecord>> create(Ref ref) {
    return activeSlotRecords(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<SlotRecord>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<SlotRecord>>>(value),
    );
  }
}

String _$activeSlotRecordsHash() => r'9832ac3fe2ae53ea1bb191652f07185cf270095c';

/// How many live entries each meal holds (by meal ID; absent means none).

@ProviderFor(slotEntryCounts)
final slotEntryCountsProvider = SlotEntryCountsProvider._();

/// How many live entries each meal holds (by meal ID; absent means none).

final class SlotEntryCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          Stream<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  /// How many live entries each meal holds (by meal ID; absent means none).
  SlotEntryCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slotEntryCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slotEntryCountsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    return slotEntryCounts(ref);
  }
}

String _$slotEntryCountsHash() => r'e5ede67b3aca6b1de0bec06e90f96bbc801fa65d';

/// What the remove sheet shows for meal [slotId]: every live entry and dish
/// group in it with its version, and the days they are on (PA1).

@ProviderFor(slotContents)
final slotContentsProvider = SlotContentsFamily._();

/// What the remove sheet shows for meal [slotId]: every live entry and dish
/// group in it with its version, and the days they are on (PA1).

final class SlotContentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SlotContents>,
          SlotContents,
          Stream<SlotContents>
        >
    with $FutureModifier<SlotContents>, $StreamProvider<SlotContents> {
  /// What the remove sheet shows for meal [slotId]: every live entry and dish
  /// group in it with its version, and the days they are on (PA1).
  SlotContentsProvider._({
    required SlotContentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'slotContentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$slotContentsHash();

  @override
  String toString() {
    return r'slotContentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SlotContents> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SlotContents> create(Ref ref) {
    final argument = this.argument as String;
    return slotContents(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SlotContentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$slotContentsHash() => r'01c36c59c509f10ac539d3caa95e2a243f4b9006';

/// What the remove sheet shows for meal [slotId]: every live entry and dish
/// group in it with its version, and the days they are on (PA1).

final class SlotContentsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SlotContents>, String> {
  SlotContentsFamily._()
    : super(
        retry: null,
        name: r'slotContentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What the remove sheet shows for meal [slotId]: every live entry and dish
  /// group in it with its version, and the days they are on (PA1).

  SlotContentsProvider call(String slotId) =>
      SlotContentsProvider._(argument: slotId, from: this);

  @override
  String toString() => r'slotContentsProvider';
}

/// The live meals (any mode, removed ones included) for sheets that offer a
/// choice of meal and must drop a removed one (A10 D12a).

@ProviderFor(liveSlots)
final liveSlotsProvider = LiveSlotsProvider._();

/// The live meals (any mode, removed ones included) for sheets that offer a
/// choice of meal and must drop a removed one (A10 D12a).

final class LiveSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MealSlot>>,
          List<MealSlot>,
          Stream<List<MealSlot>>
        >
    with $FutureModifier<List<MealSlot>>, $StreamProvider<List<MealSlot>> {
  /// The live meals (any mode, removed ones included) for sheets that offer a
  /// choice of meal and must drop a removed one (A10 D12a).
  LiveSlotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveSlotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveSlotsHash();

  @$internal
  @override
  $StreamProviderElement<List<MealSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MealSlot>> create(Ref ref) {
    return liveSlots(ref);
  }
}

String _$liveSlotsHash() => r'f120c5ad3fdf967e7d7294cacb313422e3307eba';

/// The Meal times list's local order while a drag is being written (D12).

@ProviderFor(MealTimesEditor)
final mealTimesEditorProvider = MealTimesEditorProvider._();

/// The Meal times list's local order while a drag is being written (D12).
final class MealTimesEditorProvider
    extends $NotifierProvider<MealTimesEditor, SlotEditorState> {
  /// The Meal times list's local order while a drag is being written (D12).
  MealTimesEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealTimesEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealTimesEditorHash();

  @$internal
  @override
  MealTimesEditor create() => MealTimesEditor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlotEditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlotEditorState>(value),
    );
  }
}

String _$mealTimesEditorHash() => r'e18810608ebac76c353a933596f69b74e927f71e';

/// The Meal times list's local order while a drag is being written (D12).

abstract class _$MealTimesEditor extends $Notifier<SlotEditorState> {
  SlotEditorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SlotEditorState, SlotEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SlotEditorState, SlotEditorState>,
              SlotEditorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
