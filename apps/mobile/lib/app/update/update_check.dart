import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/config/update_gate.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_check.g.dart';

/// Where the update screen's "Check again" stands.
enum UpdateCheckStatus {
  /// No check yet.
  idle,

  /// A check is running.
  checking,

  /// The last check reached the server, and this version is still too old.
  stillOld,

  /// The last check couldn't reach the server (offline, timeout, error).
  failed,
}

/// View model of the update screen's "Check again" (S06 plan D10, A1).
@riverpod
class UpdateCheck extends _$UpdateCheck {
  @override
  UpdateCheckStatus build() => UpdateCheckStatus.idle;

  /// Fetches a fresh config. When it arrives, the 426 signal is cleared and
  /// the fresh `minimumAppVersion` decides: if this version is allowed, the
  /// gate lifts and the router leaves the update screen; otherwise the
  /// status is [UpdateCheckStatus.stillOld]. Offline, the gate stays and the
  /// status is [UpdateCheckStatus.failed].
  Future<void> checkAgain() async {
    if (state == UpdateCheckStatus.checking) return;
    state = UpdateCheckStatus.checking;
    var result = UpdateCheckStatus.failed;
    try {
      final fresh = await ref.read(clientConfigProvider.notifier).refresh();
      if (fresh && ref.mounted) {
        ref.read(upgradeSignalProvider.notifier).clear();
        result = ref.read(updateRequiredProvider)
            ? UpdateCheckStatus.stillOld
            : UpdateCheckStatus.idle;
      }
    } finally {
      if (ref.mounted) state = result;
    }
  }
}
