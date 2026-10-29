// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_persistence_contributor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The registered contributors, in order. Empty in A22a.

@ProviderFor(proposalPersistenceContributors)
final proposalPersistenceContributorsProvider =
    ProposalPersistenceContributorsProvider._();

/// The registered contributors, in order. Empty in A22a.

final class ProposalPersistenceContributorsProvider
    extends
        $FunctionalProvider<
          List<ProposalPersistenceContributor>,
          List<ProposalPersistenceContributor>,
          List<ProposalPersistenceContributor>
        >
    with $Provider<List<ProposalPersistenceContributor>> {
  /// The registered contributors, in order. Empty in A22a.
  ProposalPersistenceContributorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proposalPersistenceContributorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proposalPersistenceContributorsHash();

  @$internal
  @override
  $ProviderElement<List<ProposalPersistenceContributor>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ProposalPersistenceContributor> create(Ref ref) {
    return proposalPersistenceContributors(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ProposalPersistenceContributor> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<List<ProposalPersistenceContributor>>(value),
    );
  }
}

String _$proposalPersistenceContributorsHash() =>
    r'263dd872ff3267753c5d3183c63ef8b49f9b8a8b';
