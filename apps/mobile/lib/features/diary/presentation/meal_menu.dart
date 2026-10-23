import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/presentation/copy_meal_sheet.dart';
import 'package:fb_mobile/features/diary/presentation/save_meal_sheet.dart';
import 'package:flutter/widgets.dart';

enum _MealAction { copy, save }

/// The "⋯" menu of a meal that has items (DY-023, A08 D11): copy it to
/// another day or meal, or save its items as a saved meal. A short action
/// sheet; each choice opens its own sheet.
Future<void> showMealMenu(
  BuildContext context, {
  required SlotSection section,
  required LocalDate date,
}) async {
  final l10n = context.l10n;
  final name = section.slot == null
      ? l10n.diarySlotOther
      : slotLabel(l10n, section.slot!);
  final action = await showFbSheet<_MealAction>(
    context,
    title: name,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FbListRow(
          title: l10n.diaryMealCopyAction,
          onTap: () => Navigator.of(sheet).pop(_MealAction.copy),
        ),
        FbListRow(
          title: l10n.diaryMealSaveAction,
          onTap: () => Navigator.of(sheet).pop(_MealAction.save),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _MealAction.copy:
      await showCopyMealSheet(context, section: section, date: date);
    case _MealAction.save:
      await showSaveMealSheet(context, section: section, date: date);
  }
}
