// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_generation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bumped on every profile switch (A33 re-check 3), before the new profile
/// opens: appliers, commands and the app's widget tree created for an older
/// generation are stale, and the write gate rejects their writes.

@ProviderFor(ProfileGeneration)
final profileGenerationProvider = ProfileGenerationProvider._();

/// Bumped on every profile switch (A33 re-check 3), before the new profile
/// opens: appliers, commands and the app's widget tree created for an older
/// generation are stale, and the write gate rejects their writes.
final class ProfileGenerationProvider
    extends $NotifierProvider<ProfileGeneration, int> {
  /// Bumped on every profile switch (A33 re-check 3), before the new profile
  /// opens: appliers, commands and the app's widget tree created for an older
  /// generation are stale, and the write gate rejects their writes.
  ProfileGenerationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileGenerationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileGenerationHash();

  @$internal
  @override
  ProfileGeneration create() => ProfileGeneration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$profileGenerationHash() => r'16315f8e32e293cc0383adea225cffa8120fd821';

/// Bumped on every profile switch (A33 re-check 3), before the new profile
/// opens: appliers, commands and the app's widget tree created for an older
/// generation are stale, and the write gate rejects their writes.

abstract class _$ProfileGeneration extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
