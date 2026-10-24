import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// Asks before a form with unsaved changes is left (UX-052): the typed values
/// are not lost by a stray back gesture. Resolves to true when the user
/// chooses to discard them.
Future<bool> showDiscardChangesSheet(BuildContext context) async {
  final discard = await showFbSheet<bool>(
    context,
    title: context.l10n.personalFoodDiscardTitle,
    builder: (_) => const DiscardChangesSheet(),
  );
  return discard ?? false;
}

/// The body of the discard sheet: keep editing (the dominant choice) or
/// discard. Pops with true to discard.
class DiscardChangesSheet extends StatelessWidget {
  /// Creates the sheet body.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(
          l10n.personalFoodDiscardMessage,
          style: FbType.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        FbButton.primary(
          label: l10n.personalFoodDiscardKeep,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FbButton.secondary(
          label: l10n.personalFoodDiscardConfirm,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
