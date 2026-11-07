// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_answers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Buddy's phone tools with the QueryEngine behind `queryData` (A68 D4).

@ProviderFor(buddyPhoneTools)
final buddyPhoneToolsProvider = BuddyPhoneToolsProvider._();

/// Buddy's phone tools with the QueryEngine behind `queryData` (A68 D4).

final class BuddyPhoneToolsProvider
    extends $FunctionalProvider<PhoneTools, PhoneTools, PhoneTools>
    with $Provider<PhoneTools> {
  /// Buddy's phone tools with the QueryEngine behind `queryData` (A68 D4).
  BuddyPhoneToolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyPhoneToolsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyPhoneToolsHash();

  @$internal
  @override
  $ProviderElement<PhoneTools> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhoneTools create(Ref ref) {
    return buddyPhoneTools(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneTools value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneTools>(value),
    );
  }
}

String _$buddyPhoneToolsHash() => r'078004f10d30ea962511f160358c74f4899839f1';
