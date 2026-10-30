// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_thread_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// a restart starts empty (durable restore is A23's).
///
/// Orchestrates the send path, card adjustments, single-flight confirm,
/// discard and the one undo per confirm. Writes only through the use cases
/// (single writer).

@ProviderFor(BuddyThreadController)
final buddyThreadControllerProvider = BuddyThreadControllerProvider._();

/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// a restart starts empty (durable restore is A23's).
///
/// Orchestrates the send path, card adjustments, single-flight confirm,
/// discard and the one undo per confirm. Writes only through the use cases
/// (single writer).
final class BuddyThreadControllerProvider
    extends $NotifierProvider<BuddyThreadController, BuddyThread> {
  /// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
  /// a restart starts empty (durable restore is A23's).
  ///
  /// Orchestrates the send path, card adjustments, single-flight confirm,
  /// discard and the one undo per confirm. Writes only through the use cases
  /// (single writer).
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
    r'2cf9a3c4d9b9de9dae200ecd062d5e2621acfa9f';

/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// a restart starts empty (durable restore is A23's).
///
/// Orchestrates the send path, card adjustments, single-flight confirm,
/// discard and the one undo per confirm. Writes only through the use cases
/// (single writer).

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
