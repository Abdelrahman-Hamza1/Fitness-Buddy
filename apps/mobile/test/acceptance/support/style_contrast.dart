import 'dart:ui' show Tristate;

import 'package:fb_design_system/fb_design_system.dart' show wcagContrast;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// One piece of on-screen text below the WCAG AA minimum.
typedef ContrastFinding = ({String text, double ratio, double needed});

/// One layer between a text and the window: a fill painted behind it, or an
/// opacity applied to everything inside it.
sealed class _Layer;

final class _Fill extends _Layer {
  new(this.color);
  final Color color;
}

final class _Fade extends _Layer {
  new(this.opacity);
  final double opacity;
}

/// Checks every visible text on screen against WCAG AA (UX-071): the
/// paragraphs (`RichText`) and the typed text of fields (`EditableText`).
///
/// For each text it collects the layers above it up to the window: the
/// fills its ancestors paint (a physical model, as every `Material` builds;
/// a coloured or decorated box; an `InputDecorator`'s fill; the scaffold)
/// and the opacities they sit in. It then paints two pixels through those
/// layers the way the engine composites them, one with the glyph's colour
/// on top and one without, and compares the two. So text inside a faded
/// panel is judged against what the panel really shows over what lies
/// behind it, not against the panel's own colour. 4.5:1, or 3:1 for large
/// text (24 px, or 18.66 px bold). Text of a disabled control is exempt, as
/// WCAG 1.4.3 allows, and fully faded text (a field's hint behind its
/// label) isn't shown.
///
/// Unlike Flutter's `textContrastGuideline`, which samples the screenshot's
/// pixels, this reads the styles, so anti-aliased single glyphs and large
/// merged semantics nodes give no false results. Text painted by a custom
/// painter (chart labels) isn't a widget; the token pairs cover it.
List<ContrastFinding> styleContrastFindings(WidgetTester tester) {
  final findings = <ContrastFinding>[];
  void judge(
    Element element,
    RenderBox box,
    InlineSpan span,
    TextStyle base,
    TextScaler scaler,
  ) {
    if (!box.hasSize || box.size.isEmpty || _disabled(box)) return;
    final layers = _layers(element);
    final window = Theme.of(element).colorScheme.surface;
    final fade = layers.whereType<_Fade>().fold<double>(
      1,
      (o, l) => o * l.opacity,
    );
    void visit(InlineSpan span, TextStyle inherited) {
      final style = inherited.merge(span.style);
      if (span is! TextSpan) return;
      final text = span.text?.trim() ?? '';
      final color = style.color ?? style.foreground?.color;
      if (text.isNotEmpty && color != null && color.a * fade > 0.05) {
        final glyph = _paint(layers, window, color);
        final behind = _paint(layers, window, null);
        final ratio = wcagContrast(glyph, behind);
        final size = scaler.scale(style.fontSize ?? 14);
        final bold = (style.fontWeight ?? FontWeight.w400).value >= 700;
        final needed = size >= 24 || (bold && size >= 18.66) ? 3.0 : 4.5;
        if (ratio + 0.005 < needed) {
          findings.add((text: text, ratio: ratio, needed: needed));
        }
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child, style);
      }
    }

    visit(span, base);
  }

  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph) continue;
    judge(
      element,
      paragraph,
      paragraph.text,
      DefaultTextStyle.of(element).style,
      paragraph.textScaler,
    );
  }
  for (final element in find.byType(EditableText).evaluate()) {
    final field = element.widget as EditableText;
    final box = element.renderObject;
    if (box is! RenderBox || field.obscureText) continue;
    judge(
      element,
      box,
      TextSpan(text: field.controller.text),
      field.style,
      field.textScaler ?? MediaQuery.textScalerOf(element),
    );
  }
  return findings;
}

/// Whether the text belongs to a control whose semantics say it is
/// disabled.
bool _disabled(RenderObject object) {
  for (RenderObject? o = object; o != null; o = o.parent) {
    final node = o.debugSemantics;
    if (node == null) continue;
    final enabled = node.getSemanticsData().flagsCollection.isEnabled;
    if (enabled != Tristate.none) return enabled == Tristate.isFalse;
  }
  return false;
}

/// The layers above [element], from the window down to the text.
List<_Layer> _layers(Element element) {
  final nearestFirst = <_Layer>[];
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    final opacity = switch (widget) {
      Opacity(:final opacity) => opacity,
      AnimatedOpacity(:final opacity) => opacity,
      FadeTransition(:final opacity) => opacity.value,
      SliverOpacity(:final opacity) => opacity,
      _ => null,
    };
    if (opacity != null && opacity < 1) nearestFirst.add(_Fade(opacity));
    final fill = _fill(ancestor);
    if (fill != null && fill.a > 0) nearestFirst.add(_Fill(fill));
    return true;
  });
  return nearestFirst.reversed.toList();
}

/// One pixel painted through [layers] onto [window]: with [glyph] on top
/// (the text's pixel) or without it (the pixel beside the text). An opacity
/// composites everything painted inside it over what was below it.
Color _paint(List<_Layer> layers, Color window, Color? glyph) {
  Color from(int i, Color canvas) {
    if (i == layers.length) {
      return glyph == null ? canvas : _over(glyph, canvas);
    }
    return switch (layers[i]) {
      _Fill(:final color) => from(i + 1, _over(color, canvas)),
      _Fade(:final opacity) => _lerp(canvas, from(i + 1, canvas), opacity),
    };
  }

  return from(0, window);
}

/// The fill an ancestor paints behind its child, if any.
Color? _fill(Element ancestor) {
  final widget = ancestor.widget;
  return switch (widget) {
    PhysicalModel(:final color) => color,
    PhysicalShape(:final color) => color,
    AnimatedPhysicalModel(:final color) => color,
    ColoredBox(:final color) => color,
    DecoratedBox(:final decoration) => _decorationColor(decoration),
    Ink(:final decoration?) => _decorationColor(decoration),
    InputDecorator(:final decoration) => _fieldFill(ancestor, decoration),
    Scaffold(:final backgroundColor) =>
      backgroundColor ?? Theme.of(ancestor).scaffoldBackgroundColor,
    _ => null,
  };
}

/// The fill an `InputDecorator` paints, as Material resolves it.
Color? _fieldFill(Element context, InputDecoration decoration) {
  final theme = Theme.of(context);
  final fields = theme.inputDecorationTheme;
  if (!(decoration.filled ?? fields.filled)) return null;
  return decoration.fillColor ??
      fields.fillColor ??
      theme.colorScheme.surfaceContainerHighest;
}

Color? _decorationColor(Decoration decoration) => switch (decoration) {
  BoxDecoration(:final color) => color,
  ShapeDecoration(:final color) => color,
  _ => null,
};

/// [top] composited over the opaque [bottom].
Color _over(Color top, Color bottom) =>
    _lerp(bottom, top.withValues(alpha: 1), top.a);

/// [a] and [b] mixed by [t] (opaque result).
Color _lerp(Color a, Color b, double t) => Color.from(
  alpha: 1,
  red: b.r * t + a.r * (1 - t),
  green: b.g * t + a.g * (1 - t),
  blue: b.b * t + a.b * (1 - t),
);
