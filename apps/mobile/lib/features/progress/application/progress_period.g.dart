// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_period.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the [ProgressSelection]: session-only, kept while the app runs
/// (like the weight graph's window). Opens on this week (SC-5).

@ProviderFor(ProgressPeriodController)
final progressPeriodControllerProvider = ProgressPeriodControllerProvider._();

/// Holds the [ProgressSelection]: session-only, kept while the app runs
/// (like the weight graph's window). Opens on this week (SC-5).
final class ProgressPeriodControllerProvider
    extends $NotifierProvider<ProgressPeriodController, ProgressSelection> {
  /// Holds the [ProgressSelection]: session-only, kept while the app runs
  /// (like the weight graph's window). Opens on this week (SC-5).
  ProgressPeriodControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressPeriodControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressPeriodControllerHash();

  @$internal
  @override
  ProgressPeriodController create() => ProgressPeriodController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressSelection>(value),
    );
  }
}

String _$progressPeriodControllerHash() =>
    r'dfe74ae753bb86610da32bd070de7ef0b947052e';

/// Holds the [ProgressSelection]: session-only, kept while the app runs
/// (like the weight graph's window). Opens on this week (SC-5).

abstract class _$ProgressPeriodController extends $Notifier<ProgressSelection> {
  ProgressSelection build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProgressSelection, ProgressSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgressSelection, ProgressSelection>,
              ProgressSelection,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
