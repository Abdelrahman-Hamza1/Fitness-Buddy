import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SF-040 the licence registry lists Inter, Noto Sans Arabic and Nunito '
      'with their OFL text', () {
    expect([
      for (final (name, _) in fbFontLicenses) name,
    ], unorderedEquals(['Inter', 'Noto Sans Arabic', 'Nunito']));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final (_, file) in fbFontLicenses) {
      final text = File('assets/fonts/$file').readAsStringSync();
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'), reason: file);
      // Declared as an asset, so the licence page can load it.
      expect(pubspec, contains('- assets/fonts/$file'), reason: file);
    }
  });
}
