// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_export.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One export at a time, with the settings feature's complete key vocabulary.

@ProviderFor(DataExportController)
final dataExportControllerProvider = DataExportControllerProvider._();

/// One export at a time, with the settings feature's complete key vocabulary.
final class DataExportControllerProvider
    extends $NotifierProvider<DataExportController, DataExportState> {
  /// One export at a time, with the settings feature's complete key vocabulary.
  DataExportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataExportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataExportControllerHash();

  @$internal
  @override
  DataExportController create() => DataExportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataExportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataExportState>(value),
    );
  }
}

String _$dataExportControllerHash() =>
    r'd07c63da4e3ce624ff32e3dcf511729fc9ddc366';

/// One export at a time, with the settings feature's complete key vocabulary.

abstract class _$DataExportController extends $Notifier<DataExportState> {
  DataExportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DataExportState, DataExportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DataExportState, DataExportState>,
              DataExportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
