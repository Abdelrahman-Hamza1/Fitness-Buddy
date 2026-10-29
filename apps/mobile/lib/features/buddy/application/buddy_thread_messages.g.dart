// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_thread_messages.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The saved rows of this process's thread by ID (A22 D11), live: the sheet
/// renders text and status from storage, never from memory.

@ProviderFor(buddyThreadMessages)
final buddyThreadMessagesProvider = BuddyThreadMessagesProvider._();

/// The saved rows of this process's thread by ID (A22 D11), live: the sheet
/// renders text and status from storage, never from memory.

final class BuddyThreadMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ChatMessage>>,
          Map<String, ChatMessage>,
          Stream<Map<String, ChatMessage>>
        >
    with
        $FutureModifier<Map<String, ChatMessage>>,
        $StreamProvider<Map<String, ChatMessage>> {
  /// The saved rows of this process's thread by ID (A22 D11), live: the sheet
  /// renders text and status from storage, never from memory.
  BuddyThreadMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyThreadMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyThreadMessagesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, ChatMessage>> create(Ref ref) {
    return buddyThreadMessages(ref);
  }
}

String _$buddyThreadMessagesHash() =>
    r'c9a7563927e8dfaa5ab9563614c461484ffc34e5';
