import 'package:fb_mobile/core/config/app_version.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_gate.g.dart';

/// Whether the app must show the update screen instead of everything else
/// (S06 plan D10, A1): the server refused this version, or the config's
/// `minimumAppVersion` is above the installed version.
///
/// Fails open: a malformed version on either side, or a version not known
/// yet, never gates (A8). The router redirects on it.
@Riverpod(keepAlive: true)
bool updateRequired(Ref ref) {
  // The config first: it is alive whenever the gate is, so it sees the
  // signal trip and refreshes.
  final minimum = ref.watch(clientConfigProvider).minimumAppVersion;
  if (ref.watch(upgradeSignalProvider)) return true;
  final parsed = AppVersion.tryParse(minimum);
  // 0.0.0 (the default) can't gate any version: don't read the package info
  // for it, which keeps that platform call off the first frame (UX-001).
  if (parsed == null || parsed == AppVersion.zero) return false;
  final installed = ref.watch(packageInfoProvider).value?.version;
  return installed != null &&
      AppVersion.isBelowMinimum(installed: installed, minimum: minimum);
}
