// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_input_loader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The proposal loader of the open profile, with the client config snapshot
/// at load time (thresholds) and the installed catalog.

@ProviderFor(proposalInputLoader)
final proposalInputLoaderProvider = ProposalInputLoaderProvider._();

/// The proposal loader of the open profile, with the client config snapshot
/// at load time (thresholds) and the installed catalog.

final class ProposalInputLoaderProvider
    extends
        $FunctionalProvider<
          ProposalInputLoader,
          ProposalInputLoader,
          ProposalInputLoader
        >
    with $Provider<ProposalInputLoader> {
  /// The proposal loader of the open profile, with the client config snapshot
  /// at load time (thresholds) and the installed catalog.
  ProposalInputLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proposalInputLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proposalInputLoaderHash();

  @$internal
  @override
  $ProviderElement<ProposalInputLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProposalInputLoader create(Ref ref) {
    return proposalInputLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProposalInputLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProposalInputLoader>(value),
    );
  }
}

String _$proposalInputLoaderHash() =>
    r'18aad32c98d080c2869c099c361e6e688e5440c1';
