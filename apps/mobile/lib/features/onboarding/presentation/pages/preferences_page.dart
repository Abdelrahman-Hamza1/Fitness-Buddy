import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/widgets.dart';

/// Page 4 (D9, UX-060): week start, halal and city, prefilled from the
/// settings and each skippable. Nothing is written until Save; then only
/// the ones that differ (D10).
class PreferencesPage extends StatelessWidget {
  /// Creates the page.
  const new({required this.draft, required this.flow, super.key});

  /// What setup holds.
  final SetupDraft draft;

  /// The view model.
  final SetupFlow flow;

  Future<void> _pickWeekStart(BuildContext context) async {
    final picked = await showFbOptionSheet<DayOfWeek>(
      context,
      title: context.l10n.settingsWeekStart,
      selected: draft.weekStart,
      options: [
        for (final day in DayOfWeek.values)
          FbOption(value: day, label: weekdayName(context, day)),
      ],
    );
    if (picked != null) flow.setWeekStart(picked);
  }

  Future<void> _pickCity(BuildContext context) async {
    final city = await showCityPickSheet(context, currentId: draft.cityId);
    if (city != null) flow.setCity(city);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final city = draft.city;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        SetupHint(l10n.setupPreferencesHint),
        // One card: the rows' own inset lines up with the card's edge,
        // not the page's padding plus the row's (no double inset).
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FbListRow(
                title: l10n.settingsWeekStart,
                subtitle: weekdayName(context, draft.weekStart),
                trailing: const Icon(FbIcons.next),
                onTap: () => unawaited(_pickWeekStart(context)),
              ),
              FbSwitchRow(
                title: l10n.settingsHalal,
                subtitle: l10n.settingsHalalHint,
                value: draft.halal,
                onChanged: flow.setHalal,
              ),
              FbListRow(
                title: l10n.settingsCity,
                subtitle: city == null
                    ? l10n.settingsCityNotSet
                    : cityLabel(l10n, city),
                trailing: const Icon(FbIcons.next),
                onTap: () => unawaited(_pickCity(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
