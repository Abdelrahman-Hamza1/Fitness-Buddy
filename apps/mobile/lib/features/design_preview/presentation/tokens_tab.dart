import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/theme/theme_providers.dart';
import 'package:fb_mobile/features/design_preview/application/gallery_samples.dart';
import 'package:fb_mobile/features/design_preview/application/token_roles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Tokens tab: the colour swatches, the type scale and the live contrast
/// ratio of every text/background pair of the palette on screen (UX-071).
class TokensTab extends ConsumerWidget {
  /// Creates the tab.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = FbPalette.of(
      ref.watch(themeVariantProvider),
      theme.brightness,
    );
    final pairs = fbContrastPairs(palette);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FbSectionHeader(title: l10n.previewTokensColors),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
            ),
            child: Wrap(
              spacing: FbSpace.s2,
              runSpacing: FbSpace.s2,
              children: [
                for (final (name, color) in paletteRoles(palette))
                  _Swatch(name: name, color: color),
              ],
            ),
          ),
          FbSectionHeader(title: l10n.previewTokensType),
          for (final (name, style) in typeStyles)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FbSpace.s4,
                vertical: FbSpace.s1,
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.previewTypeSample, style: style),
                    TextSpan(
                      text: '  $name',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FbSectionHeader(title: l10n.previewTokensContrast),
          for (final pair in pairs) _ContrastRow(pair: pair),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const new({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: FbRadius.smAll,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: const SizedBox(height: FbSpace.s6, width: double.infinity),
          ),
          const SizedBox(height: FbSpace.s1),
          Text(name, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ContrastRow extends StatelessWidget {
  const new({required this.pair});

  final FbContrastPair pair;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final passes = pair.passes;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s4,
        vertical: FbSpace.s1,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: pair.background,
              borderRadius: FbRadius.smAll,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FbSpace.s2,
                vertical: FbSpace.s1,
              ),
              child: Text(
                GallerySamples.contrastSample,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: pair.foreground,
                ),
              ),
            ),
          ),
          const SizedBox(width: FbSpace.s3),
          Expanded(child: Text(pair.name, style: theme.textTheme.bodySmall)),
          const SizedBox(width: FbSpace.s2),
          Text(
            '${pair.ratio.toStringAsFixed(2)} (${pair.kind.minimum})',
            style: FbType.numeric(theme.textTheme.bodySmall!),
          ),
          const SizedBox(width: FbSpace.s2),
          Icon(
            passes ? FbIcons.check : FbIcons.error,
            size: FbSpace.s4,
            semanticLabel: passes
                ? l10n.previewContrastPasses
                : l10n.previewContrastFails,
          ),
        ],
      ),
    );
  }
}
