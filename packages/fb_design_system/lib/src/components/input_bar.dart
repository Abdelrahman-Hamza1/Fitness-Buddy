import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/brand/buddy_avatar.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The "Tell Buddy what you ate" bar (HM-008): Buddy's avatar at the start,
/// the hint, and optional camera and barcode buttons; at least 52 dp tall. A
/// shell: tapping it calls [onTap] (the app opens the real input); it has no
/// text logic.
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

  /// The bar's minimum height (the identity's input bar).
  static const double minHeight = 52;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = FbLocalizations.of(context);
    // Without buttons at the end, keep the hint clear of the pill's curve.
    final trailing = onCamera != null || onBarcode != null;
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
                constraints: const BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: FbSpace.s3,
                    end: trailing ? FbSpace.s2 : FbSpace.s4,
                    top: FbSpace.s2,
                    bottom: FbSpace.s2,
                  ),
                  child: Row(
                    children: [
                      const FbBuddyAvatar(),
                      const SizedBox(width: FbSpace.s3),
                      Expanded(
                        child: Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FbType.body.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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
