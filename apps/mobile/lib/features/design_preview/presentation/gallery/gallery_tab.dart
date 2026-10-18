import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_registry.dart';
import 'package:material_ui/material_ui.dart';

/// The Components tab: every design-system component in all its states.
///
/// Built eagerly (a `Column`, not a lazy list): it is a developer tool with
/// about 20 sections, and the gallery test then exercises every section.
class GalleryTab extends StatelessWidget {
  /// Creates the tab.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in gallerySections)
            Column(
              key: ValueKey('gallery.${section.name}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FbSectionHeader(title: section.name),
                for (final state in section.states(context))
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: FbSpace.s4,
                      vertical: FbSpace.s2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: FbSpace.s1),
                        state.child,
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
