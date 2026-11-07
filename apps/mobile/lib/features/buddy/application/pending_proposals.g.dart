// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_proposals.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How many Buddy cards wait to be confirmed or discarded, of any kind,
/// plus messages waiting to be processed (AI-045, AI-047, HM-004, D-094):
/// Today's Buddy bar shows it as "{n} waiting". Re-emitted on every change;
/// pending cards never count toward totals.

@ProviderFor(pendingProposalCount)
final pendingProposalCountProvider = PendingProposalCountProvider._();

/// How many Buddy cards wait to be confirmed or discarded, of any kind,
/// plus messages waiting to be processed (AI-045, AI-047, HM-004, D-094):
/// Today's Buddy bar shows it as "{n} waiting". Re-emitted on every change;
/// pending cards never count toward totals.

final class PendingProposalCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// How many Buddy cards wait to be confirmed or discarded, of any kind,
  /// plus messages waiting to be processed (AI-045, AI-047, HM-004, D-094):
  /// Today's Buddy bar shows it as "{n} waiting". Re-emitted on every change;
  /// pending cards never count toward totals.
  PendingProposalCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingProposalCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingProposalCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return pendingProposalCount(ref);
  }
}

String _$pendingProposalCountHash() =>
    r'26e55e3c00d8a45a45d899ed9f9e7cce8df3cd8d';
