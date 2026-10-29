import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'android_xml.dart';

const _darkParent = 'parent="@android:style/Theme.Black.NoTitleBar"';

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

  test('A44-D12 the v31 LaunchTheme sets the splash background, animated icon '
      'and icon background, and a solid window background', () {
    final styles = readAndroid('main/res/values-v31/styles.xml');
    expect(styles, contains('<style name="LaunchTheme" $_darkParent>'));
    expect(styleItems(styles, 'LaunchTheme'), {
      'android:windowSplashScreenBackground': '@color/fb_window_background',
      'android:windowSplashScreenAnimatedIcon':
          '@drawable/ic_launcher_foreground',
      'android:windowSplashScreenIconBackgroundColor':
          '@color/ic_launcher_background',
      'android:windowBackground': '@color/fb_window_background',
    });
    // Pre-12: the dark window colour and the mark, in one layer-list.
    final launch = readAndroid('main/res/drawable/launch_background.xml');
    final items = xmlElements(launch, 'item');
    expect(items.first['android:drawable'], '@color/fb_window_background');
    expect(items.last['android:drawable'], '@drawable/ic_launcher_foreground');
    expect(
      Directory('$androidSrc/main/res/drawable-v21').existsSync(),
      isFalse,
    );
  });
}
