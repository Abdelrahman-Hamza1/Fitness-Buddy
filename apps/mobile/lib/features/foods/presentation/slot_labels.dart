import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';

/// The name of [slot]: its own name when the user gave one, else the word
/// for its default key.
String slotLabel(AppLocalizations l10n, MealSlot slot) =>
    slot.name ??
    switch (slot.defaultKey) {
      'breakfast' => l10n.todaySlotBreakfast,
      'lunch' => l10n.todaySlotLunch,
      'snacks' => l10n.todaySlotSnacks,
      'dinner' => l10n.todaySlotDinner,
      final key? => key,
      null => '',
    };
