import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The "Tell Buddy what you ate" bar (HM-008). A shell: tapping it calls
/// [onTap] (the app opens the real input); it has no text logic.
class FbInputBar extends StatelessWidget {
  /// Creates the bar. [onCamera] and [onBarcode] show their buttons when set.
  const new({
    required this.hint,
    required this.onTap,
    this.onCamera,
    this.onBarcode,
    super.key,
  });

  /// The (already translated) hint text.
  final String hint;

  /// Called when the bar is tapped.
  final VoidCallback onTap;

  /// Shows a camera button when set.
  final VoidCallback? onCamera;

  /// Shows a barcode button when set.
  final VoidCallback? onBarcode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = FbLocalizations.of(context);
    return Material(
      color: scheme.surfaceContainerHigh,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: FbSpace.s4,
                    end: FbSpace.s2,
                    top: FbSpace.s2,
                    bottom: FbSpace.s2,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FbType.body.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onCamera != null)
            IconButton(
              onPressed: onCamera,
              tooltip: l10n.fbInputCamera,
              icon: const Icon(FbIcons.camera),
            ),
          if (onBarcode != null)
            IconButton(
              onPressed: onBarcode,
              tooltip: l10n.fbInputBarcode,
              icon: const Icon(FbIcons.barcode),
            ),
        ],
      ),
    );
  }
}
