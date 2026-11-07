// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_persistence_contributor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The registered contributors, in order: durable proposals (A23), learned
/// habits (A67).

@ProviderFor(proposalPersistenceContributors)
final proposalPersistenceContributorsProvider =
    ProposalPersistenceContributorsProvider._();

/// The registered contributors, in order: durable proposals (A23), learned
/// habits (A67).

final class ProposalPersistenceContributorsProvider
    extends
        $FunctionalProvider<
          List<ProposalPersistenceContributor>,
          List<ProposalPersistenceContributor>,
          List<ProposalPersistenceContributor>
        >
    with $Provider<List<ProposalPersistenceContributor>> {
  /// The registered contributors, in order: durable proposals (A23), learned
  /// habits (A67).
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
    r'fc67672d9ce24183dc2a8ec9fc8202f7c038bbeb';
