import 'package:fb_design_system/src/components/card.dart';
import 'package:fb_design_system/src/components/section_header.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A group of settings rows (A51, A65 M4): an optional section header, the
/// rows in one card, and an optional quiet note under the card. The one
/// layout of every Me page (Me, its subpages, Notifications, Ramadan,
/// About, Profile & goal). Nothing when there are no rows.
class FbRowGroup extends StatelessWidget {
  /// Creates the group.
  const new({required this.children, this.title, this.note, super.key});

  /// The header, or null.
  final String? title;

  /// The rows (usually `FbListRow`, `FbSwitchRow`).
  final List<Widget> children;

  /// A quiet line under the card, or null.
  final String? note;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final title?) FbSectionHeader(title: title),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        if (note case final note?)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              FbSpace.s4,
              FbSpace.s2,
              FbSpace.s4,
              0,
            ),
            child: Text(
              note,
              style: FbType.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
