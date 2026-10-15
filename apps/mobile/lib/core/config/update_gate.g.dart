// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the app must show the update screen instead of everything else
/// (S06 plan D10, A1): the server refused this version, or the config's
/// `minimumAppVersion` is above the installed version.
///
/// Fails open: a malformed version on either side, or a version not known
/// yet, never gates (A8). The router redirects on it.

@ProviderFor(updateRequired)
final updateRequiredProvider = UpdateRequiredProvider._();

/// Whether the app must show the update screen instead of everything else
/// (S06 plan D10, A1): the server refused this version, or the config's
/// `minimumAppVersion` is above the installed version.
///
/// Fails open: a malformed version on either side, or a version not known
/// yet, never gates (A8). The router redirects on it.

final class UpdateRequiredProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the app must show the update screen instead of everything else
  /// (S06 plan D10, A1): the server refused this version, or the config's
  /// `minimumAppVersion` is above the installed version.
  ///
  /// Fails open: a malformed version on either side, or a version not known
  /// yet, never gates (A8). The router redirects on it.
  UpdateRequiredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateRequiredProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateRequiredHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return updateRequired(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$updateRequiredHash() => r'0b02ba259bfbdfeeebfe4547884db159fb7dd80d';
