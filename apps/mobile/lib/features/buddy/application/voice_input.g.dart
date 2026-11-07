// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_input.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The listening panel's view model (A70 D5): asks for the microphone,
/// runs one recording at a time on the phone's recogniser and ends with
/// the words. It never sends anything: the words go to the message box.
///
/// Every transition bumps one operation number, checked after each await
/// and on each event (A70 review 2, 3, 6): a cancelled, suspended, stopped
/// or replaced recording can't start, finish or listen again. A new
/// recording waits for the previous cancel to reach the recogniser.

@ProviderFor(VoiceInputController)
final voiceInputControllerProvider = VoiceInputControllerProvider._();

/// The listening panel's view model (A70 D5): asks for the microphone,
/// runs one recording at a time on the phone's recogniser and ends with
/// the words. It never sends anything: the words go to the message box.
///
/// Every transition bumps one operation number, checked after each await
/// and on each event (A70 review 2, 3, 6): a cancelled, suspended, stopped
/// or replaced recording can't start, finish or listen again. A new
/// recording waits for the previous cancel to reach the recogniser.
final class VoiceInputControllerProvider
    extends $NotifierProvider<VoiceInputController, VoiceState> {
  /// The listening panel's view model (A70 D5): asks for the microphone,
  /// runs one recording at a time on the phone's recogniser and ends with
  /// the words. It never sends anything: the words go to the message box.
  ///
  /// Every transition bumps one operation number, checked after each await
  /// and on each event (A70 review 2, 3, 6): a cancelled, suspended, stopped
  /// or replaced recording can't start, finish or listen again. A new
  /// recording waits for the previous cancel to reach the recogniser.
  VoiceInputControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceInputControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceInputControllerHash();

  @$internal
  @override
  VoiceInputController create() => VoiceInputController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceState>(value),
    );
  }
}

String _$voiceInputControllerHash() =>
    r'ccd564e20eb3be5cbfcca3b1557fba04ca457f7e';

/// The listening panel's view model (A70 D5): asks for the microphone,
/// runs one recording at a time on the phone's recogniser and ends with
/// the words. It never sends anything: the words go to the message box.
///
/// Every transition bumps one operation number, checked after each await
/// and on each event (A70 review 2, 3, 6): a cancelled, suspended, stopped
/// or replaced recording can't start, finish or listen again. A new
/// recording waits for the previous cancel to reach the recogniser.

abstract class _$VoiceInputController extends $Notifier<VoiceState> {
  VoiceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VoiceState, VoiceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VoiceState, VoiceState>,
              VoiceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
