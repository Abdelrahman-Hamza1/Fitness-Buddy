// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'id_generator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's ID source (UUIDv7, `05` §1). `fb_domain`'s system generator is
/// wired in by the composition root (`lib/app/app_scope.dart`), the only
/// place that imports `package:fb_domain/system.dart`; tests may pass a
/// seeded one.

@ProviderFor(idGenerator)
final idGeneratorProvider = IdGeneratorProvider._();

/// The app's ID source (UUIDv7, `05` §1). `fb_domain`'s system generator is
/// wired in by the composition root (`lib/app/app_scope.dart`), the only
/// place that imports `package:fb_domain/system.dart`; tests may pass a
/// seeded one.

final class IdGeneratorProvider
    extends $FunctionalProvider<IdGenerator, IdGenerator, IdGenerator>
    with $Provider<IdGenerator> {
  /// The app's ID source (UUIDv7, `05` §1). `fb_domain`'s system generator is
  /// wired in by the composition root (`lib/app/app_scope.dart`), the only
  /// place that imports `package:fb_domain/system.dart`; tests may pass a
  /// seeded one.
  IdGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idGeneratorHash();

  @$internal
  @override
  $ProviderElement<IdGenerator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IdGenerator create(Ref ref) {
    return idGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdGenerator>(value),
    );
  }
}

String _$idGeneratorHash() => r'6527602fe85fb9cc22910d7f4ec5791f5bcc1aae';
