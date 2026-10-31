// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The deletion screen's state (A35, AC-031). The work itself is the
/// profile-bound `AccountService.deleteAccount` (fix 2): it keeps going if
/// the screen goes away, and a successful wipe switches to a new empty
/// guest profile, which rebuilds the app (A33), so there is no "done"
/// phase. The profile is the one active when the user confirmed, in this
/// screen's profile generation.

@ProviderFor(DeleteAccountController)
final deleteAccountControllerProvider = DeleteAccountControllerProvider._();

/// The deletion screen's state (A35, AC-031). The work itself is the
/// profile-bound `AccountService.deleteAccount` (fix 2): it keeps going if
/// the screen goes away, and a successful wipe switches to a new empty
/// guest profile, which rebuilds the app (A33), so there is no "done"
/// phase. The profile is the one active when the user confirmed, in this
/// screen's profile generation.
final class DeleteAccountControllerProvider
    extends $NotifierProvider<DeleteAccountController, DeletePhase> {
  /// The deletion screen's state (A35, AC-031). The work itself is the
  /// profile-bound `AccountService.deleteAccount` (fix 2): it keeps going if
  /// the screen goes away, and a successful wipe switches to a new empty
  /// guest profile, which rebuilds the app (A33), so there is no "done"
  /// phase. The profile is the one active when the user confirmed, in this
  /// screen's profile generation.
  DeleteAccountControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountControllerHash();

  @$internal
  @override
  DeleteAccountController create() => DeleteAccountController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletePhase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletePhase>(value),
    );
  }
}

String _$deleteAccountControllerHash() =>
    r'f34dde9397276f0cc06b744de740dcc84f73f800';

/// The deletion screen's state (A35, AC-031). The work itself is the
/// profile-bound `AccountService.deleteAccount` (fix 2): it keeps going if
/// the screen goes away, and a successful wipe switches to a new empty
/// guest profile, which rebuilds the app (A33), so there is no "done"
/// phase. The profile is the one active when the user confirmed, in this
/// screen's profile generation.

abstract class _$DeleteAccountController extends $Notifier<DeletePhase> {
  DeletePhase build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DeletePhase, DeletePhase>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeletePhase, DeletePhase>,
              DeletePhase,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
