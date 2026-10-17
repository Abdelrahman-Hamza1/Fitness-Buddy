// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open profile (A01 D13): `local` until A33 adds accounts and guests.

@ProviderFor(profileKey)
final profileKeyProvider = ProfileKeyProvider._();

/// The open profile (A01 D13): `local` until A33 adds accounts and guests.

final class ProfileKeyProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The open profile (A01 D13): `local` until A33 adds accounts and guests.
  ProfileKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileKeyHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return profileKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$profileKeyHash() => r'c03e637b5c9b8f5b05a43dc79834911d46901db2';

/// Where the catalog pack is: none until A05 (A01 D14).

@ProviderFor(catalogPackSource)
final catalogPackSourceProvider = CatalogPackSourceProvider._();

/// Where the catalog pack is: none until A05 (A01 D14).

final class CatalogPackSourceProvider
    extends
        $FunctionalProvider<
          CatalogPackSource,
          CatalogPackSource,
          CatalogPackSource
        >
    with $Provider<CatalogPackSource> {
  /// Where the catalog pack is: none until A05 (A01 D14).
  CatalogPackSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogPackSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogPackSourceHash();

  @$internal
  @override
  $ProviderElement<CatalogPackSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CatalogPackSource create(Ref ref) {
    return catalogPackSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogPackSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogPackSource>(value),
    );
  }
}

String _$catalogPackSourceHash() => r'e87714ed55158e2d686a38aa7e82bc6b7db984a7';

/// Where the open profile's database lives.

@ProviderFor(databaseLocation)
final databaseLocationProvider = DatabaseLocationProvider._();

/// Where the open profile's database lives.

final class DatabaseLocationProvider
    extends
        $FunctionalProvider<
          DatabaseLocation,
          DatabaseLocation,
          DatabaseLocation
        >
    with $Provider<DatabaseLocation> {
  /// Where the open profile's database lives.
  DatabaseLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseLocationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseLocationHash();

  @$internal
  @override
  $ProviderElement<DatabaseLocation> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseLocation create(Ref ref) {
    return databaseLocation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseLocation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseLocation>(value),
    );
  }
}

String _$databaseLocationHash() => r'e1c7c02b7683c22e79664766ecc20c2fe56c5afa';

/// The open profile's database. Synchronous: it opens lazily on the first
/// query, so reading this provider touches no storage (UX-001). Closed when
/// the provider is disposed (a profile switch, A33).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The open profile's database. Synchronous: it opens lazily on the first
/// query, so reading this provider touches no storage (UX-001). Closed when
/// the provider is disposed (a profile switch, A33).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The open profile's database. Synchronous: it opens lazily on the first
  /// query, so reading this provider touches no storage (UX-001). Closed when
  /// the provider is disposed (a profile switch, A33).
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'159aea520ee2ef9207c27392cde0a08b8bc3d283';
