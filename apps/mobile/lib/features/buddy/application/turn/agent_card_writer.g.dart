// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_card_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's agent card writer.

@ProviderFor(agentCardWriter)
final agentCardWriterProvider = AgentCardWriterProvider._();

/// The app's agent card writer.

final class AgentCardWriterProvider
    extends
        $FunctionalProvider<AgentCardWriter, AgentCardWriter, AgentCardWriter>
    with $Provider<AgentCardWriter> {
  /// The app's agent card writer.
  AgentCardWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentCardWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentCardWriterHash();

  @$internal
  @override
  $ProviderElement<AgentCardWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AgentCardWriter create(Ref ref) {
    return agentCardWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentCardWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentCardWriter>(value),
    );
  }
}

String _$agentCardWriterHash() => r'4a58920c0ae3459cf99c59e1a0bc9e02551caee5';
