// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account status from the local registry and the session state.
/// Kept alive: Today's guest prompt depends on it.

@ProviderFor(accountStatus)
final accountStatusProvider = AccountStatusProvider._();

/// The account status from the local registry and the session state.
/// Kept alive: Today's guest prompt depends on it.

final class AccountStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccountStatus>,
          AccountStatus,
          FutureOr<AccountStatus>
        >
    with $FutureModifier<AccountStatus>, $FutureProvider<AccountStatus> {
  /// The account status from the local registry and the session state.
  /// Kept alive: Today's guest prompt depends on it.
  AccountStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountStatusHash();

  @$internal
  @override
  $FutureProviderElement<AccountStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AccountStatus> create(Ref ref) {
    return accountStatus(ref);
  }
}

String _$accountStatusHash() => r'8268a713bf762dfe37f80896e1cb869523d225eb';

/// Whether Google sign-in can be offered on this build (A33 D7).

@ProviderFor(googleSignInAvailable)
final googleSignInAvailableProvider = GoogleSignInAvailableProvider._();

/// Whether Google sign-in can be offered on this build (A33 D7).

final class GoogleSignInAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether Google sign-in can be offered on this build (A33 D7).
  GoogleSignInAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleSignInAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleSignInAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return googleSignInAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$googleSignInAvailableHash() =>
    r'084dbd5f98e763c1accaef5a1961a850fc2a3851';

/// Orchestrates the sign-in screen (A33 D4–D5, D9).

@ProviderFor(SignInController)
final signInControllerProvider = SignInControllerProvider._();

/// Orchestrates the sign-in screen (A33 D4–D5, D9).
final class SignInControllerProvider
    extends $NotifierProvider<SignInController, SignInState> {
  /// Orchestrates the sign-in screen (A33 D4–D5, D9).
  SignInControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInControllerHash();

  @$internal
  @override
  SignInController create() => SignInController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInState>(value),
    );
  }
}

String _$signInControllerHash() => r'8616433473533ccbd9b08cf2cbda4233deaa5441';

/// Orchestrates the sign-in screen (A33 D4–D5, D9).

abstract class _$SignInController extends $Notifier<SignInState> {
  SignInState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SignInState, SignInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignInState, SignInState>,
              SignInState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Sign-out from Me › Account (AC-004). Kept alive: the section only reads
/// it, and a sign-out outlives the frame that started it.

@ProviderFor(AccountActions)
final accountActionsProvider = AccountActionsProvider._();

/// Sign-out from Me › Account (AC-004). Kept alive: the section only reads
/// it, and a sign-out outlives the frame that started it.
final class AccountActionsProvider
    extends $NotifierProvider<AccountActions, void> {
  /// Sign-out from Me › Account (AC-004). Kept alive: the section only reads
  /// it, and a sign-out outlives the frame that started it.
  AccountActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountActionsHash();

  @$internal
  @override
  AccountActions create() => AccountActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$accountActionsHash() => r'e6ca722d7d6358cb345d90ac5827b1bb59c37454';

/// Sign-out from Me › Account (AC-004). Kept alive: the section only reads
/// it, and a sign-out outlives the frame that started it.

abstract class _$AccountActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
