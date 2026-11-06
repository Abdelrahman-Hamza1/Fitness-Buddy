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
/// until answered. A one-line notice on Progress (UX-047, A63 D6); Review
/// opens the offer in a sheet: "Maintain during Ramadan" or "Keep my goal",
/// nothing written before a tap. Normal targets resume after Ramadan either
/// way (TG-061).
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
      child: FbNoticeRow(
        key: const ValueKey('ramadan-offer-row'),
        icon: FbIcons.ramadan,
        text: l10n.ramadanOfferRow,
        actionLabel: l10n.noticeReview,
        actionKey: const ValueKey('ramadan-offer-review'),
        onAction: () => unawaited(
          showFbSheet<void>(
            context,
            builder: (sheet) => FbProposalCard(
              key: const ValueKey('ramadan-offer-card'),
              header: l10n.ramadanOfferTitle,
              details: Text(l10n.ramadanOfferBody, style: FbType.body),
              actions: FbProposalActions(
                discardLabel: l10n.ramadanTargetsKeep,
                confirmLabel: l10n.ramadanOfferMaintain,
                onDiscard: () => _tap(sheet, ref, season, false),
                onConfirm: () => _tap(sheet, ref, season, true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The answer, then the sheet closes.
  static void _tap(
    BuildContext sheet,
    WidgetRef ref,
    RamadanSeason season,
    bool maintain,
  ) {
    unawaited(_answer(sheet, ref, season, maintain));
    Navigator.of(sheet).pop();
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
        .updateRamadanSeason(
          season.hijriYear,
          (s) => s.copyWith(maintain: maintain, targetsAnswered: true),
        );
    if (!host.mounted) return;
    reportSettingsOutcome(
      host,
      outcome,
      () => maintain ? host.l10n.ramadanMaintainOn : host.l10n.ramadanKeepGoal,
    );
  }
}
