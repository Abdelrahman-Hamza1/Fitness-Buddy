import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/mockup_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The action row both proposal mockups share: the secondary [discardLabel]
/// at the start and the primary [confirmLabel] filling the rest. At a large
/// text scale the two stack, primary on top. A22 promotes this into
/// `fb_design_system` (backlog).
class ProposalActionRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.discardLabel,
    required this.confirmLabel,
    super.key,
  });

  /// Label of the secondary button.
  final String discardLabel;

  /// Label of the primary button.
  final String confirmLabel;

  /// From this text scale on, the buttons stack.
  static const double stackFromScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final discard = FbButton.secondary(
      label: discardLabel,
      onPressed: mockupNoop,
      expand: MediaQuery.textScalerOf(context).scale(1) >= stackFromScale,
    );
    final confirm = FbButton.primary(
      label: confirmLabel,
      icon: FbIcons.check,
      onPressed: mockupNoop,
      expand: true,
    );
    if (MediaQuery.textScalerOf(context).scale(1) >= stackFromScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [confirm, discard],
      );
    }
    return Row(
      spacing: FbSpace.s3,
      children: [
        discard,
        Expanded(child: confirm),
      ],
    );
  }
}
