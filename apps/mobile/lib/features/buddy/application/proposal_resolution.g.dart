// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_resolution.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's proposal resolution.

@ProviderFor(proposalResolution)
final proposalResolutionProvider = ProposalResolutionProvider._();

/// The app's proposal resolution.

final class ProposalResolutionProvider
    extends
        $FunctionalProvider<
          ProposalResolution,
          ProposalResolution,
          ProposalResolution
        >
    with $Provider<ProposalResolution> {
  /// The app's proposal resolution.
  ProposalResolutionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proposalResolutionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proposalResolutionHash();

  @$internal
  @override
  $ProviderElement<ProposalResolution> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProposalResolution create(Ref ref) {
    return proposalResolution(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProposalResolution value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProposalResolution>(value),
    );
  }
}

String _$proposalResolutionHash() =>
    r'83a90c31a66337f04547689ad8576d530ea0a547';
