// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_snapshot.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Database boundary: callers receive plain snapshots only.

@ProviderFor(exportSnapshotReader)
final exportSnapshotReaderProvider = ExportSnapshotReaderProvider._();

/// Database boundary: callers receive plain snapshots only.

final class ExportSnapshotReaderProvider
    extends
        $FunctionalProvider<
          Future<ExportSnapshot> Function({
            required Iterable<String> settingNames,
          }),
          Future<ExportSnapshot> Function({
            required Iterable<String> settingNames,
          }),
          Future<ExportSnapshot> Function({
            required Iterable<String> settingNames,
          })
        >
    with
        $Provider<
          Future<ExportSnapshot> Function({
            required Iterable<String> settingNames,
          })
        > {
  /// Database boundary: callers receive plain snapshots only.
  ExportSnapshotReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportSnapshotReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportSnapshotReaderHash();

  @$internal
  @override
  $ProviderElement<
    Future<ExportSnapshot> Function({required Iterable<String> settingNames})
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Future<ExportSnapshot> Function({required Iterable<String> settingNames})
  create(Ref ref) {
    return exportSnapshotReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Future<ExportSnapshot> Function({required Iterable<String> settingNames})
    value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            Future<ExportSnapshot> Function({
              required Iterable<String> settingNames,
            })
          >(value),
    );
  }
}

String _$exportSnapshotReaderHash() =>
    r'63cda9f93bd9162bba176b4d21f17183ede2dcdc';
