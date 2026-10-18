import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// The colour roles of [palette] with their names, in the order the Tokens
/// tab shows them. Names are the palette's field names (identifiers, not UI
/// strings).
List<(String, Color)> paletteRoles(FbPalette palette) => [
  ('brand', palette.brand),
  ('onBrand', palette.onBrand),
  ('brandContainer', palette.brandContainer),
  ('onBrandContainer', palette.onBrandContainer),
  ('surface', palette.surface),
  ('surfaceContainer', palette.surfaceContainer),
  ('surfaceContainerHigh', palette.surfaceContainerHigh),
  ('onSurface', palette.onSurface),
  ('onSurfaceVariant', palette.onSurfaceVariant),
  ('outline', palette.outline),
  ('outlineVariant', palette.outlineVariant),
  ('protein', palette.protein),
  ('carbs', palette.carbs),
  ('fat', palette.fat),
  ('fiber', palette.fiber),
  ('overTarget', palette.overTarget),
  ('success', palette.success),
  ('info', palette.info),
  ('error', palette.error),
  ('errorContainer', palette.errorContainer),
  ('inverseSurface', palette.inverseSurface),
  ('inverseOnSurface', palette.inverseOnSurface),
  ('inversePrimary', palette.inversePrimary),
];

/// The type styles with their names, largest first.
const List<(String, TextStyle)> typeStyles = [
  ('display', FbType.display),
  ('headline', FbType.headline),
  ('title', FbType.title),
  ('body', FbType.body),
  ('bodySmall', FbType.bodySmall),
  ('label', FbType.label),
  ('caption', FbType.caption),
];
