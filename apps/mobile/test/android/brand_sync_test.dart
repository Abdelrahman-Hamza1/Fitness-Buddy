import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import 'android_xml.dart';

const _brandDir = '../../packages/fb_design_system/brand';

void _expectCopies({
  required String file,
  required List<Map<String, String>> paths,
  required List<FbMarkShape> source,
  required String pathKey,
  required String fillKey,
  required String strokeKey,
  required String widthKey,
  required int Function(FbMarkPart part) colour,
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
    if (shape.strokeWidth case final width?) {
      expect(double.parse(p[widthKey]!), width, reason: where);
      expect(argb(p[strokeKey]!), colour(shape.part), reason: where);
      expect(p[fillKey], anyOf(isNull, 'none'), reason: where);
      expect(
        p['stroke-linecap'] ?? p['android:strokeLineCap'],
        'round',
        reason: where,
      );
    } else {
      expect(argb(p[fillKey]!), colour(shape.part), reason: where);
      expect(p[strokeKey], isNull, reason: where);
    }
  }
}

void main() {
  test('A44-D9 the brand SVGs and launcher VectorDrawables are verbatim '
      'copies of the brand geometry', () {
    final onLight = {
      FbMarkPart.a: FbBrandColors.plate.toARGB32(),
      FbMarkPart.b: FbBrandColors.mint.toARGB32(),
    };
    for (final (file, source, canvas) in [
      ('embrace-mark.svg', fbEmbraceMark, fbEmbraceMarkCanvas),
      ('embrace-mini.svg', fbEmbraceMini, fbEmbraceMiniCanvas),
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
        strokeKey: 'stroke',
        widthKey: 'stroke-width',
        colour: (part) => onLight[part]!,
      );
    }

    final reversed = {
      FbMarkPart.a: FbBrandColors.reversedA.toARGB32(),
      FbMarkPart.b: FbBrandColors.mint.toARGB32(),
    };
    for (final (file, colour) in [
      ('ic_launcher_foreground.xml', (FbMarkPart p) => reversed[p]!),
      ('ic_launcher_monochrome.xml', (FbMarkPart _) => 0xFFFFFFFF),
    ]) {
      final xml = readAndroid('main/res/drawable/$file');
      final vector = xmlElements(xml, 'vector').single;
      expect(vector['android:width'], '108dp', reason: file);
      expect(vector['android:height'], '108dp', reason: file);
      expect(vector['android:viewportWidth'], '108', reason: file);
      expect(vector['android:viewportHeight'], '108', reason: file);
      _expectCopies(
        file: file,
        paths: xmlElements(xml, 'path'),
        source: fbEmbraceMark,
        pathKey: 'android:pathData',
        fillKey: 'android:fillColor',
        strokeKey: 'android:strokeColor',
        widthKey: 'android:strokeWidth',
        colour: colour,
      );
    }
  });
}
