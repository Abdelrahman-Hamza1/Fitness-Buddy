import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  // rule: A22 chat-language
  test('A22 language tag is normalized from the fixed app list', () {
    expect(
      [for (final l in ChatLanguage.values) l.code],
      ['en', 'ar', 'ar-Latn'],
    );
    for (final language in ChatLanguage.values) {
      expect(ChatLanguage.fromCode(language.code), language);
      expect(
        language.code.length,
        lessThanOrEqualTo(ChatProposalSyncBounds.language),
      );
    }
    expect(ChatLanguage.fromCode(null), isNull);
    expect(ChatLanguage.fromCode('EN'), isNull);
    expect(ChatLanguage.fromCode('english'), isNull);

    const cases = {
      ('english', 'latin'): ChatLanguage.english,
      ('english', 'arabic'): ChatLanguage.english,
      ('english', 'mixed'): ChatLanguage.english,
      ('arabic', 'arabic'): ChatLanguage.arabic,
      ('arabic', 'arabizi'): ChatLanguage.arabizi,
      ('arabic', 'latin'): ChatLanguage.arabizi,
      ('arabic', 'mixed'): null,
      ('arabic', null): null,
      ('mixed', 'latin'): null,
      ('mixed', 'arabic'): null,
      ('French', 'latin'): null,
      ('English', 'latin'): null,
      (null, 'latin'): null,
      (null, null): null,
    };
    for (final MapEntry(key: (language, script), :value) in cases.entries) {
      expect(
        ChatLanguage.normalize(language, script),
        value,
        reason: '$language/$script',
      );
    }

    // Mixed intents tag nothing.
    expect(ChatLanguage.unanimous(const []), isNull);
    expect(
      ChatLanguage.unanimous(const [ChatLanguage.arabic, ChatLanguage.arabic]),
      ChatLanguage.arabic,
    );
    expect(
      ChatLanguage.unanimous(const [ChatLanguage.arabic, ChatLanguage.english]),
      isNull,
    );
    expect(ChatLanguage.unanimous(const [ChatLanguage.english, null]), isNull);
    expect(ChatLanguage.unanimous(const [null, ChatLanguage.english]), isNull);
  });
}
