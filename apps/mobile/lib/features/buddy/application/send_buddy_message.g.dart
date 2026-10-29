// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_buddy_message.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's send path.

@ProviderFor(sendBuddyMessage)
final sendBuddyMessageProvider = SendBuddyMessageProvider._();

/// The app's send path.

final class SendBuddyMessageProvider
    extends
        $FunctionalProvider<
          SendBuddyMessage,
          SendBuddyMessage,
          SendBuddyMessage
        >
    with $Provider<SendBuddyMessage> {
  /// The app's send path.
  SendBuddyMessageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendBuddyMessageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendBuddyMessageHash();

  @$internal
  @override
  $ProviderElement<SendBuddyMessage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendBuddyMessage create(Ref ref) {
    return sendBuddyMessage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendBuddyMessage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendBuddyMessage>(value),
    );
  }
}

String _$sendBuddyMessageHash() => r'f33bfc9aa8a9dbb91b935a5b4cbaf112339eb6fd';
