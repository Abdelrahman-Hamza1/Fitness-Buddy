// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only repository composition stays in data (application-db rule).

@ProviderFor(chatMessageRepository)
final chatMessageRepositoryProvider = ChatMessageRepositoryProvider._();

/// Read-only repository composition stays in data (application-db rule).

final class ChatMessageRepositoryProvider
    extends
        $FunctionalProvider<
          ChatMessageRepository,
          ChatMessageRepository,
          ChatMessageRepository
        >
    with $Provider<ChatMessageRepository> {
  /// Read-only repository composition stays in data (application-db rule).
  ChatMessageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessageRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatMessageRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatMessageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatMessageRepository create(Ref ref) {
    return chatMessageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMessageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMessageRepository>(value),
    );
  }
}

String _$chatMessageRepositoryHash() =>
    r'011be01d974552da6457f382ca963c796f6ff9f2';
