import 'dart:io';

/// A tiny reader for the hand-written Android and SVG resources the A44
/// tests check: the attributes of every `<tag …>` element, in order. Enough
/// for these flat files; not a general XML parser.
List<Map<String, String>> xmlElements(String xml, String tag) => [
  for (final match in RegExp('<$tag\\b([^>]*?)/?>').allMatches(xml))
    {
      for (final a in RegExp(r'([\w:-]+)="([^"]*)"').allMatches(match[1]!))
        a[1]!: a[2]!,
    },
];

/// The `<item name="…">value</item>` entries of the style [name] in [xml].
Map<String, String> styleItems(String xml, String name) {
  final style = RegExp(
    '<style name="$name"([^>]*)>(.*?)</style>',
    dotAll: true,
  ).firstMatch(xml);
  if (style == null) return const {};
  return {
    for (final item in RegExp(
      '<item name="([^"]+)">([^<]*)</item>',
    ).allMatches(style[2]!))
      item[1]!: item[2]!.trim(),
  };
}

/// The value of `<color name="[name]">` in [xml], as ARGB.
int? colorResource(String xml, String name) {
  final m = RegExp('<color name="$name">([^<]+)</color>').firstMatch(xml);
  return m == null ? null : argb(m[1]!.trim());
}

/// `#RRGGBB` (opaque) or `#AARRGGBB` as an ARGB int.
int argb(String hex) {
  final h = hex.replaceFirst('#', '');
  return switch (h.length) {
    6 => 0xFF000000 | int.parse(h, radix: 16),
    8 => int.parse(h, radix: 16),
    _ => throw FormatException('Not a colour', hex),
  };
}

/// The Android app's `src/` folder (tests run in apps/mobile).
const String androidSrc = 'android/app/src';

/// Reads [path] under the Android `src/` folder.
String readAndroid(String path) => File('$androidSrc/$path').readAsStringSync();
