import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/application/about_info.dart';
import 'package:fb_mobile/features/settings/application/test_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// About (SF-040, A10 D14): the app version, the food data version, the data
/// credits the sources require (from the pack, active sources only), the
/// open-source licences and the "not medical advice" line. All of it works
/// offline; while the versions load they are placeholders, and without a
/// readable pack the credits say so while the rest of the page shows. A long
/// press on the version line sends a test error report (A11 D17).
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
                // The brand lockup is the header (A44 D14b).
                FbBrandLockup(name: l10n.appTitle),
                if (loading) ...[
                  const FbSkeleton.line(width: 160),
                  const FbSkeleton.line(width: 200),
                ] else ...[
                  // Long-press: the hidden test error report (A11 D17).
                  Semantics(
                    label: value == null
                        ? l10n.aboutInfoUnavailable
                        : _version(l10n, value),
                    onLongPress: () => unawaited(_testReport(context, ref)),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () => unawaited(_testReport(context, ref)),
                      child: SizedBox(
                        width: double.infinity,
                        child: value == null
                            ? Text(l10n.aboutInfoUnavailable, style: muted)
                            : Text(_version(l10n, value), style: muted),
                      ),
                    ),
                  ),
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

  /// Asks, then sends the test error report (A11 D17). Without a crash-report
  /// address (dev builds) it only says so; nothing is asked or sent.
  Future<void> _testReport(BuildContext context, WidgetRef ref) async {
    final sender = ref.read(testReportSenderProvider);
    final isDev = ref.read(appConfigProvider).flavor == AppFlavor.dev;
    final l10n = context.l10n;
    if (!sender.enabled) {
      showFbSnackBar(
        context,
        isDev ? l10n.aboutTestReportOffDev : l10n.aboutTestReportOffNoDsn,
      );
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final confirmed = await showFbSheet<bool>(
      context,
      title: l10n.aboutTestReportTitle,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          Text(
            l10n.aboutTestReportBody,
            style: FbType.body.copyWith(
              color: Theme.of(sheet).colorScheme.onSurface,
            ),
          ),
          FbButton.primary(
            label: l10n.aboutTestReportSend,
            onPressed: () => Navigator.of(sheet).pop(true),
            expand: true,
          ),
          FbButton.text(
            label: l10n.aboutTestReportCancel,
            onPressed: () => Navigator.of(sheet).pop(false),
            expand: true,
          ),
        ],
      ),
    );
    if (confirmed != true || !host.mounted) return;
    final outcome = await sender.sendReport();
    if (!host.mounted) return;
    showFbSnackBar(
      host,
      outcome == TestReportOutcome.sent
          ? host.l10n.aboutTestReportSent
          : isDev
          ? host.l10n.aboutTestReportOffDev
          : host.l10n.aboutTestReportOffNoDsn,
    );
  }

  String _version(AppLocalizations l10n, AboutInfo info) =>
      info.flavor == AppFlavor.prod
      ? l10n.aboutVersion(info.version, info.build)
      : l10n.aboutVersionFlavor(info.version, info.build, info.flavor.name);
}
