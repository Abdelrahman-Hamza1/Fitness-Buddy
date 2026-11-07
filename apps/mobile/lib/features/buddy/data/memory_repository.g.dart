// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The memory repository of the open profile.

@ProviderFor(memoryRepository)
final memoryRepositoryProvider = MemoryRepositoryProvider._();

/// The memory repository of the open profile.

final class MemoryRepositoryProvider
    extends
        $FunctionalProvider<
          MemoryRepository,
          MemoryRepository,
          MemoryRepository
        >
    with $Provider<MemoryRepository> {
  /// The memory repository of the open profile.
  MemoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemoryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoryRepository create(Ref ref) {
    return memoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoryRepository>(value),
    );
  }
}

String _$memoryRepositoryHash() => r'b5195b2e3fc6fdc7e4399085be7e2c1e93f5869c';
