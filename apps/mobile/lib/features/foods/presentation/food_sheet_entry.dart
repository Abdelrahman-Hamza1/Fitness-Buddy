import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/app_navigator.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/foods/application/log_food.dart';
import 'package:fb_mobile/features/foods/presentation/food_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the search screen hands to the food sheet when a result is tapped
/// (A07 D11): only the structured choice and where the log should go.
@immutable
final class FoodPick {
  /// Creates the pick.
  const new({
    required this.row,
    this.date,
    this.slotId,
    this.carried,
    this.replacing,
  });

  /// The tapped result; its `choiceRef` is what the sheet loads.
  final FoodSearchRow row;

  /// The diary day to add to; null for today.
  final LocalDate? date;

  /// The meal slot to add to; null to choose by the time of day.
  final String? slotId;

  /// The quantity typed in the query ("2 khubz arabi" carries 2), if the
  /// search accepted that reading.
  final ParsedAmount? carried;

  /// The logged item this pick replaces, at the version the user saw
  /// (change-food mode, A08 D7); null to add a new item.
  final VersionedId? replacing;
}

/// Opens the food sheet for [pick] (amount, unit, slot, Add).
///
/// The seam between the search screen and the amount flow. When the food is
/// added (AI-048), the sheet closes, then the search screen closes (back to
/// the caller), and the undo snackbar shows on the root messenger (UX-030),
/// where it survives the screen that started it.
Future<void> openFoodSheet(BuildContext context, FoodPick pick) async {
  FocusScope.of(context).unfocus();
  final container = ProviderScope.containerOf(context);
  // The root navigator's context outlives the search screen.
  final host = Navigator.of(context, rootNavigator: true).context;
  final logged = await showFbSheet<FoodLogged>(
    context,
    builder: (_) => FoodSheet(pick: pick),
  );
  if (logged == null || !host.mounted) return;
  container.read(appNavigatorProvider).pop();
  showUndoFeedback(
    host,
    message: pick.replacing != null
        ? host.l10n.foodChangedMessage(logged.nameEn)
        : host.l10n.foodLoggedMessage(
            logged.nameEn,
            [
                  for (final slot
                      in container.read(foodSlotsProvider).value ??
                          <MealSlot>[])
                    if (slot.id == logged.slotId) slotLabel(host.l10n, slot),
                ].firstOrNull ??
                host.l10n.foodSheetSlotNone,
          ),
    undoEntryId: logged.undoEntryId,
  );
}
