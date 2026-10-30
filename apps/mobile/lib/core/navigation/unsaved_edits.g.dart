// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unsaved_edits.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's one [UnsavedEdits] registry.

@ProviderFor(unsavedEdits)
final unsavedEditsProvider = UnsavedEditsProvider._();

/// The app's one [UnsavedEdits] registry.

final class UnsavedEditsProvider
    extends $FunctionalProvider<UnsavedEdits, UnsavedEdits, UnsavedEdits>
    with $Provider<UnsavedEdits> {
  /// The app's one [UnsavedEdits] registry.
  UnsavedEditsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unsavedEditsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unsavedEditsHash();

  @$internal
  @override
  $ProviderElement<UnsavedEdits> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UnsavedEdits create(Ref ref) {
    return unsavedEdits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnsavedEdits value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnsavedEdits>(value),
    );
  }
}

String _$unsavedEditsHash() => r'8917fc9761aa4aa16fd68b6b0d40b482a81fd3cb';
