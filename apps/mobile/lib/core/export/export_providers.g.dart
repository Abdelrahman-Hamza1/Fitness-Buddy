// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Share boundary override for host tests.

@ProviderFor(exportSharer)
final exportSharerProvider = ExportSharerProvider._();

/// Share boundary override for host tests.

final class ExportSharerProvider
    extends $FunctionalProvider<ExportSharer, ExportSharer, ExportSharer>
    with $Provider<ExportSharer> {
  /// Share boundary override for host tests.
  ExportSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportSharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportSharerHash();

  @$internal
  @override
  $ProviderElement<ExportSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportSharer create(Ref ref) {
    return exportSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportSharer>(value),
    );
  }
}

String _$exportSharerHash() => r'c07a7de6f3e7e62707381ffedad76ac6d303031b';

/// The share copies recorded per profile; the account layer deletes a
/// removed profile's copies through it. Construction does no I/O.

@ProviderFor(exportHandoffs)
final exportHandoffsProvider = ExportHandoffsProvider._();

/// The share copies recorded per profile; the account layer deletes a
/// removed profile's copies through it. Construction does no I/O.

final class ExportHandoffsProvider
    extends $FunctionalProvider<ExportHandoffs, ExportHandoffs, ExportHandoffs>
    with $Provider<ExportHandoffs> {
  /// The share copies recorded per profile; the account layer deletes a
  /// removed profile's copies through it. Construction does no I/O.
  ExportHandoffsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportHandoffsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportHandoffsHash();

  @$internal
  @override
  $ProviderElement<ExportHandoffs> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportHandoffs create(Ref ref) {
    return exportHandoffs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportHandoffs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportHandoffs>(value),
    );
  }
}

String _$exportHandoffsHash() => r'8050b9b4231739ccedfc8f3827e3db41468a49ce';

/// Keeps the operation alive through the share sheet, serializing exports.

@ProviderFor(dataExportService)
final dataExportServiceProvider = DataExportServiceProvider._();

/// Keeps the operation alive through the share sheet, serializing exports.

final class DataExportServiceProvider
    extends
        $FunctionalProvider<
          DataExportService,
          DataExportService,
          DataExportService
        >
    with $Provider<DataExportService> {
  /// Keeps the operation alive through the share sheet, serializing exports.
  DataExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataExportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataExportServiceHash();

  @$internal
  @override
  $ProviderElement<DataExportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DataExportService create(Ref ref) {
    return dataExportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataExportService>(value),
    );
  }
}

String _$dataExportServiceHash() => r'f30e304b14aebad3367931598c4b92399e90f7fd';
