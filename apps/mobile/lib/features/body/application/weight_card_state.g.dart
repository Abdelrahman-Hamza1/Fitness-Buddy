// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_card_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weight card's state for [date] (A14 D9). [isToday] adds the
/// cadence and the suggestion (D10, PA3: today's page only).
///
/// Synchronous over the shared weigh-in and trend streams: once they have
/// loaded (for any page), a newly shown day page has its card in the same
/// frame, with no skeleton. The unit setting is read only when there is a
/// weight to show, and the suggestion's preference only when it could show
/// (until it has loaded the suggestion stays hidden).

@ProviderFor(weightCard)
final weightCardProvider = WeightCardFamily._();

/// The weight card's state for [date] (A14 D9). [isToday] adds the
/// cadence and the suggestion (D10, PA3: today's page only).
///
/// Synchronous over the shared weigh-in and trend streams: once they have
/// loaded (for any page), a newly shown day page has its card in the same
/// frame, with no skeleton. The unit setting is read only when there is a
/// weight to show, and the suggestion's preference only when it could show
/// (until it has loaded the suggestion stays hidden).

final class WeightCardProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeightCardState>,
          AsyncValue<WeightCardState>,
          AsyncValue<WeightCardState>
        >
    with $Provider<AsyncValue<WeightCardState>> {
  /// The weight card's state for [date] (A14 D9). [isToday] adds the
  /// cadence and the suggestion (D10, PA3: today's page only).
  ///
  /// Synchronous over the shared weigh-in and trend streams: once they have
  /// loaded (for any page), a newly shown day page has its card in the same
  /// frame, with no skeleton. The unit setting is read only when there is a
  /// weight to show, and the suggestion's preference only when it could show
  /// (until it has loaded the suggestion stays hidden).
  WeightCardProvider._({
    required WeightCardFamily super.from,
    required (LocalDate, {bool isToday}) super.argument,
  }) : super(
         retry: null,
         name: r'weightCardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weightCardHash();

  @override
  String toString() {
    return r'weightCardProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<WeightCardState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<WeightCardState> create(Ref ref) {
    final argument = this.argument as (LocalDate, {bool isToday});
    return weightCard(ref, argument.$1, isToday: argument.isToday);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<WeightCardState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<WeightCardState>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WeightCardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weightCardHash() => r'a2fc892400d1eb52a01eaeed1abd61c0e23833c1';

/// The weight card's state for [date] (A14 D9). [isToday] adds the
/// cadence and the suggestion (D10, PA3: today's page only).
///
/// Synchronous over the shared weigh-in and trend streams: once they have
/// loaded (for any page), a newly shown day page has its card in the same
/// frame, with no skeleton. The unit setting is read only when there is a
/// weight to show, and the suggestion's preference only when it could show
/// (until it has loaded the suggestion stays hidden).

final class WeightCardFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<WeightCardState>,
          (LocalDate, {bool isToday})
        > {
  WeightCardFamily._()
    : super(
        retry: null,
        name: r'weightCardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The weight card's state for [date] (A14 D9). [isToday] adds the
  /// cadence and the suggestion (D10, PA3: today's page only).
  ///
  /// Synchronous over the shared weigh-in and trend streams: once they have
  /// loaded (for any page), a newly shown day page has its card in the same
  /// frame, with no skeleton. The unit setting is read only when there is a
  /// weight to show, and the suggestion's preference only when it could show
  /// (until it has loaded the suggestion stays hidden).

  WeightCardProvider call(LocalDate date, {required bool isToday}) =>
      WeightCardProvider._(argument: (date, isToday: isToday), from: this);

  @override
  String toString() => r'weightCardProvider';
}
