/// The language a chat message was written in, as the short tag stored in
/// `chatMessage.language` (B18 handoff, A22 D8).
///
/// A fixed app list: the raw model values (`intent.language`,
/// `intent.script`) are never stored. Mixed or unknown input has no tag
/// (`null`).
enum ChatLanguage {
  /// English.
  english('en'),

  /// Arabic in Arabic script.
  arabic('ar'),

  /// Arabic in Latin letters (Arabizi).
  arabizi('ar-Latn');

  new(this.code);

  /// The stored tag.
  final String code;

  /// The language whose [code] is exactly [code], or `null` for unknown
  /// tags and `null`.
  static ChatLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// The tag of one interpreted intent from B08's `language` (`english`,
  /// `arabic`, `mixed`) and `script` (`latin`, `arabic`, `arabizi`,
  /// `mixed`): English in any script is [english]; Arabic in Arabic script
  /// is [arabic]; Arabic in Arabizi or Latin letters is [arabizi]; anything
  /// else (mixed, unknown, missing) is `null`.
  static ChatLanguage? normalize(String? language, String? script) =>
      switch ((language, script)) {
        ('english', _) => english,
        ('arabic', 'arabic') => arabic,
        ('arabic', 'arabizi' || 'latin') => arabizi,
        _ => null,
      };

  /// The one language all [languages] agree on, else `null` (also for none
  /// or any `null`): a reply's intents tag the message only when unanimous.
  static ChatLanguage? unanimous(Iterable<ChatLanguage?> languages) {
    ChatLanguage? agreed;
    for (final language in languages) {
      if (language == null || (agreed != null && agreed != language)) {
        return null;
      }
      agreed = language;
    }
    return agreed;
  }
}
