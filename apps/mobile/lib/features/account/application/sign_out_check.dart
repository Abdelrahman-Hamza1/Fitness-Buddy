import 'dart:async';

import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/sync/sync_providers.dart';
import 'package:fb_mobile/core/sync/sync_status.dart' show LocalSyncCounts;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_out_check.g.dart';

/// The removal step's count (A65 M1): the profile it was read for and its
/// changes the server doesn't have yet; its count is `null` when the read
/// failed.
typedef UnsyncedCount = ({String profileKey, int? count});

/// What the user confirmed on "Remove from this phone" (A65 review 1): the
/// profile and the unsynced count shown (`null`: the count couldn't be
/// read and the user removed anyway).
final class RemoveConfirmation {
  /// The confirmed profile and count.
  const new({required this.profileKey, required this.unsynced});

  /// The profile shown on the step.
  final String profileKey;

  /// The count shown, or `null` when it was unreadable.
  final int? unsynced;

  /// Whether the final count [now] (read with writes held; `null` when
  /// unreadable) is still covered by what was confirmed: never more
  /// changes than shown. After an unreadable count the user accepted an
  /// unknown loss, so a still unreadable or zero count passes; a readable
  /// non-zero one is asked about again with its number.
  bool covers(int? now) {
    final shown = unsynced;
    if (shown == null) return now == null || now == 0;
    return now != null && now <= shown;
  }
}

/// Changes on this phone the server doesn't have yet (A65 M1): rows waiting
/// to sync plus changes that couldn't sync, live. Read from the sync store
/// whatever the sync state: an expired session doesn't sync, but its
/// waiting changes are still only on this phone. A failed read gives a
/// `null` count, also after an earlier count (A65 review 3): the
/// destructive step never shows an old or missing number as the truth.
@riverpod
Stream<UnsyncedCount> unsyncedChanges(Ref ref) async* {
  final store = ref.watch(syncStoreProvider);
  final registry = ref.watch(profileRegistryProvider);
  final profileKey = (await registry.read()).activeKey;
  yield* store
      .watchCounts(reportErrors: true)
      .transform(
        StreamTransformer<LocalSyncCounts, UnsyncedCount>.fromHandlers(
          handleData: (counts, sink) => sink.add((
            profileKey: profileKey,
            count: counts.pendingRows + counts.parked,
          )),
          handleError: (_, _, sink) =>
              sink.add((profileKey: profileKey, count: null)),
        ),
      );
}
