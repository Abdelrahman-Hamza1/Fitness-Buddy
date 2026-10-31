// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_slots.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [DaySlots] of [date], live: follows the slots, the Ramadan decisions,
/// the day's not-fasting mark, the city and the prayer method.

@ProviderFor(daySlots)
final daySlotsProvider = DaySlotsFamily._();

/// [DaySlots] of [date], live: follows the slots, the Ramadan decisions,
/// the day's not-fasting mark, the city and the prayer method.

final class DaySlotsProvider
    extends
        $FunctionalProvider<AsyncValue<DaySlots>, DaySlots, FutureOr<DaySlots>>
    with $FutureModifier<DaySlots>, $FutureProvider<DaySlots> {
  /// [DaySlots] of [date], live: follows the slots, the Ramadan decisions,
  /// the day's not-fasting mark, the city and the prayer method.
  DaySlotsProvider._({
    required DaySlotsFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'daySlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$daySlotsHash();

  @override
  String toString() {
    return r'daySlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DaySlots> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DaySlots> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return daySlots(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DaySlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$daySlotsHash() => r'f402aead002083a48d0d3a110e9dd22a9604f552';

/// [DaySlots] of [date], live: follows the slots, the Ramadan decisions,
/// the day's not-fasting mark, the city and the prayer method.

final class DaySlotsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DaySlots>, LocalDate> {
  DaySlotsFamily._()
    : super(
        retry: null,
        name: r'daySlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [DaySlots] of [date], live: follows the slots, the Ramadan decisions,
  /// the day's not-fasting mark, the city and the prayer method.

  DaySlotsProvider call(LocalDate date) =>
      DaySlotsProvider._(argument: date, from: this);

  @override
  String toString() => r'daySlotsProvider';
}

@ProviderFor(_allSlots)
final _allSlotsProvider = _AllSlotsProvider._();

final class _AllSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MealSlot>>,
          List<MealSlot>,
          Stream<List<MealSlot>>
        >
    with $FutureModifier<List<MealSlot>>, $StreamProvider<List<MealSlot>> {
  _AllSlotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_allSlotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_allSlotsHash();

  @$internal
  @override
  $StreamProviderElement<List<MealSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MealSlot>> create(Ref ref) {
    return _allSlots(ref);
  }
}

String _$_allSlotsHash() => r'e31f5000b27cac9839a46cfb6547530132517a36';
