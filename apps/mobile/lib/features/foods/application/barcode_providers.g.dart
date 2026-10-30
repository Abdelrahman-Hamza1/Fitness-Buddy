// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the scanner opens the camera (A28a D13). On in the app; widget
/// tests switch it off (no platform camera there) and type the code.

@ProviderFor(barcodeCameraEnabled)
final barcodeCameraEnabledProvider = BarcodeCameraEnabledProvider._();

/// Whether the scanner opens the camera (A28a D13). On in the app; widget
/// tests switch it off (no platform camera there) and type the code.

final class BarcodeCameraEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the scanner opens the camera (A28a D13). On in the app; widget
  /// tests switch it off (no platform camera there) and type the code.
  BarcodeCameraEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'barcodeCameraEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$barcodeCameraEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return barcodeCameraEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$barcodeCameraEnabledHash() =>
    r'3bedf1a553ebb4a2ad55cecbf376da6223dc2f69';

/// The registry for this app run.

@ProviderFor(scannedFoodRegistry)
final scannedFoodRegistryProvider = ScannedFoodRegistryProvider._();

/// The registry for this app run.

final class ScannedFoodRegistryProvider
    extends
        $FunctionalProvider<
          ScannedFoodRegistry,
          ScannedFoodRegistry,
          ScannedFoodRegistry
        >
    with $Provider<ScannedFoodRegistry> {
  /// The registry for this app run.
  ScannedFoodRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scannedFoodRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scannedFoodRegistryHash();

  @$internal
  @override
  $ProviderElement<ScannedFoodRegistry> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScannedFoodRegistry create(Ref ref) {
    return scannedFoodRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScannedFoodRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScannedFoodRegistry>(value),
    );
  }
}

String _$scannedFoodRegistryHash() =>
    r'98f65ee7124d9342ceb726756fd8c191e5ad2581';

/// The barcode chain over the app's repositories and the server.

@ProviderFor(barcodeLookup)
final barcodeLookupProvider = BarcodeLookupProvider._();

/// The barcode chain over the app's repositories and the server.

final class BarcodeLookupProvider
    extends $FunctionalProvider<BarcodeLookup, BarcodeLookup, BarcodeLookup>
    with $Provider<BarcodeLookup> {
  /// The barcode chain over the app's repositories and the server.
  BarcodeLookupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'barcodeLookupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$barcodeLookupHash();

  @$internal
  @override
  $ProviderElement<BarcodeLookup> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BarcodeLookup create(Ref ref) {
    return barcodeLookup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BarcodeLookup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BarcodeLookup>(value),
    );
  }
}

String _$barcodeLookupHash() => r'32caa7a45ce2f0495e8f0035e634fac2ab057e4c';

/// One-shot handoff of a scan's prefill to the new-food form (A28a D9);
/// like the search's name prefill, private data never enters a route.

@ProviderFor(ScanFoodPrefill)
final scanFoodPrefillProvider = ScanFoodPrefillProvider._();

/// One-shot handoff of a scan's prefill to the new-food form (A28a D9);
/// like the search's name prefill, private data never enters a route.
final class ScanFoodPrefillProvider
    extends $NotifierProvider<ScanFoodPrefill, ScanPrefill?> {
  /// One-shot handoff of a scan's prefill to the new-food form (A28a D9);
  /// like the search's name prefill, private data never enters a route.
  ScanFoodPrefillProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanFoodPrefillProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanFoodPrefillHash();

  @$internal
  @override
  ScanFoodPrefill create() => ScanFoodPrefill();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanPrefill? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanPrefill?>(value),
    );
  }
}

String _$scanFoodPrefillHash() => r'bc7b5597489348571cf76126c24eb9fb7a8ea890';

/// One-shot handoff of a scan's prefill to the new-food form (A28a D9);
/// like the search's name prefill, private data never enters a route.

abstract class _$ScanFoodPrefill extends $Notifier<ScanPrefill?> {
  ScanPrefill? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScanPrefill?, ScanPrefill?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScanPrefill?, ScanPrefill?>,
              ScanPrefill?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Scans waiting for a later lookup (A28a D10, OF-02): at most [maxScans],
/// dropped after [maxAge], one list per local profile (review fix 1: the
/// store follows profile switches; work started for an older profile never
/// writes into the new one). [process] looks the waiting ones up again; it
/// runs when the scanner opens, when the app comes back to the front and
/// after a successful lookup, never on the startup path. A scan leaves the
/// list only when it was logged, saved as your food, or dismissed (review
/// fix 3).

@ProviderFor(PendingScans)
final pendingScansProvider = PendingScansProvider._();

/// Scans waiting for a later lookup (A28a D10, OF-02): at most [maxScans],
/// dropped after [maxAge], one list per local profile (review fix 1: the
/// store follows profile switches; work started for an older profile never
/// writes into the new one). [process] looks the waiting ones up again; it
/// runs when the scanner opens, when the app comes back to the front and
/// after a successful lookup, never on the startup path. A scan leaves the
/// list only when it was logged, saved as your food, or dismissed (review
/// fix 3).
final class PendingScansProvider
    extends $AsyncNotifierProvider<PendingScans, List<PendingScan>> {
  /// Scans waiting for a later lookup (A28a D10, OF-02): at most [maxScans],
  /// dropped after [maxAge], one list per local profile (review fix 1: the
  /// store follows profile switches; work started for an older profile never
  /// writes into the new one). [process] looks the waiting ones up again; it
  /// runs when the scanner opens, when the app comes back to the front and
  /// after a successful lookup, never on the startup path. A scan leaves the
  /// list only when it was logged, saved as your food, or dismissed (review
  /// fix 3).
  PendingScansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingScansProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingScansHash();

  @$internal
  @override
  PendingScans create() => PendingScans();
}

String _$pendingScansHash() => r'8878e833b1193f7de3e982f47097378b142a9afc';

/// Scans waiting for a later lookup (A28a D10, OF-02): at most [maxScans],
/// dropped after [maxAge], one list per local profile (review fix 1: the
/// store follows profile switches; work started for an older profile never
/// writes into the new one). [process] looks the waiting ones up again; it
/// runs when the scanner opens, when the app comes back to the front and
/// after a successful lookup, never on the startup path. A scan leaves the
/// list only when it was logged, saved as your food, or dismissed (review
/// fix 3).

abstract class _$PendingScans extends $AsyncNotifier<List<PendingScan>> {
  FutureOr<List<PendingScan>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PendingScan>>, List<PendingScan>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PendingScan>>, List<PendingScan>>,
              AsyncValue<List<PendingScan>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
