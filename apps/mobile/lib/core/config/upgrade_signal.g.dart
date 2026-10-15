// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upgrade_signal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Set when the server answers that this version is too old (any 426 or
/// `/errors/upgrade-required`, S06 plan A1). Session only: never persisted;
/// the cached `minimumAppVersion` carries the gate to the next start.
///
/// Free of other app imports on purpose: `core/api` trips it and
/// `core/config` reacts to it (the config refreshes when it trips), so
/// there is no file or provider cycle between the two: `core/api` only
/// trips this dependency-free signal and `core/config` listens.

@ProviderFor(UpgradeSignal)
final upgradeSignalProvider = UpgradeSignalProvider._();

/// Set when the server answers that this version is too old (any 426 or
/// `/errors/upgrade-required`, S06 plan A1). Session only: never persisted;
/// the cached `minimumAppVersion` carries the gate to the next start.
///
/// Free of other app imports on purpose: `core/api` trips it and
/// `core/config` reacts to it (the config refreshes when it trips), so
/// there is no file or provider cycle between the two: `core/api` only
/// trips this dependency-free signal and `core/config` listens.
final class UpgradeSignalProvider
    extends $NotifierProvider<UpgradeSignal, bool> {
  /// Set when the server answers that this version is too old (any 426 or
  /// `/errors/upgrade-required`, S06 plan A1). Session only: never persisted;
  /// the cached `minimumAppVersion` carries the gate to the next start.
  ///
  /// Free of other app imports on purpose: `core/api` trips it and
  /// `core/config` reacts to it (the config refreshes when it trips), so
  /// there is no file or provider cycle between the two: `core/api` only
  /// trips this dependency-free signal and `core/config` listens.
  UpgradeSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upgradeSignalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upgradeSignalHash();

  @$internal
  @override
  UpgradeSignal create() => UpgradeSignal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$upgradeSignalHash() => r'6a2dd3c2c84be1d020b47b449805efdddd303730';

/// Set when the server answers that this version is too old (any 426 or
/// `/errors/upgrade-required`, S06 plan A1). Session only: never persisted;
/// the cached `minimumAppVersion` carries the gate to the next start.
///
/// Free of other app imports on purpose: `core/api` trips it and
/// `core/config` reacts to it (the config refreshes when it trips), so
/// there is no file or provider cycle between the two: `core/api` only
/// trips this dependency-free signal and `core/config` listens.

abstract class _$UpgradeSignal extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
