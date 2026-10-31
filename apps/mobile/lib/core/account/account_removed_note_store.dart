import 'dart:convert';

import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the last deletion removed (A35 D19, #241): the note the new guest's
/// Today shows once.
enum AccountRemovedKind {
  /// The server account and this phone's copy (`DELETE /v1/me` returned
  /// 204).
  account,

  /// Only this phone's data (a guest's own data, or the user's choice after
  /// an unconfirmed deletion).
  local,
}

/// Where the one-time "account deleted" note waits across the profile
/// switch a deletion ends with (`PreferenceKeys.accountRemovedNote`): the
/// kind and the local key of the guest profile the removal switches to.
/// Device state, never synced or sent.
abstract interface class AccountRemovedNoteStore {
  /// Records [kind] for the guest profile [guestKey] (written once the
  /// removal is journaled).
  Future<void> mark(AccountRemovedKind kind, {required String guestKey});

  /// The recorded kind when [activeKey] is the guest it was recorded for,
  /// cleared as it is read (shown once); null otherwise. A note for another
  /// profile is dropped unless [removalPending] (the removal may still
  /// switch to it).
  Future<AccountRemovedKind?> take(
    String activeKey, {
    required bool removalPending,
  });
}

/// [AccountRemovedNoteStore] over the app's preferences, as JSON
/// `{"kind": "<name>", "guest": "<profile key>"}`; an unreadable value
/// reads as none.
final class PreferencesAccountRemovedNoteStore
    implements AccountRemovedNoteStore {
  /// Over [_preferences].
  const new(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<void> mark(AccountRemovedKind kind, {required String guestKey}) =>
      _preferences.setString(
        PreferenceKeys.accountRemovedNote,
        jsonEncode({'kind': kind.name, 'guest': guestKey}),
      );

  @override
  Future<AccountRemovedKind?> take(
    String activeKey, {
    required bool removalPending,
  }) async {
    final text = await _preferences.getString(
      PreferenceKeys.accountRemovedNote,
    );
    if (text == null) return null;
    AccountRemovedKind? kind;
    String? guest;
    try {
      final json = jsonDecode(text);
      if (json is Map<String, Object?>) {
        kind = AccountRemovedKind.values.asNameMap()[json['kind']];
        guest = switch (json['guest']) {
          final String key => key,
          _ => null,
        };
      }
    } on FormatException {
      // Unreadable: dropped below.
    }
    final matches = kind != null && guest == activeKey;
    if (!matches && removalPending && kind != null) return null;
    await _preferences.remove(PreferenceKeys.accountRemovedNote);
    return matches ? kind : null;
  }
}
