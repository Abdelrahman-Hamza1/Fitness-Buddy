// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_thread_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// pending cards and waiting messages come back after a restart (A23, A66).
///
/// Orchestrates agent turns (A66: one at a time, the runner, the message
/// queue), card adjustments, single-flight confirm and Apply all, discard
/// and the one undo per confirm. Writes only through the use cases (single
/// writer); a `proposal` event only ever becomes a pending card.

@ProviderFor(BuddyThreadController)
final buddyThreadControllerProvider = BuddyThreadControllerProvider._();

/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// pending cards and waiting messages come back after a restart (A23, A66).
///
/// Orchestrates agent turns (A66: one at a time, the runner, the message
/// queue), card adjustments, single-flight confirm and Apply all, discard
/// and the one undo per confirm. Writes only through the use cases (single
/// writer); a `proposal` event only ever becomes a pending card.
final class BuddyThreadControllerProvider
    extends $NotifierProvider<BuddyThreadController, BuddyThread> {
  /// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
  /// pending cards and waiting messages come back after a restart (A23, A66).
  ///
  /// Orchestrates agent turns (A66: one at a time, the runner, the message
  /// queue), card adjustments, single-flight confirm and Apply all, discard
  /// and the one undo per confirm. Writes only through the use cases (single
  /// writer); a `proposal` event only ever becomes a pending card.
  BuddyThreadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyThreadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyThreadControllerHash();

  @$internal
  @override
  BuddyThreadController create() => BuddyThreadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyThread value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyThread>(value),
    );
  }
}

String _$buddyThreadControllerHash() =>
    r'771960c8cb67f2f650e894ae6c3cc8f7579635ea';

/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// pending cards and waiting messages come back after a restart (A23, A66).
///
/// Orchestrates agent turns (A66: one at a time, the runner, the message
/// queue), card adjustments, single-flight confirm and Apply all, discard
/// and the one undo per confirm. Writes only through the use cases (single
/// writer); a `proposal` event only ever becomes a pending card.

abstract class _$BuddyThreadController extends $Notifier<BuddyThread> {
  BuddyThread build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BuddyThread, BuddyThread>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BuddyThread, BuddyThread>,
              BuddyThread,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
