import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_removed_note_store.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/core/account/account_removed_note_store.dart'
    show AccountRemovedKind;

part 'account_removed_note.g.dart';

/// The one-time note on the new guest's Today after a deletion (A35 D19,
/// #241): what was removed, or null. Read again on every profile switch
/// (a deletion ends with one); it shows only on the guest profile the
/// journaled removal switched to, is cleared as it is read, and so shows
/// in this run until dismissed and never again.
@Riverpod(keepAlive: true)
class AccountRemovedNote extends _$AccountRemovedNote {
  @override
  Future<AccountRemovedKind?> build() async {
    ref.watch(profileGenerationProvider);
    try {
      final snapshot = await ref.read(profileRegistryProvider).read();
      return await ref
          .read(accountRemovedNoteStoreProvider)
          .take(
            snapshot.activeKey,
            removalPending: snapshot.transition != null,
          );
    } on Object {
      // A preference read failing only hides the note.
      return null;
    }
  }

  /// "OK": hides the note.
  void dismiss() => state = const AsyncData(null);
}
