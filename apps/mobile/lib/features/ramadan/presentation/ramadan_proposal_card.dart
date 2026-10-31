import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/ramadan/application/ramadan_providers.dart';
import 'package:fb_mobile/features/ramadan/presentation/ramadan_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Today's "Switch on Ramadan mode?" proposal (LC-031, J11, A41a D4): from
/// three days before the expected start until the end, while the user
/// hasn't decided. Switch on or Not now; both are stored (with Undo), so it
/// is never asked again. Never a silent switch.
class RamadanProposalCard extends ConsumerWidget {
  /// The card (nothing when no proposal is due).
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(ramadanProposalProvider).value;
    if (period == null) return const SizedBox.shrink();
    final today = ref.watch(todayProvider).value;
    final l10n = context.l10n;
    final started = today != null && !today.isBefore(period.start);
    return Padding(
      key: const ValueKey('ramadan-proposal'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        0,
        FbSpace.s4,
        FbDensity.cardGap,
      ),
      child: FbProposalCard(
        header: l10n.ramadanProposalTitle,
        details: Text(
          started
              ? l10n.ramadanProposalStarted
              : l10n.ramadanProposalBody(
                  ramadanDateText(context, period.start),
                ),
          style: FbType.body,
        ),
        actions: FbProposalActions(
          discardLabel: l10n.ramadanNotNow,
          confirmLabel: l10n.ramadanSwitchOn,
          onDiscard: () => unawaited(_decide(context, ref, period, on: false)),
          onConfirm: () => unawaited(_decide(context, ref, period, on: true)),
        ),
      ),
    );
  }

  static Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    RamadanPeriod period, {
    required bool on,
  }) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(settingsActionsProvider)
        .setRamadanSeason(RamadanSeason(hijriYear: period.hijriYear, on: on));
    if (!host.mounted) return;
    reportSettingsOutcome(
      host,
      outcome,
      () => on ? host.l10n.ramadanSwitchedOn : host.l10n.ramadanNotNowDone,
    );
  }
}
