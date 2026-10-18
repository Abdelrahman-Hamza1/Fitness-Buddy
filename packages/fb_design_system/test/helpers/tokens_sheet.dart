import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Swatches of every colour role of [palette] plus the type scale, for the
/// tokens golden. Labels are role names (test fixtures, not product copy).
class TokensSheet extends StatelessWidget {
  const new({required this.palette, super.key});

  final FbPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final swatches = <(String, Color)>[
      ('brand', p.brand),
      ('brandContainer', p.brandContainer),
      ('surface', p.surface),
      ('surfaceContainer', p.surfaceContainer),
      ('surfaceContainerHigh', p.surfaceContainerHigh),
      ('onSurface', p.onSurface),
      ('onSurfaceVariant', p.onSurfaceVariant),
      ('outline', p.outline),
      ('outlineVariant', p.outlineVariant),
      ('protein', p.protein),
      ('carbs', p.carbs),
      ('fat', p.fat),
      ('fiber', p.fiber),
      ('overTarget', p.overTarget),
      ('success', p.success),
      ('info', p.info),
      ('error', p.error),
      ('errorContainer', p.errorContainer),
      ('inverseSurface', p.inverseSurface),
    ];
    final styles = <(String, TextStyle)>[
      ('display 48', FbType.display),
      ('headline 24', FbType.headline),
      ('title 18', FbType.title),
      ('body 16', FbType.body),
      ('bodySmall 14', FbType.bodySmall),
      ('label 14', FbType.label),
      ('caption 12', FbType.caption),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              for (final (name, color) in swatches)
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: FbRadius.smAll,
                          border: Border.all(color: p.outlineVariant),
                        ),
                      ),
                      Text(
                        name,
                        style: FbType.caption.copyWith(color: p.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: FbSpace.s4),
          for (final (name, style) in styles)
            Text(name, style: style.copyWith(color: p.onSurface)),
        ],
      ),
    );
  }
}
