import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'android_xml.dart';

void main() {
  test('A44-D7 the Android window background colour equals the dark surface '
      'token', () {
    final colors = readAndroid('main/res/values/colors.xml');
    expect(
      colorResource(colors, 'fb_window_background'),
      FbPalette.of(Brightness.dark).surface.toARGB32(),
    );
    // Dark in day and night: no night-only resources.
    expect(Directory('$androidSrc/main/res/values-night').existsSync(), false);
    final styles = readAndroid('main/res/values/styles.xml');
    expect(
      styleItems(styles, 'NormalTheme')['android:windowBackground'],
      '@color/fb_window_background',
    );
    expect(
      styleItems(styles, 'LaunchTheme')['android:windowBackground'],
      '@drawable/launch_background',
    );
    expect(styles, isNot(contains('Theme.Light')));
  });

  test('A44-D11 every flavor has a launcher plate colour, and the adaptive '
      'icon declares background, foreground and monochrome', () {
    final plates = {
      for (final flavor in ['main', 'dev', 'staging'])
        flavor: colorResource(
          readAndroid('$flavor/res/values/colors.xml'),
          'ic_launcher_background',
        ),
    };
    expect(plates.values, everyElement(isNotNull));
    expect(plates.values.toSet(), hasLength(3), reason: '$plates');
    expect(plates['main'], FbBrandColors.plate.toARGB32());

    final icon = readAndroid('main/res/mipmap-anydpi-v26/ic_launcher.xml');
    String layer(String tag) =>
        xmlElements(icon, tag).single['android:drawable']!;
    expect(layer('background'), '@color/ic_launcher_background');
    expect(layer('foreground'), '@drawable/ic_launcher_foreground');
    expect(layer('monochrome'), '@drawable/ic_launcher_monochrome');
    expect(
      readAndroid('main/AndroidManifest.xml'),
      contains('android:icon="@mipmap/ic_launcher"'),
    );
    // minSdk 26 always uses the adaptive icon: no legacy PNGs to keep in sync.
    final pngs = Directory('$androidSrc/main/res')
        .listSync(recursive: true)
        .where((f) => f.path.endsWith('ic_launcher.png'));
    expect(pngs, isEmpty);
  });
}
