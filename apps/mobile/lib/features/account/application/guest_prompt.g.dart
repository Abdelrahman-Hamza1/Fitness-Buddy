// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_prompt.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the gentle, dismissible "create an account" card shows on Today
/// (AC-002, A33 D8): the cadence rule is [GuestPromptPolicy]; this only
/// reads and records the instants. Once shown it stays for this run until
/// dismissed or the user is no longer a guest.

@ProviderFor(GuestPrompt)
final guestPromptProvider = GuestPromptProvider._();

/// Whether the gentle, dismissible "create an account" card shows on Today
/// (AC-002, A33 D8): the cadence rule is [GuestPromptPolicy]; this only
/// reads and records the instants. Once shown it stays for this run until
/// dismissed or the user is no longer a guest.
final class GuestPromptProvider
    extends $AsyncNotifierProvider<GuestPrompt, bool> {
  /// Whether the gentle, dismissible "create an account" card shows on Today
  /// (AC-002, A33 D8): the cadence rule is [GuestPromptPolicy]; this only
  /// reads and records the instants. Once shown it stays for this run until
  /// dismissed or the user is no longer a guest.
  GuestPromptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestPromptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestPromptHash();

  @$internal
  @override
  GuestPrompt create() => GuestPrompt();
}

String _$guestPromptHash() => r'a5598dda9754fbaab640152155942757076d715a';

/// Whether the gentle, dismissible "create an account" card shows on Today
/// (AC-002, A33 D8): the cadence rule is [GuestPromptPolicy]; this only
/// reads and records the instants. Once shown it stays for this run until
/// dismissed or the user is no longer a guest.

abstract class _$GuestPrompt extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
