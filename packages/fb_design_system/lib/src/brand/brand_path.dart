import 'package:fb_design_system/src/brand/brand_geometry.dart';
import 'package:material_ui/material_ui.dart';

const Map<String, int> _arity = {
  'M': 2,
  'L': 2,
  'C': 6,
  'Q': 4,
  'A': 7,
  'Z': 0,
};

final RegExp _number = RegExp(r'^-?(\d+(\.\d+)?|\.\d+)$');

/// Parses [d], the restricted SVG path syntax of `brand_geometry.dart`, into
/// a [Path] (A44 D9). Only absolute `M L C Q A Z`, each command followed by
/// exactly its own numbers, separated by spaces or commas. Throws a
/// [FormatException] on anything else (relative commands, `H V S T`,
/// implicit repeats, malformed numbers, arc flags other than 0/1, an empty
/// path or one that doesn't start with `M`), so a hand-edited string can't
/// silently draw something else.
Path parseFbMarkPath(String d) {
  final tokens = d
      .replaceAllMapped(RegExp('[A-Za-z]'), (m) => ' ${m[0]} ')
      .split(RegExp(r'[\s,]+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty || tokens.first != 'M') {
    throw FormatException('A mark path starts with M', d);
  }
  final path = Path();
  var i = 0;
  while (i < tokens.length) {
    final command = tokens[i++];
    final arity = _arity[command];
    if (arity == null) {
      throw FormatException('Unsupported command "$command"', d);
    }
    if (i + arity > tokens.length) {
      throw FormatException('"$command" needs $arity numbers', d);
    }
    final n = <double>[];
    for (final token in tokens.sublist(i, i + arity)) {
      if (!_number.hasMatch(token)) {
        throw FormatException('Not a number: "$token"', d);
      }
      n.add(double.parse(token));
    }
    i += arity;
    switch (command) {
      case 'M':
        path.moveTo(n[0], n[1]);
      case 'L':
        path.lineTo(n[0], n[1]);
      case 'C':
        path.cubicTo(n[0], n[1], n[2], n[3], n[4], n[5]);
      case 'Q':
        path.quadraticBezierTo(n[0], n[1], n[2], n[3]);
      case 'A':
        if (!{0.0, 1.0}.contains(n[3]) || !{0.0, 1.0}.contains(n[4])) {
          throw FormatException('Arc flags are 0 or 1', d);
        }
        path.arcToPoint(
          Offset(n[5], n[6]),
          radius: Radius.elliptical(n[0], n[1]),
          rotation: n[2],
          largeArc: n[3] == 1,
          clockwise: n[4] == 1,
        );
      case 'Z':
        path.close();
    }
  }
  return path;
}

final Map<String, Path> _cache = {};

/// The parsed path of [shape], parsed once. Don't mutate it.
Path fbMarkPath(FbMarkShape shape) =>
    _cache.putIfAbsent(shape.d, () => parseFbMarkPath(shape.d));
