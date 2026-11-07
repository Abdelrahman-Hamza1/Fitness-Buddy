import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'android_xml.dart';

void main() {
  test("A71 D2 the widgets' Android colours are the Ink & Sky palette, "
      'light in values/ and dark in values-night/', () {
    for (final (dir, brightness) in [
      ('values', Brightness.light),
      ('values-night', Brightness.dark),
    ]) {
      final p = FbPalette.of(brightness);
      final xml = readAndroid('main/res/$dir/widget_colors.xml');
      final expected = <String, Color>{
        'widget_surface': p.surfaceContainer,
        'widget_on_surface': p.onSurface,
        'widget_on_surface_variant': p.onSurfaceVariant,
        'widget_track': p.surfaceContainerHigh,
        'widget_brand': p.brand,
        'widget_on_brand': p.onBrand,
        'widget_tonal': p.brandContainer,
        'widget_on_tonal': p.onBrandContainer,
        'widget_protein': p.protein,
        'widget_carbs': p.carbs,
        'widget_fat': p.fat,
        'widget_fiber': p.fiber,
        'widget_over': p.overTarget,
        'widget_mark_soft': p.markSoft,
        'widget_mark_mid': p.markMid,
        'widget_mark_strong': p.markStrong,
      };
      expect(
        xmlElements(xml, 'color').length,
        expected.length,
        reason: '$dir: no colour without a palette source',
      );
      for (final MapEntry(:key, :value) in expected.entries) {
        expect(colorResource(xml, key), value.toARGB32(), reason: '$dir/$key');
      }
    }
  });

  test('A71 the widget mark is a verbatim copy of the brand geometry, in the '
      'mark tones', () {
    final xml = readAndroid('main/res/drawable/widget_mark.xml');
    final paths = xmlElements(xml, 'path');
    expect(paths, hasLength(fbMomentumMark.length));
    const tones = {
      FbMarkTone.soft: '@color/widget_mark_soft',
      FbMarkTone.mid: '@color/widget_mark_mid',
      FbMarkTone.strong: '@color/widget_mark_strong',
    };
    for (final (i, shape) in fbMomentumMark.indexed) {
      expect(paths[i]['android:pathData'], shape.d, reason: 'shape $i');
      expect(paths[i]['android:fillColor'], tones[shape.tone], reason: '$i');
    }
  });
}
