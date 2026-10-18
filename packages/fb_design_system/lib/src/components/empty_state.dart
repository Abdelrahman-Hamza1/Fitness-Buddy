import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A friendly "nothing here yet" (UX-050): an icon, a title, one line of
/// help and an optional action (usually an `FbButton`).
class FbEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const new({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  /// An icon from `FbIcons`.
  final IconData icon;

  /// The headline.
  final String title;

  /// One line of help.
  final String message;

  /// What to do next.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: FbSpace.s3),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: FbSpace.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: FbSpace.s4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
