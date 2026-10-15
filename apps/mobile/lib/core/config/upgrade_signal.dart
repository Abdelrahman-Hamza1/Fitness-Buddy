import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upgrade_signal.g.dart';

/// Set when the server answers that this version is too old (any 426 or
/// `/errors/upgrade-required`, S06 plan A1). Session only: never persisted;
/// the cached `minimumAppVersion` carries the gate to the next start.
///
/// Free of other app imports on purpose: `core/api` trips it and
/// `core/config` reacts to it (the config refreshes when it trips), so
/// there is no file or provider cycle between the two: `core/api` only
/// trips this dependency-free signal and `core/config` listens.
@Riverpod(keepAlive: true)
class UpgradeSignal extends _$UpgradeSignal {
  @override
  bool build() => false;

  /// The server refused this version.
  void trip() => state = true;

  /// A fresh config was fetched after the user asked to check again; the
  /// minimum-version half of `updateRequired` decides from now on.
  void clear() => state = false;
}
