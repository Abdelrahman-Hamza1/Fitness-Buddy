// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_trace.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether this build asks for and shows Buddy's trace (AI-172, A66 D14):
/// dev builds, and the owner's builds made with
/// `--dart-define=FB_BUDDY_TRACE=true`. The server honours it only with
/// `Buddy:Agent:TraceEnabled`; the trace stays on the phone.

@ProviderFor(buddyTraceEnabled)
final buddyTraceEnabledProvider = BuddyTraceEnabledProvider._();

/// Whether this build asks for and shows Buddy's trace (AI-172, A66 D14):
/// dev builds, and the owner's builds made with
/// `--dart-define=FB_BUDDY_TRACE=true`. The server honours it only with
/// `Buddy:Agent:TraceEnabled`; the trace stays on the phone.

final class BuddyTraceEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this build asks for and shows Buddy's trace (AI-172, A66 D14):
  /// dev builds, and the owner's builds made with
  /// `--dart-define=FB_BUDDY_TRACE=true`. The server honours it only with
  /// `Buddy:Agent:TraceEnabled`; the trace stays on the phone.
  BuddyTraceEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyTraceEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyTraceEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return buddyTraceEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$buddyTraceEnabledHash() => r'ff229b00f3dd847679041aad49ae6c7e2ecbdee0';
