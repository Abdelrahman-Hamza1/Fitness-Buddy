// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watching safe state alone does no I/O or session startup.

@ProviderFor(SessionStateView)
final sessionStateViewProvider = SessionStateViewProvider._();

/// Watching safe state alone does no I/O or session startup.
final class SessionStateViewProvider
    extends $NotifierProvider<SessionStateView, SessionState> {
  /// Watching safe state alone does no I/O or session startup.
  SessionStateViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionStateViewProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionStateViewHash();

  @$internal
  @override
  SessionStateView create() => SessionStateView();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionStateViewHash() => r'1b2a4e86a63c0c995088bf931a212abf4a70f270';

/// Watching safe state alone does no I/O or session startup.

abstract class _$SessionStateView extends $Notifier<SessionState> {
  SessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Public token-free session view; observation never starts auth.

@ProviderFor(sessionState)
final sessionStateProvider = SessionStateProvider._();

/// Public token-free session view; observation never starts auth.

final class SessionStateProvider
    extends $FunctionalProvider<SessionState, SessionState, SessionState>
    with $Provider<SessionState> {
  /// Public token-free session view; observation never starts auth.
  SessionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionStateHash();

  @$internal
  @override
  $ProviderElement<SessionState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionState create(Ref ref) {
    return sessionState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionStateHash() => r'18da6baf30899d92c751d0d8318ae618d2fb4186';

/// Injectable monotonic and wall clocks, shared by transport and coordinator.

@ProviderFor(sessionClock)
final sessionClockProvider = SessionClockProvider._();

/// Injectable monotonic and wall clocks, shared by transport and coordinator.

final class SessionClockProvider
    extends $FunctionalProvider<SessionClock, SessionClock, SessionClock>
    with $Provider<SessionClock> {
  /// Injectable monotonic and wall clocks, shared by transport and coordinator.
  SessionClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionClockHash();

  @$internal
  @override
  $ProviderElement<SessionClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionClock create(Ref ref) {
    return sessionClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionClock>(value),
    );
  }
}

String _$sessionClockHash() => r'1a4e4df612d898a382f67f63b891f4af147d218d';

/// The one writer for this flavor/origin's session keys.

@ProviderFor(secureSessionStore)
final secureSessionStoreProvider = SecureSessionStoreProvider._();

/// The one writer for this flavor/origin's session keys.

final class SecureSessionStoreProvider
    extends
        $FunctionalProvider<
          SecureSessionStore,
          SecureSessionStore,
          SecureSessionStore
        >
    with $Provider<SecureSessionStore> {
  /// The one writer for this flavor/origin's session keys.
  SecureSessionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureSessionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureSessionStoreHash();

  @$internal
  @override
  $ProviderElement<SecureSessionStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SecureSessionStore create(Ref ref) {
    return secureSessionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureSessionStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureSessionStore>(value),
    );
  }
}

String _$secureSessionStoreHash() =>
    r'9c065ac9177e74cd1a4edd423457f179eb10209f';

/// Auth and normal Dio have independent adapter ownership.

@ProviderFor(authHttpClientAdapter)
final authHttpClientAdapterProvider = AuthHttpClientAdapterProvider._();

/// Auth and normal Dio have independent adapter ownership.

final class AuthHttpClientAdapterProvider
    extends
        $FunctionalProvider<
          HttpClientAdapter,
          HttpClientAdapter,
          HttpClientAdapter
        >
    with $Provider<HttpClientAdapter> {
  /// Auth and normal Dio have independent adapter ownership.
  AuthHttpClientAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authHttpClientAdapterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authHttpClientAdapterHash();

  @$internal
  @override
  $ProviderElement<HttpClientAdapter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HttpClientAdapter create(Ref ref) {
    return authHttpClientAdapter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HttpClientAdapter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HttpClientAdapter>(value),
    );
  }
}

String _$authHttpClientAdapterHash() =>
    r'fe9f79537c04565730bbcfcf45cbc87f4f98b754';

/// No auth interceptor, so refresh cannot recurse through the normal API Dio.

@ProviderFor(authTransport)
final authTransportProvider = AuthTransportProvider._();

/// No auth interceptor, so refresh cannot recurse through the normal API Dio.

final class AuthTransportProvider
    extends $FunctionalProvider<AuthTransport, AuthTransport, AuthTransport>
    with $Provider<AuthTransport> {
  /// No auth interceptor, so refresh cannot recurse through the normal API Dio.
  AuthTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authTransportHash();

  @$internal
  @override
  $ProviderElement<AuthTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthTransport create(Ref ref) {
    return authTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthTransport>(value),
    );
  }
}

