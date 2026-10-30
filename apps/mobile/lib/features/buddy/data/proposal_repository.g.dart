// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only repository composition stays in data (application-db rule).

@ProviderFor(proposalRepository)
final proposalRepositoryProvider = ProposalRepositoryProvider._();

/// Read-only repository composition stays in data (application-db rule).

final class ProposalRepositoryProvider
    extends
        $FunctionalProvider<
          ProposalRepository,
          ProposalRepository,
          ProposalRepository
        >
    with $Provider<ProposalRepository> {
  /// Read-only repository composition stays in data (application-db rule).
  ProposalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proposalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proposalRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProposalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProposalRepository create(Ref ref) {
    return proposalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProposalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProposalRepository>(value),
    );
  }
}

String _$proposalRepositoryHash() =>
    r'5336b389f015428df0071378246859c053e432cf';
