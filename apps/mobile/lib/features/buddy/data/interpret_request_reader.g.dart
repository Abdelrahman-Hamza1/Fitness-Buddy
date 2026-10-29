// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interpret_request_reader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The interpret request reader of the open profile.

@ProviderFor(interpretRequestReader)
final interpretRequestReaderProvider = InterpretRequestReaderProvider._();

/// The interpret request reader of the open profile.

final class InterpretRequestReaderProvider
    extends
        $FunctionalProvider<
          InterpretRequestReader,
          InterpretRequestReader,
          InterpretRequestReader
        >
    with $Provider<InterpretRequestReader> {
  /// The interpret request reader of the open profile.
  InterpretRequestReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interpretRequestReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interpretRequestReaderHash();

  @$internal
  @override
  $ProviderElement<InterpretRequestReader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InterpretRequestReader create(Ref ref) {
    return interpretRequestReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InterpretRequestReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InterpretRequestReader>(value),
    );
  }
}

String _$interpretRequestReaderHash() =>
    r'df9b6f54440df47251df0ee54f8724457fe6c12d';

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
