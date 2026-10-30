// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The non-secret profile registry (A33 D1).

@ProviderFor(profileRegistry)
final profileRegistryProvider = ProfileRegistryProvider._();

/// The non-secret profile registry (A33 D1).

final class ProfileRegistryProvider
    extends
        $FunctionalProvider<ProfileRegistry, ProfileRegistry, ProfileRegistry>
    with $Provider<ProfileRegistry> {
  /// The non-secret profile registry (A33 D1).
  ProfileRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRegistryHash();

  @$internal
  @override
  $ProviderElement<ProfileRegistry> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileRegistry create(Ref ref) {
    return profileRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRegistry>(value),
    );
  }
}

String _$profileRegistryHash() => r'5762609c4ec261da3f4f9d22528f7d55c0eb52f8';

/// Google ID tokens: unconfigured until the owner sets up OAuth (A33 D7).

@ProviderFor(googleIdTokenSource)
final googleIdTokenSourceProvider = GoogleIdTokenSourceProvider._();

/// Google ID tokens: unconfigured until the owner sets up OAuth (A33 D7).

final class GoogleIdTokenSourceProvider
    extends
        $FunctionalProvider<
          GoogleIdTokenSource,
          GoogleIdTokenSource,
          GoogleIdTokenSource
        >
    with $Provider<GoogleIdTokenSource> {
  /// Google ID tokens: unconfigured until the owner sets up OAuth (A33 D7).
  GoogleIdTokenSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleIdTokenSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleIdTokenSourceHash();

  @$internal
  @override
  $ProviderElement<GoogleIdTokenSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoogleIdTokenSource create(Ref ref) {
    return googleIdTokenSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleIdTokenSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleIdTokenSource>(value),
    );
  }
}

String _$googleIdTokenSourceHash() =>
    r'706cb2fe6a2dc8e8282d73926a772560e5ca5924';

/// The account transition lifecycle (A33 §6). Construction does no I/O.

@ProviderFor(accountTransitions)
final accountTransitionsProvider = AccountTransitionsProvider._();

/// The account transition lifecycle (A33 §6). Construction does no I/O.

final class AccountTransitionsProvider
    extends
        $FunctionalProvider<
          AccountTransitions,
          AccountTransitions,
          AccountTransitions
        >
    with $Provider<AccountTransitions> {
  /// The account transition lifecycle (A33 §6). Construction does no I/O.
  AccountTransitionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountTransitionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountTransitionsHash();

  @$internal
  @override
  $ProviderElement<AccountTransitions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountTransitions create(Ref ref) {
    return accountTransitions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountTransitions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountTransitions>(value),
    );
  }
}

String _$accountTransitionsHash() =>
    r'8d25a0ddbda5a05c87d785c2c0ad602b67b426fa';

/// True while an account transition with a journal runs (sign-in, sign-out,
/// recovery of an interrupted one): the app shows a calm blocking state so
/// no profile-dependent UI opens until the profile generation switched
/// (A33 re-check 3).

@ProviderFor(AccountBusy)
final accountBusyProvider = AccountBusyProvider._();

/// True while an account transition with a journal runs (sign-in, sign-out,
/// recovery of an interrupted one): the app shows a calm blocking state so
/// no profile-dependent UI opens until the profile generation switched
/// (A33 re-check 3).
final class AccountBusyProvider extends $NotifierProvider<AccountBusy, bool> {
  /// True while an account transition with a journal runs (sign-in, sign-out,
  /// recovery of an interrupted one): the app shows a calm blocking state so
  /// no profile-dependent UI opens until the profile generation switched
  /// (A33 re-check 3).
  AccountBusyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountBusyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountBusyHash();

  @$internal
  @override
  AccountBusy create() => AccountBusy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$accountBusyHash() => r'01a94d9ea2ccaec834d458b43309af6361c71a08';

/// True while an account transition with a journal runs (sign-in, sign-out,
/// recovery of an interrupted one): the app shows a calm blocking state so
/// no profile-dependent UI opens until the profile generation switched
/// (A33 re-check 3).

abstract class _$AccountBusy extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The registry-backed write gate, suspended during live transitions.

@ProviderFor(accountWriteGate)
final accountWriteGateProvider = AccountWriteGateProvider._();

/// The registry-backed write gate, suspended during live transitions.

final class AccountWriteGateProvider
    extends
        $FunctionalProvider<
          ProfileWriteGate,
          ProfileWriteGate,
          ProfileWriteGate
        >
    with $Provider<ProfileWriteGate> {
  /// The registry-backed write gate, suspended during live transitions.
  AccountWriteGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountWriteGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountWriteGateHash();

  @$internal
  @override
  $ProviderElement<ProfileWriteGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileWriteGate create(Ref ref) {
    return accountWriteGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileWriteGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileWriteGate>(value),
    );
  }
}

String _$accountWriteGateHash() => r'0654d26fb51705b048083fa1f1ef4c875c5f5067';

/// Sign-in, upgrade and sign-out (A33 D4–D6, §6).

@ProviderFor(accountService)
final accountServiceProvider = AccountServiceProvider._();

/// Sign-in, upgrade and sign-out (A33 D4–D6, §6).

final class AccountServiceProvider
    extends $FunctionalProvider<AccountService, AccountService, AccountService>
    with $Provider<AccountService> {
  /// Sign-in, upgrade and sign-out (A33 D4–D6, §6).
  AccountServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountServiceHash();

  @$internal
  @override
  $ProviderElement<AccountService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountService create(Ref ref) {
    return accountService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountService>(value),
    );
  }
}

String _$accountServiceHash() => r'25fc974e168c7a3b292e427de3ae587fe82aea37';
