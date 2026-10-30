// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_prompt_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [GuestPromptStore].

@ProviderFor(guestPromptStore)
final guestPromptStoreProvider = GuestPromptStoreProvider._();

/// The app's [GuestPromptStore].

final class GuestPromptStoreProvider
    extends
        $FunctionalProvider<
          GuestPromptStore,
          GuestPromptStore,
          GuestPromptStore
        >
    with $Provider<GuestPromptStore> {
  /// The app's [GuestPromptStore].
  GuestPromptStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestPromptStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestPromptStoreHash();

  @$internal
  @override
  $ProviderElement<GuestPromptStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GuestPromptStore create(Ref ref) {
    return guestPromptStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuestPromptStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuestPromptStore>(value),
    );
  }
}

String _$guestPromptStoreHash() => r'dc29c6becf97dd165028190010e89c490d008647';
