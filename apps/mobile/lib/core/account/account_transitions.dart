import 'dart:async';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';

/// What a sign-in installs: the active profile entry and, optionally, a
/// profile to reserve and delete last.
typedef SignInPlan = ({LocalProfile target, String? discard});

/// The sign-in ended **provably before** its credentials were committed:
/// no local change remains and the issued session is unused, so the caller
/// may revoke it (A33 security 7). [cancelled] is true when the flow was
/// cancelled, replaced or signed out meanwhile.
final class SignInNotCommitted implements Exception {
  /// No details beyond the reason.
  const new({required this.cancelled});

  /// The flow was cancelled (otherwise a pre-commit failure).
  final bool cancelled;

  @override
  String toString() => 'SignInNotCommitted(cancelled: $cancelled)';
}

/// An account deletion step was refused (A35 fix 2): the profile isn't the
/// one confirmed, another transition is open, or a deletion request is in
/// flight. Nothing changed.
final class DeletionRefused implements Exception {
  /// A refusal.
  const new();

  @override
  String toString() => 'DeletionRefused';
}

/// The session side of a transition (adapter over A20's `SessionService`).
abstract interface class AccountSession {
  /// Persists and publishes registered tokens (durable before it completes),
  /// storing [commitTag] in the envelope.
  Future<void> accept(AuthTokens tokens, {required String commitTag});

  /// The hashed keys of every stored credential envelope (journaled before
  /// sign-out clears anything).
  Future<List<String>> storedCredentialRefs();

  /// Forgets the current credentials and every key in [refs], with or
  /// without a pointer; fails closed on storage errors.
  Future<void> end(List<String> refs);

  /// Suspends lease acquisition until the returned release runs.
  void Function() suspend();

  /// The commit tag of the durably selected envelope, or `null`.
  Future<String?> activeCommitTag();

  /// Completes or discards an interrupted secure save (recovery only).
  Future<void> reconcile();
}

/// Opens profiles and deletes their files (Riverpod adapter in the app).
abstract interface class ProfileHost {
  /// Makes [profileKey] the open database; completes once the old one closed.
  Future<void> activate(String profileKey);

  /// Deletes `profiles/<profileKey>/` after every pending close.
  Future<void> deleteFiles(String profileKey);

  /// Completes once every queued write on the open database has finished.
  Future<void> quiesce();
}

/// The one coordinated lifecycle for profile ownership, write permission and
/// credentials (A33 §6). Every change goes through a durable journal stored
/// atomically with the registry; destructive cleanup runs last; [recover]
/// resumes or rolls back after a crash.
final class AccountTransitions {
  /// Construction does no I/O.
  new({
    required this._registry,
    required this._session,
    required this._host,
    required this._newTag,
    this._onBusy,
  });

  /// Published with `busy:` true/false as journaled transitions start/end.
  final void Function({required bool busy})? _onBusy;
  int _busy = 0;

  void _setBusy(int delta) {
    final was = _busy > 0;
    _busy += delta;
    if (was != _busy > 0) _onBusy?.call(busy: _busy > 0);
  }

  final ProfileRegistry _registry;
  final AccountSession _session;
  final ProfileHost _host;

  /// A unique, opaque tag per sign-in transition (a UUIDv7 in the app).
  final String Function() _newTag;

  Future<void> _lock = Future<void>.value();
  int _running = 0;

  /// The profile whose `DELETE /v1/me` is in flight (A35 fix 2): sign-in,
  /// sign-out and switches are refused meanwhile, so the profile and its
  /// credentials can't change under the request.
  String? _deleting;

  /// Whether an account deletion request is in flight (sync pauses).
  bool get deleting => _deleting != null;

  /// Whether a deletion request for [profileKey] may still be sent: it is
  /// the one in flight and no transition runs (checked after the request
  /// has its credentials, A35 fix 2).
  bool deletionBoundTo(String profileKey) =>
      _deleting == profileKey && !suspended;

  /// True while a live transition runs: writes are denied synchronously.
  bool get suspended => _running > 0;

