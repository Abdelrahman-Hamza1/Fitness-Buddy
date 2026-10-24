import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/application/about_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// About (SF-040, A10 D14): the app version, the food data version, the data
/// credits the sources require (from the pack, active sources only), the
/// open-source licences and the "not medical advice" line. All of it works
/// offline; while the versions load they are placeholders, and without a
/// readable pack the credits say so while the rest of the page shows.
class AboutScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final info = ref.watch(aboutInfoProvider);
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final value = info.value;
    final loading = info.isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s6),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
              vertical: FbSpace.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FbSpace.s2,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.appTitle,
                    style: FbType.headline.copyWith(color: scheme.onSurface),
                  ),
                ),
                if (loading) ...[
                  const FbSkeleton.line(width: 160),
                  const FbSkeleton.line(width: 200),
                ] else ...[
                  if (value == null)
                    Text(l10n.aboutInfoUnavailable, style: muted)
                  else
                    Text(_version(l10n, value), style: muted),
                  if (value?.packVersion case final pack?)
                    Text(l10n.aboutFoodDataVersion(pack), style: muted),
                ],
              ],
            ),
          ),
          FbSectionHeader(title: l10n.aboutCreditsTitle),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FbSpace.s2,
              children: [
                if (loading)
                  const FbSkeleton.line(height: 40)
                else if (value?.activeCredits case final credits?)
                  for (final credit in credits)
                    Text(
                      l10n.aboutCredit(credit.name, credit.credit),
                      style: FbType.body.copyWith(color: scheme.onSurface),
                    )
                else
                  Text(l10n.aboutCreditsUnavailable, style: muted),
              ],
            ),
          ),
          const SizedBox(height: FbSpace.s2),
          FbListRow(
            title: l10n.aboutLicenses,
            trailing: const Icon(FbIcons.next),
            onTap: () => unawaited(
              showFbLicensePage(
                context,
                applicationName: l10n.appTitle,
                applicationVersion: value == null
                    ? ''
                    : l10n.aboutVersion(value.version, value.build),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(FbSpace.s4),
            child: Text(l10n.aboutNotMedical, style: muted),
          ),
        ],
      ),
    );
  }

  String _version(AppLocalizations l10n, AboutInfo info) =>
      info.flavor == AppFlavor.prod
      ? l10n.aboutVersion(info.version, info.build)
      : l10n.aboutVersionFlavor(info.version, info.build, info.flavor.name);
}
