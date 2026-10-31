import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// A question's title and the plain line under it (A51): the title is the
/// page's heading for a screen reader.
class SetupHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.title, this.hint, super.key});

  /// The question, already translated.
  final String title;

  /// The line under it.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s2,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: FbType.headline.copyWith(color: scheme.onSurface),
          ),
        ),
        if (hint case final hint?) SetupHint(hint),
      ],
    );
  }
}

/// A muted line under a page title or a field.
class SetupHint extends StatelessWidget {
  /// Creates the hint.
  const new(this.text, {super.key});

  /// The (already translated) text.
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: FbType.body.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// A label above a choice.
class SetupLabel extends StatelessWidget {
  /// Creates the label.
  const new(this.text, {super.key});

  /// The (already translated) text.
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: FbType.label.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

/// A benefit line: an icon in a tinted circle, a title and a detail.
class SetupBenefit extends StatelessWidget {
  /// Creates the line.
  const new({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  /// A decorative icon (from `FbIcons`).
  final IconData icon;

  /// The benefit.
  final String title;

  /// Its detail.
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s3,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: FbRadius.mdAll,
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: FbType.body.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  body,
                  style: FbType.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
