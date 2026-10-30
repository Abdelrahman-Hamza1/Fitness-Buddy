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

  test('WO-007 the licence registry carries the muscle map outline MIT '
      'notice', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(fbArtworkLicenses, isNotEmpty);
    for (final (_, file) in fbArtworkLicenses) {
      final text = File('assets/licenses/$file').readAsStringSync();
      expect(text, contains('MIT License'), reason: file);
      expect(text, contains('Copyright (c) 2022 ELABBASSI Hicham'));
      expect(pubspec, contains('- assets/licenses/$file'), reason: file);
    }
  });
}
