/// Persisted identity classification; independent of network availability.
enum SessionKind {
  /// Server guest identity.
  anonymous,

  /// Identity requiring sign-in after terminal failure.
  registered,
}

/// Token-free session lifecycle. A33 owns the expired-session UI.
enum SessionStatus {
  /// No account confirmed by successful storage read.
  none,

  /// Server guest.
  anonymous,

  /// Signed-in account, including offline.
  registered,

  /// Registered marker without usable credentials.
  sessionExpired,
}

/// Availability is separate so offline never changes account identity.
enum SessionReadiness {
  /// Startup has not run.
  idle,

  /// An operation is in flight.
  pending,

  /// Durably stored request credentials are available.
  ready,

  /// Storage or transport cannot currently supply credentials.
  unavailable,
}

/// Safe provider-facing state. The account reference is opaque, never a token.
final class SessionState {
  /// Creates token-free state.
  const new({
    required this.status,
    this.readiness = SessionReadiness.idle,
    this.accountReference,
  });

  /// Identity lifecycle.
  final SessionStatus status;

  /// Current availability.
  final SessionReadiness readiness;

  /// Opaque storage reference, not the server user id.
  final String? accountReference;

  @override
  String toString() => 'SessionState(${status.name}, ${readiness.name})';
}

/// Fixed diagnostic kinds; never retain underlying plugin exceptions.
enum SessionStorageFailureKind {
  /// Secret store could not be read.
  unavailable,

  /// Persisted data failed validation.
  malformed,

  /// Mutation did not obtain durable acknowledgement.
  durability,
}

/// Fail closed while retaining any independently readable account marker.
final class SessionStorageFailure implements Exception {
  /// Creates a redacted storage failure.
  const new(this.kind, {this.knownState});

  /// Safe diagnostic category.
  final SessionStorageFailureKind kind;

  /// Identity survives credential corruption; never interpret failure as none.
  final SessionState? knownState;

  @override
  String toString() => 'SessionStorageFailure(${kind.name})';
}
