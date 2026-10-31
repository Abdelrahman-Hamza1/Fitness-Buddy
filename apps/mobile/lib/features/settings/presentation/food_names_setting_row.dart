import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/application/settings_providers.dart';
import 'package:fb_mobile/features/settings/presentation/settings_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The "Food names" row (D-091, sketch `FnSetting`): Match my phone
/// (default) / English / Arabic / Both, in an option sheet; a change is a
/// direct action with Undo. Its own widget so the Me › Preferences page
/// (A51) can take it as it is.
class FoodNamesSettingRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final setting =
        ref.watch(foodNameSettingProvider).value ?? FoodNameLanguage.phone;
    return FbListRow(
      key: const ValueKey('settings-food-names'),
      title: l10n.foodNamesSetting,
      subtitle: foodNameLanguageLabel(l10n, setting),
      trailing: const Icon(FbIcons.next),
      onTap: () => unawaited(_pick(context, ref, setting)),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    FoodNameLanguage current,
  ) async {
    final l10n = context.l10n;
    final host = Navigator.of(context, rootNavigator: true).context;
    final phone = FoodNameLanguage.phone.resolve(
      ref.read(phoneLanguagesProvider),
    );
    final picked = await showFbOptionSheet<FoodNameLanguage>(
      context,
      title: l10n.foodNamesSetting,
      selected: current,
      options: [
        FbOption(
          value: FoodNameLanguage.phone,
          label: l10n.foodNamesPhone,
          subtitle: phone == FoodNameLanguage.arabic
              ? l10n.foodNamesPhoneArabic
              : l10n.foodNamesPhoneEnglish,
        ),
        FbOption(value: FoodNameLanguage.english, label: l10n.foodNamesEnglish),
        FbOption(value: FoodNameLanguage.arabic, label: l10n.foodNamesArabic),
        FbOption(
          value: FoodNameLanguage.both,
          label: l10n.foodNamesBoth,
          subtitle: l10n.foodNamesBothHint,
        ),
      ],
    );
    if (picked == null || !host.mounted) return;
    final outcome = await ref
        .read(settingsActionsProvider)
        .setFoodNames(picked);
    if (!host.mounted) return;
    reportSettingsOutcome(
      host,
      outcome,
      () => host.l10n.foodNamesSet(foodNameLanguageLabel(host.l10n, picked)),
    );
  }
}

/// The name of a "Food names" choice.
String foodNameLanguageLabel(
  AppLocalizations l10n,
  FoodNameLanguage language,
) => switch (language) {
  FoodNameLanguage.phone => l10n.foodNamesPhone,
  FoodNameLanguage.english => l10n.foodNamesEnglish,
  FoodNameLanguage.arabic => l10n.foodNamesArabic,
  FoodNameLanguage.both => l10n.foodNamesBoth,
};
