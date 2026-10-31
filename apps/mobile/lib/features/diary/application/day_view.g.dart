// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auto-disposed by the screen's bounded prefetch subscriptions.

@ProviderFor(dayView)
final dayViewProvider = DayViewFamily._();

/// Auto-disposed by the screen's bounded prefetch subscriptions.

final class DayViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<DayView>,
          AsyncValue<DayView>,
          AsyncValue<DayView>
        >
    with $Provider<AsyncValue<DayView>> {
  /// Auto-disposed by the screen's bounded prefetch subscriptions.
  DayViewProvider._({
    required DayViewFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'dayViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayViewHash();

  @override
  String toString() {
    return r'dayViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<DayView>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<DayView> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return dayView(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DayView> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DayView>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DayViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayViewHash() => r'c71cc526c040924bb56c28c70188956da3bfadc8';

/// Auto-disposed by the screen's bounded prefetch subscriptions.

final class DayViewFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<DayView>, LocalDate> {
  DayViewFamily._()
    : super(
        retry: null,
        name: r'dayViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Auto-disposed by the screen's bounded prefetch subscriptions.

  DayViewProvider call(LocalDate date) =>
      DayViewProvider._(argument: date, from: this);

  @override
  String toString() => r'dayViewProvider';
}
