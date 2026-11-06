import 'package:fb_design_system/src/components/list_row.dart';
import 'package:fb_design_system/src/components/sheet.dart';
import 'package:material_ui/material_ui.dart';

/// One choice of an action sheet (A65 m9).
final class FbAction<T> {
  /// Creates a choice that pops [value].
  const new({
    required this.value,
    required this.label,
    this.icon,
    this.subtitle,
    this.destructive = false,
    this.key,
  });

  /// What the sheet resolves to.
  final T value;

  /// The (already translated) label.
  final String label;

  /// A leading icon (from `FbIcons`).
  final IconData? icon;

  /// A second, muted line.
  final String? subtitle;

  /// Deletes or removes: the error tone, and always last.
  final bool destructive;

  /// The row's key, for tests.
  final Key? key;
}

/// The rows of an action sheet: a leading icon, the label, the
/// destructive choices last in the error tone. Rows line up with the
/// sheet's title (no extra inset). Public for goldens and custom sheets.
class FbActionList<T> extends StatelessWidget {
  /// Creates the rows; a tap calls [onSelected].
  const new({required this.actions, required this.onSelected, super.key});

  /// The choices, in order (destructive ones are moved last).
  final List<FbAction<T>> actions;

  /// Called with the chosen value.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ordered = [
      ...actions.where((a) => !a.destructive),
      ...actions.where((a) => a.destructive),
    ];
    Widget row(FbAction<T> a) => FbListRow(
      key: a.key,
      leading: a.icon == null ? null : Icon(a.icon),
      title: a.label,
      subtitle: a.subtitle,
      onTap: () => onSelected(a.value),
    );
    return ListTileTheme.merge(
      contentPadding: EdgeInsetsDirectional.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in ordered)
            if (a.destructive)
              ListTileTheme.merge(
                textColor: scheme.error,
                iconColor: scheme.error,
                child: row(a),
              )
            else
              row(a),
        ],
      ),
    );
  }
}

/// Shows an action sheet (A65 m9): the one style of "⋯" menus. Resolves to
/// the chosen value, or null when dismissed.
Future<T?> showFbActionSheet<T>(
  BuildContext context, {
  required List<FbAction<T>> actions,
  String? title,
}) => showFbSheet<T>(
  context,
  title: title,
  builder: (sheet) => FbActionList<T>(
    actions: actions,
    onSelected: (value) => Navigator.of(sheet).pop(value),
  ),
);