  Future<T> _exclusive<T>(Future<T> Function() body) {
    final result = _lock.then((_) => body());
    _lock = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  // Session acquisition stays suspended from the start of a transition
  // until the journal is durably clear: a failed step, a failed journal
  // write or an unreadable registry keeps it suspended (A33 security 2).
  void Function()? _heldSession;

  void _holdSession() => _heldSession ??= _session.suspend();

  Future<void> _releaseSessionIfSettled() async {
    try {
      if ((await _registry.read()).transition != null) return;
    } on Object {
      return; // Fail closed: stay suspended.
    }
    // Called by a transition that still counts itself: a later one queued
    // meanwhile keeps the hold.
    if (_running > 1) return;
    _heldSession?.call();
    _heldSession = null;
  }

  /// Whether session acquisition is held for an unfinished transition.
  bool get holdsSession => _heldSession != null;

  /// [busy]: the transition writes a journal (true), or only recovers one
  /// if present (null: busy only when a journal exists).
  Future<T> _live<T>(Future<T> Function() body, {bool? busy = true}) {
    // Suspended synchronously when enqueued, not when the lock is reached:
    // a write arriving meanwhile is denied at once instead of queueing in
    // front of the transition's quiesce (A33 security 6).
    _running++;
    _holdSession();
    var busyCounted = busy ?? false;
    if (busyCounted) _setBusy(1);
    return _exclusive(() async {
      try {
        if (busy == null &&
            (await _registry.read()).transitionPending &&
            !busyCounted) {
          busyCounted = true;
          _setBusy(1);
        }
        await _host.quiesce();
        await _recover(live: true);
        return await body();
      } finally {
        await _releaseSessionIfSettled();
      }
    }).whenComplete(() {
      _running--;
      // Released only after any profile switch (new generation) happened.
      if (busyCounted) _setBusy(-1);
    });
  }

  /// Signs in with [tokens] (already proven by the server, held in memory
  /// only): [plan] picks, inside the lock and against the current registry,
  /// the profile to install and an optional one to reserve and delete last
  /// (`null` = refused, nothing changes). Nothing local changes before the
  /// tokens are durably stored; [stillValid] is checked inside the lock
  /// before any commit.
  Future<void> signIn({
    required AuthTokens tokens,
    required SignInPlan? Function(ProfilesSnapshot) plan,
    required bool Function() stillValid,
  }) async {
    // True until the credentials may have been committed; a failure while it
    // holds is reported as SignInNotCommitted (revocable).
    var provenUncommitted = true;
    try {
      await _live(() async {
        // Inside the lock, before any commit: a flow cancelled (or replaced,
        // or signed out) while this waited must not sign back in.
        if (!stillValid()) throw const SignInNotCommitted(cancelled: true);
        // A35: never while a deletion request is in flight.
        if (_deleting != null) {
          throw const SignInNotCommitted(cancelled: false);
        }
        final snapshot = await _registry.read();
        final planned = plan(snapshot);
        if (planned == null) return;
        final (:target, :discard) = planned;
        final transition = AccountTransition(
          kind: TransitionKind.signIn,
          phase: TransitionPhase.preparing,
          fromKey: snapshot.activeKey,
          target: target,
          commitTag: _newTag(),
          discard: discard == target.profileKey ? null : discard,
        );
        if (!stillValid()) throw const SignInNotCommitted(cancelled: true);
        // Signing in leaves an unconfirmed deletion behind (A35).
        await _registry.write(
          snapshot.copyWith(
            transition: transition,
            clearDeletion: !(snapshot.deletion?.confirmed ?? false),
          ),
        );
        // Recheck after the awaited journal write (A33 re-check 1): a
        // cancellation meanwhile rolls the preparation back. No await
        // between this check and the acceptance starting.
        if (!stillValid()) {
          await _rollBackPreparation();
          throw const SignInNotCommitted(cancelled: true);
        }
        provenUncommitted = false;
        try {
          await _session.accept(tokens, commitTag: transition.commitTag!);
        } on Object {
          // Roll back unless this transition's tokens were committed. If
          // the check itself fails, commitment stays unknown (no revoke).
          if (await _session.activeCommitTag() != transition.commitTag) {
            // Known uncommitted from here, before the rollback is awaited
            // (A33 round 4): a failed rollback still ends in revocation.
            provenUncommitted = true;
            await _rollBackPreparation();
          }
          rethrow;
        }
        final committed = transition.at(TransitionPhase.credentialsCommitted);
        await _setTransition(committed);
        await _advance(committed, live: true);
      });
    } on SignInNotCommitted {
      rethrow;
    } on Object {
      if (provenUncommitted) {
        throw const SignInNotCommitted(cancelled: false);
      }
      rethrow;
    }
  }

  /// Signs out (AC-004): keep marks the profile read-only; remove reserves
  /// it and opens a new, distinct, empty guest profile. The profile state is
  /// persisted before the credentials are cleared.
  Future<void> signOut({required bool keep}) => _live(() async {
    if (_deleting != null) throw const DeletionRefused();
    final snapshot = await _registry.read();
    final active = snapshot.active;
    final (guestKey, guestSeq) = snapshot.nextGuest();
    // Journal the exact credential keys first, so recovery can delete them
    // even after the pointer is gone (A33 review 2, item 1).
    final forgetRefs = await _session.storedCredentialRefs();
    final transition = AccountTransition(
      kind: TransitionKind.signOut,
      phase: TransitionPhase.preparing,
      fromKey: active.profileKey,
      target: keep
          ? active.copyWith(readOnly: true)
          : LocalProfile(profileKey: guestKey, kind: ProfileKind.guest),
      discard: keep ? null : active.profileKey,
      forgetRefs: forgetRefs,
    );
    await _registry.write(
      snapshot.copyWith(
        transition: transition,
        guestSeq: keep ? null : guestSeq,
        clearDeletion: !(snapshot.deletion?.confirmed ?? false),
      ),
    );
    await _advance(transition, live: true);
  });

  // ---- account deletion (A35 fix 2) -------------------------------------

  /// Records the deletion of account profile [profileKey] before
  /// `DELETE /v1/me` is sent, and marks the request in flight. Refused
  /// unless [profileKey] is the active, writable, registered profile and no
  /// transition is open. Returns whether an unconfirmed deletion of it was
  /// already recorded (an earlier attempt may have reached the server).
  Future<bool> beginDeletion(String profileKey) => _exclusive(() async {
    final snapshot = await _registry.read();
    final active = snapshot.active;
    if (_deleting != null ||
        snapshot.transitionPending ||
        active.profileKey != profileKey ||
        active.kind != ProfileKind.registered ||
        active.readOnly) {
      throw const DeletionRefused();
    }
    final pending = snapshot.deletion;
    if (pending != null && pending.profileKey != profileKey) {
      throw const DeletionRefused();
    }
    if (pending == null) {
      await _registry.write(
        snapshot.copyWith(deletion: PendingDeletion(profileKey: profileKey)),
      );
    }
    _deleting = profileKey;
    return pending != null;
  });

  /// Ends the in-flight request of [profileKey] without removing anything;
  /// [forget] also drops its unconfirmed record (nothing reached the server,
  /// or the user keeps the account).
  Future<void> endDeletionAttempt(String profileKey, {required bool forget}) =>
      _exclusive(() async {
        if (_deleting == profileKey) _deleting = null;
        if (!forget) return;
        final snapshot = await _registry.read();
        final pending = snapshot.deletion;
        if (pending != null &&
            pending.profileKey == profileKey &&
            !pending.confirmed) {
          await _registry.write(snapshot.copyWith(clearDeletion: true));
        }
      });

  /// The recorded deletion, if any.
  Future<PendingDeletion?> pendingDeletion() async =>
      (await _registry.read()).deletion;

  /// Removes profile [profileKey] from the device (A35): after the server
  /// confirmed the deletion, the user's explicit choice, or a guest's own
  /// data. One write journals the confirmed deletion with an A33 "sign out,
  /// remove" transition bound to that key (validated inside the lock: the
  /// active profile must be it); recovery finishes it after a crash.
  ///
  /// The in-flight marker is released on every outcome (A35 fix round 2):
  /// an unfinished cleanup stays journaled (and holds the session) for
  /// recovery, but no longer blocks sign-in, sign-out or sync.
  ///
  /// [onJournaled] runs once the removal is journaled, before the switch,
  /// with the new guest's key (#241: the one-time note is bound to it).
  /// Its failure doesn't stop the removal.
  Future<void> removeProfile(
    String profileKey, {
    Future<void> Function(String guestKey)? onJournaled,
  }) async {
    try {
      await _live(() async {
        final snapshot = await _registry.read();
        if (snapshot.active.profileKey != profileKey) {
          throw const DeletionRefused();
        }
        await _startRemoval(snapshot, profileKey, onJournaled);
      });
    } finally {
      if (_deleting == profileKey) _deleting = null;
    }
  }

  Future<void> _startRemoval(
    ProfilesSnapshot snapshot,
    String key,
    Future<void> Function(String guestKey)? onJournaled,
  ) async {
    final (guestKey, guestSeq) = snapshot.nextGuest();
    final forgetRefs = await _session.storedCredentialRefs();
    final transition = AccountTransition(
      kind: TransitionKind.signOut,
      phase: TransitionPhase.preparing,
      fromKey: key,
      target: LocalProfile(profileKey: guestKey, kind: ProfileKind.guest),
      discard: key,
      forgetRefs: forgetRefs,
    );
    await _registry.write(
      snapshot.copyWith(
        transition: transition,
        guestSeq: guestSeq,
        deletion: PendingDeletion(profileKey: key, confirmed: true),
      ),
    );
    if (onJournaled != null) {
      try {
        await onJournaled(guestKey);
      } on Object {
        // Only the note is lost.
      }
    }
    await _advance(transition, live: true);
    await _clearFinishedDeletion();
  }

  /// Drops a confirmed deletion whose profile is gone.
  Future<void> _clearFinishedDeletion() async {
    final snapshot = await _registry.read();
    final pending = snapshot.deletion;
    if (pending == null || !pending.confirmed) return;
    if (snapshot.profiles.any((p) => p.profileKey == pending.profileKey)) {
      return;
    }
    await _registry.write(snapshot.copyWith(clearDeletion: true));
  }

  /// Leaves a read-only copy for a guest profile: the existing guest's, or a
  /// new empty one. No credential changes.
  Future<void> continueAsGuest() => _live(() async {
    if (_deleting != null) throw const DeletionRefused();
    final snapshot = await _registry.read();
    final guests = snapshot.profiles.where((p) => p.kind == ProfileKind.guest);
    final (newKey, newSeq) = snapshot.nextGuest();
    final target = guests.isEmpty
        ? LocalProfile(profileKey: newKey, kind: ProfileKind.guest)
        : guests.first;
    final transition = AccountTransition(
      kind: TransitionKind.switchProfile,
      phase: TransitionPhase.preparing,
      fromKey: snapshot.activeKey,
      target: target,
    );
    await _registry.write(
      snapshot.copyWith(
        transition: transition,
        guestSeq: guests.isEmpty ? newSeq : null,
      ),
    );
    await _advance(transition, live: true);
  });

  /// The active profile, for the lazy database resolver. Takes no lock and
  /// runs no recovery (A33 security 6): the applier's queued writes call
  /// this through the write gate, and a transition waits for those writes,
  /// so any lock here could deadlock. Recovery runs from the post-frame
  /// bootstrap ([recover]); until then a pending journal denies writes.
  Future<String> resolveActiveProfile() async =>
      (await _registry.read()).activeKey;

  /// Startup recovery (A33 §6), run by the post-frame bootstrap **before**
  /// the API session starts: resumes or rolls back an interrupted
  /// transition. Session acquisition stays suspended until the journal is
  /// clear, also when recovery fails (retried at the next launch).
  ///
  /// With no journal and nothing reserved (every normal start) it only
  /// reconciles an interrupted secure save and suspends nothing, so the
  /// first writes after launch are never refused.
  Future<void> recover() async {
    final snapshot = await _registry.read();
    if (snapshot.transition == null &&
        snapshot.reserved.isEmpty &&
        !(snapshot.deletion?.confirmed ?? false)) {
      await _session.reconcile();
      return;
    }
    await _live(() async {}, busy: null);
  }

  Future<void> _recover({required bool live}) async {
    // An interrupted secure save would block every session operation:
    // reconcile it first, deterministically (A33 security 5).
    await _session.reconcile();
    final snapshot = await _registry.read();
    final transition = snapshot.transition;
    if (transition == null) {
      if (snapshot.reserved.isNotEmpty) await _cleanup();
      // A35: a confirmed deletion whose removal never journaled (or whose
      // record outlived it) is finished for that exact profile.
      final pending = snapshot.deletion;
      if (pending != null && pending.confirmed) {
        final current = await _registry.read();
        final present = current.profiles.any(
          (p) => p.profileKey == pending.profileKey,
        );
        if (present && current.activeKey == pending.profileKey) {
          // No note here: recovery has no record of what was asked.
          await _startRemoval(current, pending.profileKey, null);
        } else {
          await _clearFinishedDeletion();
        }
      }
      return;
    }
    switch ((transition.kind, transition.phase)) {
      case (TransitionKind.signIn, TransitionPhase.preparing):
        // Exact tag match only: after a guest upgrade the user id (and so
        // the key) is unchanged, so the old guest envelope must not count.
        final tag = transition.commitTag;
        final committed =
            tag != null && await _session.activeCommitTag() == tag;
        if (!committed) return await _setTransition(null);
        final next = transition.at(TransitionPhase.credentialsCommitted);
        await _setTransition(next);
        return await _advance(next, live: live);
      case (
        TransitionKind.signOut || TransitionKind.switchProfile,
        TransitionPhase.preparing,
      ):
        // A35: a removal journaled with a confirmed deletion rolls forward
        // (the server account is gone or the user chose it); an ordinary
        // sign-out that never started rolls back.
        final pending = snapshot.deletion;
        if (transition.kind == TransitionKind.signOut &&
            pending != null &&
            pending.confirmed &&
            pending.profileKey == transition.fromKey) {
          await _advance(transition, live: live);
          return await _clearFinishedDeletion();
        }
        return await _setTransition(null);
      case _:
        await _advance(transition, live: live);
        return await _clearFinishedDeletion();
    }
  }

  Future<void> _advance(
    AccountTransition transition, {
    required bool live,
  }) async {
    var phase = transition.phase;
    final needsSwitch = switch (transition.kind) {
      TransitionKind.signIn => phase == TransitionPhase.credentialsCommitted,
      _ => phase == TransitionPhase.preparing,
    };
    if (needsSwitch) {
      await _switch(transition, live: live);
      phase = TransitionPhase.profileSwitched;
    }
    if (transition.kind == TransitionKind.signOut &&
        phase == TransitionPhase.profileSwitched) {
      await _session.end(transition.forgetRefs);
      phase = TransitionPhase.credentialsCleared;
      await _setTransition(transition.at(phase));
    }
    await _setTransition(transition.at(TransitionPhase.cleanupPending));
    await _cleanup();
    await _setTransition(null);
  }

  Future<void> _switch(
    AccountTransition transition, {
    required bool live,
  }) async {
    final snapshot = await _registry.read();
    final target = transition.target;
    var next = snapshot.put(target, activeKey: target.profileKey);
    if (transition.discard case final discard?) next = next.reserve(discard);
    await _registry.write(
      next.copyWith(transition: transition.at(TransitionPhase.profileSwitched)),
    );
    if (live && snapshot.activeKey != target.profileKey) {
      await _host.activate(target.profileKey);
    }
  }

  Future<void> _cleanup() async {
    final reserved = (await _registry.read()).reserved;
    for (final key in reserved) {
      final snapshot = await _registry.read();
      if (key == snapshot.activeKey) continue;
      await _host.deleteFiles(key);
      // Released only after the deletion succeeded.
      await _registry.write((await _registry.read()).release(key));
    }
  }

  /// Clears an uncommitted sign-in's journal. If that write fails the
  /// journal stays (recovery rolls it back; the session hold remains), and
  /// the caller still reports the sign-in as not committed.
  Future<void> _rollBackPreparation() async {
    try {
      await _setTransition(null);
    } on Object {
      // Kept pending: fail closed, retried by recovery.
    }
  }

  Future<void> _setTransition(AccountTransition? transition) async {
    final snapshot = await _registry.read();
    await _registry.write(
      transition == null
          ? snapshot.copyWith(clearTransition: true)
          : snapshot.copyWith(transition: transition),
    );
  }
}
