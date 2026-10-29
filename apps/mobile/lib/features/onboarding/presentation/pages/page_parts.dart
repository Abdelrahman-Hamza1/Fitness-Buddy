import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// A muted line under a page title or a field.
class SetupHint extends StatelessWidget {
  /// Creates the hint.
  const new(this.text, {super.key});

  /// The (already translated) text.
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: FbType.bodySmall.copyWith(
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
