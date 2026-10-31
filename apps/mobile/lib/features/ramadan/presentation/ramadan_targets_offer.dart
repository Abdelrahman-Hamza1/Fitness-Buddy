import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/ramadan/application/ramadan_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The one-tap Ramadan targets offer in the weekly summary (TG-060, phase 1
/// instead of the Buddy review, A41a D8): during the first Ramadan week,
/// until answered. "Maintain during Ramadan" or "Keep my goal"; normal
/// targets resume after Ramadan either way (TG-061).
class RamadanTargetsOfferCard extends ConsumerWidget {
  /// The card (nothing when no offer is due).
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(ramadanTargetsOfferProvider).value;
    if (season == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      key: const ValueKey('ramadan-targets-offer'),
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: FbProposalCard(
        header: l10n.ramadanOfferTitle,
        details: Text(l10n.ramadanOfferBody, style: FbType.body),
        actions: FbProposalActions(
          discardLabel: l10n.ramadanTargetsKeep,
          confirmLabel: l10n.ramadanOfferMaintain,
          onDiscard: () => unawaited(_answer(context, ref, season, false)),
          onConfirm: () => unawaited(_answer(context, ref, season, true)),
        ),
      ),
    );
  }

  static Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    RamadanSeason season,
    bool maintain,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(settingsActionsProvider)
        .setRamadanSeason(
          season.copyWith(maintain: maintain, targetsAnswered: true),
        );
    if (!host.mounted) return;
    reportSettingsOutcome(
      host,
      outcome,
      () => maintain ? host.l10n.ramadanMaintainOn : host.l10n.ramadanKeepGoal,
    );
  }
}
