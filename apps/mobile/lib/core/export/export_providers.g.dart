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
        isAutoDispose: true,
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

String _$exportSharerHash() => r'0543806d990c4345a809734d7a0fe25bac221e0a';

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

String _$dataExportServiceHash() => r'469718b67d99906a5f015b7ae768ab6b9abd0f0a';
