// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's interpret endpoint on the app dio.

@ProviderFor(buddyApi)
final buddyApiProvider = BuddyApiProvider._();

/// The app's interpret endpoint on the app dio.

final class BuddyApiProvider
    extends $FunctionalProvider<BuddyApi, BuddyApi, BuddyApi>
    with $Provider<BuddyApi> {
  /// The app's interpret endpoint on the app dio.
  BuddyApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyApiHash();

  @$internal
  @override
  $ProviderElement<BuddyApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BuddyApi create(Ref ref) {
    return buddyApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyApi>(value),
    );
  }
}

String _$buddyApiHash() => r'09e701fd2001453c96e05a64972f3e505bd19c91';
