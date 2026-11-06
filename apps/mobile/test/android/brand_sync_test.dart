import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'android_xml.dart';

const _brandDir = '../../packages/fb_design_system/brand';

void _expectCopies({
  required String file,
  required List<Map<String, String>> paths,
  required List<FbMarkShape> source,
  required String pathKey,
  required String fillKey,
  required int Function(FbMarkTone tone) colour,
}) {
  expect(paths, hasLength(source.length), reason: file);
  for (var i = 0; i < source.length; i++) {
    final shape = source[i];
    final p = paths[i];
    final where = '$file, shape $i';
    expect(
      p[pathKey],
      shape.d,
      reason: '$where: the path must be a verbatim copy of brand_geometry',
    );
    expect(argb(p[fillKey]!), colour(shape.tone), reason: where);
    // Filled shapes only: no stroke anywhere.
    expect(
      p.keys.where((k) => k.toLowerCase().contains('stroke')),
      isEmpty,
      reason: where,
    );
  }
}

void main() {
  test('A64 the brand SVGs and the launcher, splash and notification '
      'VectorDrawables are verbatim copies of the brand geometry', () {
    final onLight = {
      FbMarkTone.soft: FbBrandColors.soft.toARGB32(),
      FbMarkTone.mid: FbBrandColors.mid.toARGB32(),
      FbMarkTone.strong: FbBrandColors.plate.toARGB32(),
    };
    for (final (file, source, canvas) in [
      ('momentum-mark.svg', fbMomentumMark, fbMomentumMarkCanvas),
      ('momentum-mini.svg', fbMomentumMini, fbMomentumMiniCanvas),
    ]) {
      final svg = File('$_brandDir/$file').readAsStringSync();
      final c = canvas.toInt();
      expect(svg, contains('viewBox="0 0 $c $c"'), reason: file);
      _expectCopies(
        file: file,
        paths: xmlElements(svg, 'path'),
        source: source,
        pathKey: 'd',
        fillKey: 'fill',
        colour: (tone) => onLight[tone]!,
      );
    }

    final plate = {
      FbMarkTone.soft: FbBrandColors.soft.toARGB32(),
      FbMarkTone.mid: FbBrandColors.mid.toARGB32(),
      FbMarkTone.strong: FbBrandColors.spark.toARGB32(),
    };
    for (final (file, colour, size, viewport) in [
      (
        'ic_launcher_foreground.xml',
        (FbMarkTone p) => plate[p]!,
        '108dp',
        '108',
      ),
      (
        'ic_launcher_monochrome.xml',
        (FbMarkTone _) => 0xFFFFFFFF,
        '108dp',
        '108',
      ),
      ('ic_notification.xml', (FbMarkTone _) => 0xFFFFFFFF, '24dp', '58'),
    ]) {
      final xml = readAndroid('main/res/drawable/$file');
      final vector = xmlElements(xml, 'vector').single;
      expect(vector['android:width'], size, reason: file);
      expect(vector['android:height'], size, reason: file);
      expect(vector['android:viewportWidth'], viewport, reason: file);
      expect(vector['android:viewportHeight'], viewport, reason: file);
      _expectCopies(
        file: file,
        paths: xmlElements(xml, 'path'),
        source: fbMomentumMark,
        pathKey: 'android:pathData',
        fillKey: 'android:fillColor',
        colour: colour,
      );
    }
  });

  test('A64 the notification icon crops the 108 canvas to a square around '
      'the mark, centred, with the whole mark inside', () {
    final xml = readAndroid('main/res/drawable/ic_notification.xml');
    final group = xmlElements(xml, 'group').single;
    final dx = -double.parse(group['android:translateX']!);
    final dy = -double.parse(group['android:translateY']!);
    final vector = xmlElements(xml, 'vector').single;
    final side = double.parse(vector['android:viewportWidth']!);
    final window = Rect.fromLTWH(dx, dy, side, side);
    expect(window.center, const Offset(54, 54));
    expect(window.expandToInclude(fbMomentumMarkFigure), window);
    // The plugin finds the icon by name, so the shrinker must keep it.
    expect(
      readAndroid('main/res/raw/keep.xml'),
      contains('tools:keep="@drawable/ic_notification"'),
    );
    expect(
      File('lib/features/notifications/data/notification_platform.dart')
          .readAsStringSync(),
      contains("AndroidInitializationSettings('ic_notification')"),
    );
  });
}
