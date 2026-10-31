// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every meal of [mode] with the version a sheet renders, in order, live
/// (A10 D12; the Ramadan set is edited separately, A41a D5). Includes
/// removed (inactive) meals, so a sheet open on one can say so; lists show
/// [activeSlotRecords].

@ProviderFor(slotRecords)
final slotRecordsProvider = SlotRecordsFamily._();

/// Every meal of [mode] with the version a sheet renders, in order, live
/// (A10 D12; the Ramadan set is edited separately, A41a D5). Includes
/// removed (inactive) meals, so a sheet open on one can say so; lists show
/// [activeSlotRecords].

final class SlotRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SlotRecord>>,
          List<SlotRecord>,
          Stream<List<SlotRecord>>
        >
    with $FutureModifier<List<SlotRecord>>, $StreamProvider<List<SlotRecord>> {
  /// Every meal of [mode] with the version a sheet renders, in order, live
  /// (A10 D12; the Ramadan set is edited separately, A41a D5). Includes
  /// removed (inactive) meals, so a sheet open on one can say so; lists show
  /// [activeSlotRecords].
  SlotRecordsProvider._({
    required SlotRecordsFamily super.from,
    required SlotMode super.argument,
  }) : super(
         retry: null,
         name: r'slotRecordsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$slotRecordsHash();

  @override
  String toString() {
    return r'slotRecordsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SlotRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SlotRecord>> create(Ref ref) {
    final argument = this.argument as SlotMode;
    return slotRecords(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SlotRecordsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$slotRecordsHash() => r'89ad07d5e7c2475ebfff5939deda180e1e3b1534';

/// Every meal of [mode] with the version a sheet renders, in order, live
/// (A10 D12; the Ramadan set is edited separately, A41a D5). Includes
/// removed (inactive) meals, so a sheet open on one can say so; lists show
/// [activeSlotRecords].

final class SlotRecordsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SlotRecord>>, SlotMode> {
  SlotRecordsFamily._()
    : super(
        retry: null,
        name: r'slotRecordsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every meal of [mode] with the version a sheet renders, in order, live
  /// (A10 D12; the Ramadan set is edited separately, A41a D5). Includes
  /// removed (inactive) meals, so a sheet open on one can say so; lists show
  /// [activeSlotRecords].

  SlotRecordsProvider call(SlotMode mode) =>
      SlotRecordsProvider._(argument: mode, from: this);

  @override
  String toString() => r'slotRecordsProvider';
}

/// The meals of [mode] in use, in order, with their versions.

@ProviderFor(activeSlotRecords)
final activeSlotRecordsProvider = ActiveSlotRecordsFamily._();

/// The meals of [mode] in use, in order, with their versions.

final class ActiveSlotRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SlotRecord>>,
          AsyncValue<List<SlotRecord>>,
          AsyncValue<List<SlotRecord>>
        >
    with $Provider<AsyncValue<List<SlotRecord>>> {
  /// The meals of [mode] in use, in order, with their versions.
  ActiveSlotRecordsProvider._({
    required ActiveSlotRecordsFamily super.from,
    required SlotMode super.argument,
  }) : super(
         retry: null,
         name: r'activeSlotRecordsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeSlotRecordsHash();

  @override
  String toString() {
    return r'activeSlotRecordsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<SlotRecord>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<SlotRecord>> create(Ref ref) {
    final argument = this.argument as SlotMode;
    return activeSlotRecords(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<SlotRecord>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<SlotRecord>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveSlotRecordsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeSlotRecordsHash() => r'8727bfcab4dd3912f91ba0c1b14e274f42eff687';

/// The meals of [mode] in use, in order, with their versions.

final class ActiveSlotRecordsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<SlotRecord>>, SlotMode> {
  ActiveSlotRecordsFamily._()
    : super(
        retry: null,
        name: r'activeSlotRecordsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The meals of [mode] in use, in order, with their versions.

  ActiveSlotRecordsProvider call(SlotMode mode) =>
      ActiveSlotRecordsProvider._(argument: mode, from: this);

  @override
  String toString() => r'activeSlotRecordsProvider';
}

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

String _$liveSlotsHash() => r'd0f52ef718776bde877e86b1810e6b07a937c648';

/// The Meal times list's local order while a drag is being written (D12),
/// per mode.

@ProviderFor(MealTimesEditor)
final mealTimesEditorProvider = MealTimesEditorFamily._();

/// The Meal times list's local order while a drag is being written (D12),
/// per mode.
final class MealTimesEditorProvider
    extends $NotifierProvider<MealTimesEditor, SlotEditorState> {
  /// The Meal times list's local order while a drag is being written (D12),
  /// per mode.
  MealTimesEditorProvider._({
    required MealTimesEditorFamily super.from,
    required SlotMode super.argument,
  }) : super(
         retry: null,
         name: r'mealTimesEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mealTimesEditorHash();

  @override
  String toString() {
    return r'mealTimesEditorProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is MealTimesEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mealTimesEditorHash() => r'7d935e6bd1d6b8605edff5035b1d96ff2f7c8227';

/// The Meal times list's local order while a drag is being written (D12),
/// per mode.

final class MealTimesEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          MealTimesEditor,
          SlotEditorState,
          SlotEditorState,
          SlotEditorState,
          SlotMode
        > {
  MealTimesEditorFamily._()
    : super(
        retry: null,
        name: r'mealTimesEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Meal times list's local order while a drag is being written (D12),
  /// per mode.

  MealTimesEditorProvider call(SlotMode mode) =>
      MealTimesEditorProvider._(argument: mode, from: this);

  @override
  String toString() => r'mealTimesEditorProvider';
}

/// The Meal times list's local order while a drag is being written (D12),
/// per mode.

abstract class _$MealTimesEditor extends $Notifier<SlotEditorState> {
  late final _$args = ref.$arg as SlotMode;
  SlotMode get mode => _$args;

  SlotEditorState build(SlotMode mode);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
