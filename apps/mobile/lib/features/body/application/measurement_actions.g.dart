// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Measurement commands (A15b D15): every write is one change set through
/// the single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight ([logKey] /
/// [createTypeKey] for new rows, else the row's ID).

@ProviderFor(MeasurementActions)
final measurementActionsProvider = MeasurementActionsProvider._();

/// Measurement commands (A15b D15): every write is one change set through
/// the single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight ([logKey] /
/// [createTypeKey] for new rows, else the row's ID).
final class MeasurementActionsProvider
    extends $NotifierProvider<MeasurementActions, Set<String>> {
  /// Measurement commands (A15b D15): every write is one change set through
  /// the single writer, pushed to the undo stack as a direct action (UX-030).
  /// Session-lived, so an action outlives the sheet that started it. The
  /// state is the set of identities with an action in flight ([logKey] /
  /// [createTypeKey] for new rows, else the row's ID).
  MeasurementActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'measurementActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measurementActionsHash();

  @$internal
  @override
  MeasurementActions create() => MeasurementActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$measurementActionsHash() =>
    r'1a54d6d99a5fca0ab68b71732945f680e222b6e6';

/// Measurement commands (A15b D15): every write is one change set through
/// the single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight ([logKey] /
/// [createTypeKey] for new rows, else the row's ID).

abstract class _$MeasurementActions extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
