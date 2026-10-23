// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null follows today across midnight; a historical date stays fixed.

@ProviderFor(TodayController)
final todayControllerProvider = TodayControllerProvider._();

/// Null follows today across midnight; a historical date stays fixed.
final class TodayControllerProvider
    extends $NotifierProvider<TodayController, LocalDate?> {
  /// Null follows today across midnight; a historical date stays fixed.
  TodayControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayControllerHash();

  @$internal
  @override
  TodayController create() => TodayController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate?>(value),
    );
  }
}

String _$todayControllerHash() => r'71f62ab4dfc98de57345fff1a73120827a914603';

/// Null follows today across midnight; a historical date stays fixed.

abstract class _$TodayController extends $Notifier<LocalDate?> {
  LocalDate? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocalDate?, LocalDate?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalDate?, LocalDate?>,
              LocalDate?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
