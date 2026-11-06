// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_out_check.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Changes on this phone the server doesn't have yet (A65 M1): rows waiting
/// to sync plus changes that couldn't sync, live. Read from the sync store
/// whatever the sync state: an expired session doesn't sync, but its
/// waiting changes are still only on this phone. A failed read gives a
/// `null` count, also after an earlier count (A65 review 3): the
/// destructive step never shows an old or missing number as the truth.

@ProviderFor(unsyncedChanges)
final unsyncedChangesProvider = UnsyncedChangesProvider._();

/// Changes on this phone the server doesn't have yet (A65 M1): rows waiting
/// to sync plus changes that couldn't sync, live. Read from the sync store
/// whatever the sync state: an expired session doesn't sync, but its
/// waiting changes are still only on this phone. A failed read gives a
/// `null` count, also after an earlier count (A65 review 3): the
/// destructive step never shows an old or missing number as the truth.

final class UnsyncedChangesProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnsyncedCount>,
          UnsyncedCount,
          Stream<UnsyncedCount>
        >
    with $FutureModifier<UnsyncedCount>, $StreamProvider<UnsyncedCount> {
  /// Changes on this phone the server doesn't have yet (A65 M1): rows waiting
  /// to sync plus changes that couldn't sync, live. Read from the sync store
  /// whatever the sync state: an expired session doesn't sync, but its
  /// waiting changes are still only on this phone. A failed read gives a
  /// `null` count, also after an earlier count (A65 review 3): the
  /// destructive step never shows an old or missing number as the truth.
  UnsyncedChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unsyncedChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unsyncedChangesHash();

  @$internal
  @override
  $StreamProviderElement<UnsyncedCount> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UnsyncedCount> create(Ref ref) {
    return unsyncedChanges(ref);
  }
}

String _$unsyncedChangesHash() => r'50c7b027c87c8672a578d196c507ab7e32983480';
