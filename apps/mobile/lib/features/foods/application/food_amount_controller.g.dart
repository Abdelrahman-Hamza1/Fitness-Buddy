// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_amount_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-sheet notifier exposing immutable input and derived nutrition state.

@ProviderFor(FoodAmountController)
final foodAmountControllerProvider = FoodAmountControllerFamily._();

/// Per-sheet notifier exposing immutable input and derived nutrition state.
final class FoodAmountControllerProvider
    extends $AsyncNotifierProvider<FoodAmountController, FoodAmountState> {
  /// Per-sheet notifier exposing immutable input and derived nutrition state.
  FoodAmountControllerProvider._({
    required FoodAmountControllerFamily super.from,
    required (
      FoodChoiceRef,
      LocalDate, {
      String? slotId,
      ParsedAmount? carried,
      VersionedId? replacing,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'foodAmountControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodAmountControllerHash();

  @override
  String toString() {
    return r'foodAmountControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  FoodAmountController create() => FoodAmountController();

  @override
  bool operator ==(Object other) {
    return other is FoodAmountControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodAmountControllerHash() =>
    r'7507b31b0fc106fb29bd12b2fa7e5bf404ce1155';

/// Per-sheet notifier exposing immutable input and derived nutrition state.

final class FoodAmountControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FoodAmountController,
          AsyncValue<FoodAmountState>,
          FoodAmountState,
          FutureOr<FoodAmountState>,
          (
            FoodChoiceRef,
            LocalDate, {
            String? slotId,
            ParsedAmount? carried,
            VersionedId? replacing,
          })
        > {
  FoodAmountControllerFamily._()
    : super(
        retry: null,
        name: r'foodAmountControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-sheet notifier exposing immutable input and derived nutrition state.

  FoodAmountControllerProvider call(
    FoodChoiceRef choice,
    LocalDate date, {
    String? slotId,
    ParsedAmount? carried,
    VersionedId? replacing,
  }) => FoodAmountControllerProvider._(
    argument: (
      choice,
      date,
      slotId: slotId,
      carried: carried,
      replacing: replacing,
    ),
    from: this,
  );

  @override
  String toString() => r'foodAmountControllerProvider';
}

/// Per-sheet notifier exposing immutable input and derived nutrition state.

abstract class _$FoodAmountController extends $AsyncNotifier<FoodAmountState> {
  late final _$args =
      ref.$arg
          as (
            FoodChoiceRef,
            LocalDate, {
            String? slotId,
            ParsedAmount? carried,
            VersionedId? replacing,
          });
  FoodChoiceRef get choice => _$args.$1;
  LocalDate get date => _$args.$2;
  String? get slotId => _$args.slotId;
  ParsedAmount? get carried => _$args.carried;
  VersionedId? get replacing => _$args.replacing;

  FutureOr<FoodAmountState> build(
    FoodChoiceRef choice,
    LocalDate date, {
    String? slotId,
    ParsedAmount? carried,
    VersionedId? replacing,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FoodAmountState>, FoodAmountState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FoodAmountState>, FoodAmountState>,
              AsyncValue<FoodAmountState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        _$args.$1,
        _$args.$2,
        slotId: _$args.slotId,
        carried: _$args.carried,
        replacing: _$args.replacing,
      ),
    );
  }
}
