import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The meals an item can move to: the active ones of the normal mode, in
/// order (the mode switch arrives with A41).
List<MealSlot> movableSlots(Iterable<MealSlot> slots) => [
  for (final slot in slots)
    if (slot.active && slot.mode == SlotMode.normal) slot,
]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

/// The meals as rows (DY-022): the current one is checked and does nothing,
/// any other calls [onPick].
class MoveToSlotList extends StatelessWidget {
  /// Creates the list of [slots].
  const new({
    required this.slots,
    required this.currentSlotId,
    required this.onPick,
    super.key,
  });

  /// The meals to offer.
  final List<MealSlot> slots;

  /// The meal the item is in now.
  final String currentSlotId;

  /// Called with the picked meal.
  final ValueChanged<MealSlot> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final slot in slots)
          FbListRow(
            title: slotLabel(l10n, slot),
            trailing: slot.id == currentSlotId
                ? Semantics(
                    label: l10n.diaryMoveCurrent,
                    child: const Icon(FbIcons.check),
                  )
                : null,
            onTap: slot.id == currentSlotId ? null : () => onPick(slot),
          ),
      ],
    );
  }
}

/// Shows the meals of [slots] and resolves to the picked one, or null when
/// the sheet is dismissed.
Future<MealSlot?> showMoveToSlotSheet(
  BuildContext context, {
  required List<MealSlot> slots,
  required String currentSlotId,
}) => showFbSheet<MealSlot>(
  context,
  title: context.l10n.diaryMoveTitle,
  builder: (sheet) => MoveToSlotList(
    slots: movableSlots(slots),
    currentSlotId: currentSlotId,
    onPick: (slot) => Navigator.of(sheet).pop(slot),
  ),
);
