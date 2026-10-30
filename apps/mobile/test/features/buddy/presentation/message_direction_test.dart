import 'package:fb_mobile/features/buddy/presentation/message_direction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // rule: A22b bubble-direction
  test('A22 Arabic bubbles are laid out right to left', () {
    expect(messageDirection('بيضتين وخبز'), TextDirection.rtl);
    expect(messageDirection('2 بيضة'), TextDirection.rtl);
    expect(messageDirection('2 eggs and toast'), TextDirection.ltr);
    // Arabizi is Latin script.
    expect(messageDirection('3 bedat w 5obz'), TextDirection.ltr);
    expect(messageDirection('eggs مع خبز'), TextDirection.ltr);
    expect(messageDirection('123 😀'), isNull);
    // Arabic-Indic digits are neutral: the first strong letter decides.
    expect(messageDirection('١٢ eggs'), TextDirection.ltr);
    expect(messageDirection('١٢ بيضة'), TextDirection.rtl);
    expect(messageDirection('١٢، ٣'), isNull);
    // Arabic punctuation and harakat are neutral too.
    expect(messageDirection('؟hello'), TextDirection.ltr);
    expect(messageDirection('؛ ok'), TextDirection.ltr);
    expect(messageDirection('\u064Begg'), TextDirection.ltr);
    expect(messageDirection('؟ كم سعرة'), TextDirection.rtl);
    expect(messageDirection('שלום'), TextDirection.rtl);
  });
}
