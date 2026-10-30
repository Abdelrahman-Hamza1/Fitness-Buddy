// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open profile (A01 D13), or `null` until an A33 switch: then the
/// database location reads the registry's active profile lazily when the
/// database opens (A33 D3), so no storage is touched here.

@ProviderFor(ProfileKey)
final profileKeyProvider = ProfileKeyProvider._();

/// The open profile (A01 D13), or `null` until an A33 switch: then the
/// database location reads the registry's active profile lazily when the
/// database opens (A33 D3), so no storage is touched here.
final class ProfileKeyProvider extends $NotifierProvider<ProfileKey, String?> {
  /// The open profile (A01 D13), or `null` until an A33 switch: then the
  /// database location reads the registry's active profile lazily when the
  /// database opens (A33 D3), so no storage is touched here.
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
  ProfileKey create() => ProfileKey();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$profileKeyHash() => r'c372b242c80e33ddd5c345f5870c91f5a6e56d20';

/// The open profile (A01 D13), or `null` until an A33 switch: then the
/// database location reads the registry's active profile lazily when the
/// database opens (A33 D3), so no storage is touched here.

abstract class _$ProfileKey extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Reads the active profile from the registry when the database opens
/// (A33 D3). Overridden by the account layer; tests keep `local`.

@ProviderFor(activeProfileResolver)
final activeProfileResolverProvider = ActiveProfileResolverProvider._();

/// Reads the active profile from the registry when the database opens
/// (A33 D3). Overridden by the account layer; tests keep `local`.

final class ActiveProfileResolverProvider
    extends
        $FunctionalProvider<
          Future<String> Function()?,
          Future<String> Function()?,
          Future<String> Function()?
        >
    with $Provider<Future<String> Function()?> {
  /// Reads the active profile from the registry when the database opens
  /// (A33 D3). Overridden by the account layer; tests keep `local`.
  ActiveProfileResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeProfileResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeProfileResolverHash();

  @$internal
  @override
  $ProviderElement<Future<String> Function()?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<String> Function()? create(Ref ref) {
    return activeProfileResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<String> Function()? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<String> Function()?>(value),
    );
  }
}

String _$activeProfileResolverHash() =>
    r'9a1b266c8508c0143918f3d9a256f3b140262f76';

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

String _$databaseLocationHash() => r'2657c7ab5f0013da60f5439b04b30feddb9e145d';

/// The one [OpenProfileHandles] (no dependencies).

@ProviderFor(openProfileHandles)
final openProfileHandlesProvider = OpenProfileHandlesProvider._();

/// The one [OpenProfileHandles] (no dependencies).

final class OpenProfileHandlesProvider
    extends
        $FunctionalProvider<
          OpenProfileHandles,
          OpenProfileHandles,
          OpenProfileHandles
        >
    with $Provider<OpenProfileHandles> {
  /// The one [OpenProfileHandles] (no dependencies).
  OpenProfileHandlesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openProfileHandlesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openProfileHandlesHash();

  @$internal
  @override
  $ProviderElement<OpenProfileHandles> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OpenProfileHandles create(Ref ref) {
    return openProfileHandles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenProfileHandles value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenProfileHandles>(value),
    );
  }
}

String _$openProfileHandlesHash() =>
    r'dbff930e805e774dcc1555185325f4025f5517dc';

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

String _$appDatabaseHash() => r'5724ac97f1e2798e6f99a892fa1c06a7f9f9e692';
