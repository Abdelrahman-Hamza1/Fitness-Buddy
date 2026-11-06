import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/catalog/barcode_coverage.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/ui/settings_page.dart';
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
        padding: SettingsPage.padding,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
              vertical: FbSpace.s2,
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
                      // A 48 dp target for the hidden gesture (UX-071,
                      // audit minor).
                      child: ConstrainedBox(
                        key: const ValueKey('about-version'),
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: FbSpace.s7,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: value == null
                              ? Text(l10n.aboutInfoUnavailable, style: muted)
                              : Text(_version(l10n, value), style: muted),
                        ),
                      ),
                    ),
                  ),
                  if (value?.packVersion case final pack?)
                    Text(l10n.aboutFoodDataVersion(pack), style: muted),
                ],
              ],
            ),
          ),
          // One settings-page layout (A65 M4): credits, the licences and
          // privacy rows with the medical note, How it works (A65 m3,
          // UX-010, UX-044) and this phone's barcode numbers (TD-064).
          FbRowGroup(
            title: l10n.aboutCreditsTitle,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.all(FbSpace.s4),
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
                    // Barcode lookups show Open Food Facts data (ODbL, `07`
                    // §3).
                    Text(
                      l10n.aboutCredit(l10n.aboutOffName, l10n.aboutOffCredit),
                      style: FbType.body.copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
          settingsGroupGap,
          FbRowGroup(
            note: l10n.aboutNotMedical,
            children: [
              FbListRow(
                leading: const Icon(FbIcons.info),
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
              // A28a review fix 8: what the barcode scanner's ML Kit may
              // send, now one tap away (A65 m3).
              FbListRow(
                key: const ValueKey('about-privacy'),
                leading: const Icon(FbIcons.privacy),
                title: l10n.aboutPrivacy,
                subtitle: l10n.aboutPrivacyHint,
                trailing: const Icon(FbIcons.next),
                onTap: () => unawaited(
                  showFbSheet<void>(
                    context,
                    title: l10n.aboutPrivacy,
                    builder: (sheet) => Text(
                      l10n.aboutMlKitDisclosure,
                      key: const ValueKey('about-ml-kit'),
                      style: FbType.body.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ],
          ),
          FbRowGroup(
            key: const ValueKey('about-how'),
            title: l10n.aboutHowTitle,
            children: [
              FbListRow(
                key: const ValueKey('about-how-sources'),
                leading: const Icon(FbIcons.help),
                title: l10n.aboutHowSources,
                subtitle: l10n.aboutHowSourcesHint,
                trailing: const Icon(FbIcons.next),
                onTap: () => unawaited(showFbSourceLegend(context)),
              ),
              FbListRow(
                leading: const Icon(FbIcons.check),
                title: l10n.aboutHowUndo,
                subtitle: l10n.aboutHowUndoHint,
              ),
              FbListRow(
                leading: const Icon(FbIcons.info),
                title: l10n.aboutHowEstimates,
                subtitle: l10n.aboutHowEstimatesHint,
              ),
            ],
          ),
          // TD-064: the real barcode hit rate from daily use, on this phone.
          if (ref.watch(barcodeCoverageCountsProvider).value case final c?) ...[
            settingsGroupGap,
            FbRowGroup(
              children: [
                FbListRow(
                  key: const ValueKey('about-barcode-coverage'),
                  leading: const Icon(FbIcons.barcode),
                  title: l10n.aboutBarcodeTitle,
                  subtitle: l10n.aboutBarcodeCoverage(
                    c.found,
                    c.incomplete,
                    c.notFound,
                  ),
                ),
              ],
            ),
          ],
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
