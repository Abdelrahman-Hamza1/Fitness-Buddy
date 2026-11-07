import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/features/buddy/data/speech_recognizer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'voice_language_store.g.dart';

/// The last language spoken to Buddy (A70 D4): device display state, never
/// synced or sent.
class VoiceLanguageStore {
  /// Over [_prefs].
  const new(this._prefs);

  final SharedPreferencesAsync _prefs;

  /// The last choice; English when none (or the store can't be read).
  Future<VoiceLanguage> read() async {
    try {
      final code = await _prefs.getString(PreferenceKeys.voiceLanguage);
      return VoiceLanguage.of(code) ?? VoiceLanguage.english;
      // A store that can't be read only loses the preference.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return VoiceLanguage.english;
    }
  }

  /// Keeps [language] for next time.
  Future<void> write(VoiceLanguage language) async {
    try {
      await _prefs.setString(PreferenceKeys.voiceLanguage, language.code);
      // A platform error changes nothing for the user; never logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }
}

/// The voice-language preference.
@Riverpod(keepAlive: true)
VoiceLanguageStore voiceLanguageStore(Ref ref) =>
    VoiceLanguageStore(ref.watch(sharedPreferencesProvider));
