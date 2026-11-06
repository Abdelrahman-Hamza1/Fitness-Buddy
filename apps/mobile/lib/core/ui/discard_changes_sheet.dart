import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// Asks before a form with unsaved changes is left (UX-052): the typed values
/// are not lost by a stray back gesture. Resolves to true when the user
/// chooses to discard them.
///
/// [message] says what was changed (default: a food, its first user).
Future<bool> showDiscardChangesSheet(
  BuildContext context, {
  String? message,
}) async {
  final discard = await showFbSheet<bool>(
    context,
    title: context.l10n.personalFoodDiscardTitle,
    builder: (_) => DiscardChangesSheet(message: message),
  );
  return discard ?? false;
}

/// The body of the discard sheet: keep editing (the dominant choice) or
/// discard. Pops with true to discard.
class DiscardChangesSheet extends StatelessWidget {
  /// Creates the sheet body.
  const new({this.message, super.key});

  /// What was changed, or `null` for the food form's line.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(
          message ?? l10n.personalFoodDiscardMessage,
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

/// Guards a form sheet with edits (A65 m8, UX-052): while [dirty], a tap
/// outside or Back asks first with the discard sheet, and closes only when
/// the user discards. Show the sheet with `enableDrag: false` (a swipe
/// down pops past this guard).
class SheetDiscardGuard extends StatelessWidget {
  /// Guards [child] while [dirty].
  const new({required this.dirty, required this.child, super.key});

  /// The sheet holds typed values that would be lost.
  final bool dirty;

  /// The sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final navigator = Navigator.of(context);
      final discard = await showDiscardChangesSheet(
        context,
        message: context.l10n.sheetDiscardMessage,
      );
      if (discard && navigator.mounted) navigator.pop();
    },
    child: child,
  );
}
