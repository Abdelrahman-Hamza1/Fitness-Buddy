// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_language_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The voice-language preference.

@ProviderFor(voiceLanguageStore)
final voiceLanguageStoreProvider = VoiceLanguageStoreProvider._();

/// The voice-language preference.

final class VoiceLanguageStoreProvider
    extends
        $FunctionalProvider<
          VoiceLanguageStore,
          VoiceLanguageStore,
          VoiceLanguageStore
        >
    with $Provider<VoiceLanguageStore> {
  /// The voice-language preference.
  VoiceLanguageStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceLanguageStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceLanguageStoreHash();

  @$internal
  @override
  $ProviderElement<VoiceLanguageStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoiceLanguageStore create(Ref ref) {
    return voiceLanguageStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceLanguageStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceLanguageStore>(value),
    );
  }
}

String _$voiceLanguageStoreHash() =>
    r'f45ef05b9848627cd20e2f097faafea2a21b2d76';
