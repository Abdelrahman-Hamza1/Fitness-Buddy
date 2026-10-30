import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// Asks before the weight history is left with typed rows (UX-052, A15b
/// D17). Resolves to true when the user chooses to discard them.
Future<bool> showWeightHistoryDiscardSheet(BuildContext context) async {
  final discard = await showFbSheet<bool>(
    context,
    title: context.l10n.weightHistoryDiscardTitle,
    builder: (_) => const WeightHistoryDiscardSheet(),
  );
  return discard ?? false;
}

/// The body of the discard sheet: keep editing (the dominant choice) or
/// discard. Pops with true to discard.
class WeightHistoryDiscardSheet extends StatelessWidget {
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
          l10n.weightHistoryDiscardMessage,
          style: FbType.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        FbButton.primary(
          label: l10n.weightHistoryDiscardKeep,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FbButton.secondary(
          label: l10n.weightHistoryDiscardConfirm,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
