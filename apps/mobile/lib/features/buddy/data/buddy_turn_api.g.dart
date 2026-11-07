// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's turn routes on the app dio.

@ProviderFor(buddyTurnApi)
final buddyTurnApiProvider = BuddyTurnApiProvider._();

/// The app's turn routes on the app dio.

final class BuddyTurnApiProvider
    extends $FunctionalProvider<BuddyTurnApi, BuddyTurnApi, BuddyTurnApi>
    with $Provider<BuddyTurnApi> {
  /// The app's turn routes on the app dio.
  BuddyTurnApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyTurnApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyTurnApiHash();

  @$internal
  @override
  $ProviderElement<BuddyTurnApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BuddyTurnApi create(Ref ref) {
    return buddyTurnApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyTurnApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyTurnApi>(value),
    );
  }
}

String _$buddyTurnApiHash() => r'bb8bbe27d4250befc5e9f719053714e7f42cf6be';
