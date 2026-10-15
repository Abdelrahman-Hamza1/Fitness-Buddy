// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_config_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [ClientConfigRepository].

@ProviderFor(clientConfigRepository)
final clientConfigRepositoryProvider = ClientConfigRepositoryProvider._();

/// The app's [ClientConfigRepository].

final class ClientConfigRepositoryProvider
    extends
        $FunctionalProvider<
          ClientConfigRepository,
          ClientConfigRepository,
          ClientConfigRepository
        >
    with $Provider<ClientConfigRepository> {
  /// The app's [ClientConfigRepository].
  ClientConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientConfigRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientConfigRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClientConfigRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClientConfigRepository create(Ref ref) {
    return clientConfigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientConfigRepository>(value),
    );
  }
}

String _$clientConfigRepositoryHash() =>
    r'8c6f1a79bc6503501ea127125e867daa5c125932';
