import 'dart:async';

import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_account_controller.g.dart';

/// Where account deletion is (A35 D19).
enum DeletePhase {
  /// Nothing started (or a retry is possible).
  ready,

  /// Deleting.
  deleting,

  /// No connection: nothing was deleted.
  offline,

  /// The request may not have reached the server, or the server failed.
  uncertain,

  /// The session ended after an unconfirmed attempt: probably deleted.
  sessionEnded,

  /// The session had ended before any attempt: sign in again.
  needsSignIn,

  /// The server account is gone (or a guest), but wiping the phone failed.
  wipeFailed,
}

/// The deletion screen's state (A35, AC-031). The work itself is the
/// profile-bound `AccountService.deleteAccount` (fix 2): it keeps going if
/// the screen goes away, and a successful wipe switches to a new empty
/// guest profile, which rebuilds the app (A33), so there is no "done"
/// phase. The profile is the one active when the user confirmed, in this
/// screen's profile generation.
@riverpod
class DeleteAccountController extends _$DeleteAccountController {
  late int _generation;

  @override
  DeletePhase build() {
    _generation = ref.read(profileGenerationProvider);
    unawaited(_resume());
    return DeletePhase.ready;
  }

  /// An unconfirmed deletion recorded earlier (even before a restart)
  /// shows as "couldn't confirm".
  Future<void> _resume() async {
    final service = ref.read(accountServiceProvider);
    final pending = await service.pendingDeletion();
    final active = await _activeKey();
    if (!ref.mounted || state != DeletePhase.ready) return;
    if (pending != null && !pending.confirmed && pending.profileKey == active) {
      state = DeletePhase.uncertain;
    }
  }

  Future<String?> _activeKey() async {
    final key = (await ref.read(profileRegistryProvider).read()).activeKey;
    if (!ref.mounted || ref.read(profileGenerationProvider) != _generation) {
      return null;
    }
    return key;
  }

  /// Deletes the account ([guest]: only this phone's data).
  Future<void> delete({required bool guest}) async {
    if (state == DeletePhase.deleting) return;
    state = DeletePhase.deleting;
    final service = ref.read(accountServiceProvider);
    final key = await _activeKey();
    if (key == null) return;
    try {
      if (guest) {
        await service.removeLocalData(key);
      } else {
        await service.deleteAccount(key);
      }
    } on AccountDeletionFailure catch (failure) {
      _set(switch (failure.kind) {
        AccountDeletionKind.offline => DeletePhase.offline,
        AccountDeletionKind.uncertain => DeletePhase.uncertain,
        AccountDeletionKind.sessionEnded => DeletePhase.sessionEnded,
        AccountDeletionKind.needsSignIn => DeletePhase.needsSignIn,
        AccountDeletionKind.localRemovalFailed => DeletePhase.wipeFailed,
      });
    } on DeletionRefused {
      _set(DeletePhase.ready);
    } on Object {
      _set(guest ? DeletePhase.wipeFailed : DeletePhase.uncertain);
    }
  }

  /// Wipes this phone after an unconfirmed deletion (the user's choice,
  /// A35 D19) or a failed wipe.
  Future<void> removeLocal() async {
    if (state == DeletePhase.deleting) return;
    state = DeletePhase.deleting;
    final service = ref.read(accountServiceProvider);
    final key = await _activeKey();
    if (key == null) return;
    try {
      await service.removeLocalData(key);
    } on Object {
      _set(DeletePhase.wipeFailed);
    }
  }

  /// Keeps the account (before signing in again): drops the unconfirmed
  /// deletion record.
  Future<void> keepAccount() async {
    final service = ref.read(accountServiceProvider);
    final key = await _activeKey();
    if (key == null) return;
    await service.cancelDeletion(key);
    _set(DeletePhase.ready);
  }

  void _set(DeletePhase phase) {
    if (ref.mounted) state = phase;
  }
}
