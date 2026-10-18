import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_tab.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/mockups_tab.dart';
import 'package:fb_mobile/features/design_preview/presentation/preview_switches.dart';
import 'package:fb_mobile/features/design_preview/presentation/tokens_tab.dart';
import 'package:material_ui/material_ui.dart';

/// The design preview (A02 D15), dev flavor only: Mockups, Components and
/// Tokens, with the A/B and light/dark/system switches pinned above the tab
/// content so the owner can compare without leaving the screen (D16).
class DesignPreviewScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.previewTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.previewTabMockups),
              Tab(text: l10n.previewTabComponents),
              Tab(text: l10n.previewTabTokens),
            ],
          ),
        ),
        body: const Column(
          children: [
            PreviewSwitches(),
            Expanded(
              child: TabBarView(
                children: [MockupsTab(), GalleryTab(), TokensTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