String _$authTransportHash() => r'fd7afce82928e20167177f52970d97afa3e71be3';

/// A33 security 7: revokes a newly issued session that is abandoned before
/// it is committed (cancelled flow, refused merge) with its **own** bearer,
/// best effort. Uses the auth adapter; the token lives only in this call and
/// is never logged or stored.

@ProviderFor(abandonedSessionRevoker)
final abandonedSessionRevokerProvider = AbandonedSessionRevokerProvider._();

/// A33 security 7: revokes a newly issued session that is abandoned before
/// it is committed (cancelled flow, refused merge) with its **own** bearer,
/// best effort. Uses the auth adapter; the token lives only in this call and
/// is never logged or stored.

final class AbandonedSessionRevokerProvider
    extends
        $FunctionalProvider<
          Future<void> Function(String accessToken),
          Future<void> Function(String accessToken),
          Future<void> Function(String accessToken)
        >
    with $Provider<Future<void> Function(String accessToken)> {
  /// A33 security 7: revokes a newly issued session that is abandoned before
  /// it is committed (cancelled flow, refused merge) with its **own** bearer,
  /// best effort. Uses the auth adapter; the token lives only in this call and
  /// is never logged or stored.
  AbandonedSessionRevokerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'abandonedSessionRevokerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$abandonedSessionRevokerHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function(String accessToken)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function(String accessToken) create(Ref ref) {
    return abandonedSessionRevoker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function(String accessToken) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<void> Function(String accessToken)>(value),
    );
  }
}

String _$abandonedSessionRevokerHash() =>
    r'a1f7a59e70027509051ab9961cad9797caff81a9';

/// Lazy keepAlive coordinator; construction performs no storage/network I/O.

@ProviderFor(sessionService)
final sessionServiceProvider = SessionServiceProvider._();

/// Lazy keepAlive coordinator; construction performs no storage/network I/O.

final class SessionServiceProvider
    extends $FunctionalProvider<SessionService, SessionService, SessionService>
    with $Provider<SessionService> {
  /// Lazy keepAlive coordinator; construction performs no storage/network I/O.
  SessionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionServiceHash();

  @$internal
  @override
  $ProviderElement<SessionService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionService create(Ref ref) {
    return sessionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionService>(value),
    );
  }
}

String _$sessionServiceHash() => r'870fbdca3846d472bf4712c04d4abae1772f58b8';

/// Deferred lifecycle/scheduler; only bootstrap activates it after the frame.

@ProviderFor(sessionLifecycle)
final sessionLifecycleProvider = SessionLifecycleProvider._();

/// Deferred lifecycle/scheduler; only bootstrap activates it after the frame.

final class SessionLifecycleProvider
    extends
        $FunctionalProvider<
          SessionLifecycle,
          SessionLifecycle,
          SessionLifecycle
        >
    with $Provider<SessionLifecycle> {
  /// Deferred lifecycle/scheduler; only bootstrap activates it after the frame.
  SessionLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionLifecycleHash();

  @$internal
  @override
  $ProviderElement<SessionLifecycle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionLifecycle create(Ref ref) {
    return sessionLifecycle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionLifecycle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionLifecycle>(value),
    );
  }
}

String _$sessionLifecycleHash() => r'9a3e2179c0f49ebf0a7d26cea4c0c27d660229f9';

/// Transport notifications before bootstrap are deliberately discarded. Reading
/// this callback creates neither a lifecycle observer nor a session service.

@ProviderFor(sessionTransportSucceeded)
final sessionTransportSucceededProvider = SessionTransportSucceededProvider._();

/// Transport notifications before bootstrap are deliberately discarded. Reading
/// this callback creates neither a lifecycle observer nor a session service.

final class SessionTransportSucceededProvider
    extends
        $FunctionalProvider<void Function(), void Function(), void Function()>
    with $Provider<void Function()> {
  /// Transport notifications before bootstrap are deliberately discarded. Reading
  /// this callback creates neither a lifecycle observer nor a session service.
  SessionTransportSucceededProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionTransportSucceededProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionTransportSucceededHash();

  @$internal
  @override
  $ProviderElement<void Function()> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void Function() create(Ref ref) {
    return sessionTransportSucceeded(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void Function()>(value),
    );
  }
}

String _$sessionTransportSucceededHash() =>
    r'04458b24eea246d24ddae2836c25442acec163d3';
