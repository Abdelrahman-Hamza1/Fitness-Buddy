import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'android_xml.dart';

void main() {
  test('TD-107 the Android window, splash and window background are the '
      'light surface, with light parents, a light status bar, and the plate '
      'under the mark before Android 12', () {
    final colors = readAndroid('main/res/values/colors.xml');
    expect(
      colorResource(colors, 'fb_window_background'),
      FbPalette.of(Brightness.light).surface.toARGB32(),
    );
    // Light in day and night: no night-only resources.
    expect(Directory('$androidSrc/main/res/values-night').existsSync(), false);

    final styles = readAndroid('main/res/values/styles.xml');
    final v31 = readAndroid('main/res/values-v31/styles.xml');
    final themes = {
      'NormalTheme': styleItems(styles, 'NormalTheme'),
      'LaunchTheme': styleItems(styles, 'LaunchTheme'),
      'LaunchTheme v31': styleItems(v31, 'LaunchTheme'),
    };
    for (final MapEntry(key: name, value: items) in themes.entries) {
      expect(
        items['android:statusBarColor'],
        '@color/fb_window_background',
        reason: name,
      );
      expect(items['android:windowLightStatusBar'], 'true', reason: name);
      expect(
        items['android:windowDrawsSystemBarBackgrounds'],
        'true',
        reason: name,
      );
    }
    for (final xml in [styles, v31]) {
      final parents = RegExp(r'<style name="\w+" parent="([^"]+)"')
          .allMatches(xml)
          .map((m) => m[1]);
      expect(parents, isNotEmpty);
      expect(parents, everyElement('@android:style/Theme.Light.NoTitleBar'));
    }
    expect(
      themes['NormalTheme']!['android:windowBackground'],
      '@color/fb_window_background',
    );
    expect(
      themes['LaunchTheme']!['android:windowBackground'],
      '@drawable/launch_background',
    );
    expect(
      themes['LaunchTheme v31']!['android:windowSplashScreenBackground'],
      '@color/fb_window_background',
    );

    // Before Android 12 the reversed mark sits on a plate, not on cream.
    final launch = readAndroid('main/res/drawable/launch_background.xml');
    expect(launch, contains('android:shape="oval"'));
    expect(
      xmlElements(launch, 'solid').single['android:color'],
      '@color/ic_launcher_background',
    );
    expect(
      launch.indexOf('android:shape="oval"'),
      lessThan(launch.indexOf('@drawable/ic_launcher_foreground')),
      reason: 'the plate is drawn under the mark',
    );
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
