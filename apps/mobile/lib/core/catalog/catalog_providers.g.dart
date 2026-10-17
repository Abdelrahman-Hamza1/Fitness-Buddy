// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The installer of the bundled pack, under the application support
/// directory (`files/catalog/`, excluded from backups). The app scope makes
/// it the database's `catalogPackSource`.

@ProviderFor(catalogPackInstaller)
final catalogPackInstallerProvider = CatalogPackInstallerProvider._();

/// The installer of the bundled pack, under the application support
/// directory (`files/catalog/`, excluded from backups). The app scope makes
/// it the database's `catalogPackSource`.

final class CatalogPackInstallerProvider
    extends
        $FunctionalProvider<
          CatalogPackInstaller,
          CatalogPackInstaller,
          CatalogPackInstaller
        >
    with $Provider<CatalogPackInstaller> {
  /// The installer of the bundled pack, under the application support
  /// directory (`files/catalog/`, excluded from backups). The app scope makes
  /// it the database's `catalogPackSource`.
  CatalogPackInstallerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogPackInstallerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogPackInstallerHash();

  @$internal
  @override
  $ProviderElement<CatalogPackInstaller> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CatalogPackInstaller create(Ref ref) {
    return catalogPackInstaller(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogPackInstaller value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogPackInstaller>(value),
    );
  }
}

String _$catalogPackInstallerHash() =>
    r'be6e7ebc74c4910a36c0f5341a7fabdc1bbffc57';

/// Reads the attached offline catalog.

@ProviderFor(offlineCatalog)
final offlineCatalogProvider = OfflineCatalogProvider._();

/// Reads the attached offline catalog.

final class OfflineCatalogProvider
    extends $FunctionalProvider<OfflineCatalog, OfflineCatalog, OfflineCatalog>
    with $Provider<OfflineCatalog> {
  /// Reads the attached offline catalog.
  OfflineCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineCatalogHash();

  @$internal
  @override
  $ProviderElement<OfflineCatalog> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OfflineCatalog create(Ref ref) {
    return offlineCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineCatalog value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineCatalog>(value),
    );
  }
}

String _$offlineCatalogHash() => r'76f4d7baae07c71e4c997414cdbd9410a67da377';
