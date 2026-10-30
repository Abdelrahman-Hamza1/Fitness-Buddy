import 'dart:convert';

import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'guest_prompt_store.g.dart';

/// The guest prompt's display state (AC-002): instants only, no content.
final class GuestPromptState {
  /// See the fields.
  const new({this.firstUseAt, this.lastShownAt});

  /// When this install was first used, or `null` before the first check.
  final DateTime? firstUseAt;

  /// When the prompt last showed (shown or dismissed), or `null`.
  final DateTime? lastShownAt;
}

/// Where [GuestPromptState] lives: `PreferenceKeys.guestPrompt`, as JSON
/// `{"firstUseAt": "<UTC ISO>", "lastShownAt": "<UTC ISO>"}`.
final class GuestPromptStore {
  /// Over the app's preferences.
  const new(this._preferences);

  final SharedPreferencesAsync _preferences;

  /// The stored state; empty when absent or unreadable.
  Future<GuestPromptState> read() async {
    final text = await _preferences.getString(PreferenceKeys.guestPrompt);
    if (text == null) return const GuestPromptState();
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, Object?>) return const GuestPromptState();
      DateTime? at(String key) => switch (json[key]) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        _ => null,
      };
      return GuestPromptState(
        firstUseAt: at('firstUseAt'),
        lastShownAt: at('lastShownAt'),
      );
    } on FormatException {
      return const GuestPromptState();
    }
  }

  /// Stores [state].
  Future<void> write(GuestPromptState state) => _preferences.setString(
    PreferenceKeys.guestPrompt,
    jsonEncode({
      'firstUseAt': ?state.firstUseAt?.toUtc().toIso8601String(),
      'lastShownAt': ?state.lastShownAt?.toUtc().toIso8601String(),
    }),
  );
}

/// The app's [GuestPromptStore].
@Riverpod(keepAlive: true)
GuestPromptStore guestPromptStore(Ref ref) =>
    GuestPromptStore(ref.watch(sharedPreferencesProvider));
