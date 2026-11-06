// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_identity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Who is signed in on the open profile (AC-005, D-097, A63 D11): its
/// local key and the stored name and email. `null` for a guest (a guest
/// never shows another profile's identity). Reads only this phone's
/// preferences (TD-115); nothing else reads them. Building also prunes the
/// identities of profiles the registry no longer has (A63 PA3), best
/// effort.

@ProviderFor(MeIdentity)
final meIdentityProvider = MeIdentityProvider._();

/// Who is signed in on the open profile (AC-005, D-097, A63 D11): its
/// local key and the stored name and email. `null` for a guest (a guest
/// never shows another profile's identity). Reads only this phone's
/// preferences (TD-115); nothing else reads them. Building also prunes the
/// identities of profiles the registry no longer has (A63 PA3), best
/// effort.
final class MeIdentityProvider
    extends
        $AsyncNotifierProvider<
          MeIdentity,
          ({LocalIdentity identity, String profileKey})?
        > {
  /// Who is signed in on the open profile (AC-005, D-097, A63 D11): its
  /// local key and the stored name and email. `null` for a guest (a guest
  /// never shows another profile's identity). Reads only this phone's
  /// preferences (TD-115); nothing else reads them. Building also prunes the
  /// identities of profiles the registry no longer has (A63 PA3), best
  /// effort.
  MeIdentityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meIdentityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meIdentityHash();

  @$internal
  @override
  MeIdentity create() => MeIdentity();
}

String _$meIdentityHash() => r'd725d0a74bb54d0e7d1cee0497921426d3f99863';

/// Who is signed in on the open profile (AC-005, D-097, A63 D11): its
/// local key and the stored name and email. `null` for a guest (a guest
/// never shows another profile's identity). Reads only this phone's
/// preferences (TD-115); nothing else reads them. Building also prunes the
/// identities of profiles the registry no longer has (A63 PA3), best
/// effort.

abstract class _$MeIdentity
    extends $AsyncNotifier<({LocalIdentity identity, String profileKey})?> {
  FutureOr<({LocalIdentity identity, String profileKey})?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<({LocalIdentity identity, String profileKey})?>,
              ({LocalIdentity identity, String profileKey})?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<({LocalIdentity identity, String profileKey})?>,
                ({LocalIdentity identity, String profileKey})?
              >,
              AsyncValue<({LocalIdentity identity, String profileKey})?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
