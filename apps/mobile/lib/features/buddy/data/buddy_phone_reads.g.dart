// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_phone_reads.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The phone-tool reads of the open profile.

@ProviderFor(buddyPhoneReads)
final buddyPhoneReadsProvider = BuddyPhoneReadsProvider._();

/// The phone-tool reads of the open profile.

final class BuddyPhoneReadsProvider
    extends
        $FunctionalProvider<BuddyPhoneReads, BuddyPhoneReads, BuddyPhoneReads>
    with $Provider<BuddyPhoneReads> {
  /// The phone-tool reads of the open profile.
  BuddyPhoneReadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyPhoneReadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyPhoneReadsHash();

  @$internal
  @override
  $ProviderElement<BuddyPhoneReads> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BuddyPhoneReads create(Ref ref) {
    return buddyPhoneReads(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyPhoneReads value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyPhoneReads>(value),
    );
  }
}

String _$buddyPhoneReadsHash() => r'1bd85a3998b865d8e994a328cd11afebc887858c';
