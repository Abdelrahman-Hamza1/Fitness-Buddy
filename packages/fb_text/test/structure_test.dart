import 'dart:io';

import 'package:test/test.dart';

/// Exports in the barrel, e.g. `export 'src/normalize/normalizer.dart';`.
final _export = RegExp(
  r'''^export\s+'(src/[^']+\.dart)'\s*;''',
  multiLine: true,
);

void main() {
  group('structure:', () {
    // The coverage gate (S08 D15) only sees files a test loads. The tests
    // import the barrel, so a file the barrel misses would silently drop out
    // of the percentage.
    test('barrel exports every src file', () {
      final barrel = File('lib/fb_text.dart').readAsStringSync();
      final exported = {
        for (final match in _export.allMatches(barrel)) match[1]!,
      };
      final sources = {
        for (final file in Directory('lib/src').listSync(recursive: true))
          if (file is File && file.path.endsWith('.dart'))
            file.path
                .substring('lib/'.length)
                .replaceAll(Platform.pathSeparator, '/'),
      };
      expect(sources, isNotEmpty);
      expect(
        sources.difference(exported),
        isEmpty,
        reason: 'export these from lib/fb_text.dart',
      );
      expect(
        exported.difference(sources),
        isEmpty,
        reason: 'the barrel exports files that do not exist',
      );
    });
  });
}
