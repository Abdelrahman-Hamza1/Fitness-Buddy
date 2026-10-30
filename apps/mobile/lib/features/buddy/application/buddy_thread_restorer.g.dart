// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_thread_restorer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's restorer (per profile: its repositories watch the database).

@ProviderFor(buddyThreadRestorer)
final buddyThreadRestorerProvider = BuddyThreadRestorerProvider._();

/// The app's restorer (per profile: its repositories watch the database).

final class BuddyThreadRestorerProvider
    extends
        $FunctionalProvider<
          BuddyThreadRestorer,
          BuddyThreadRestorer,
          BuddyThreadRestorer
        >
    with $Provider<BuddyThreadRestorer> {
  /// The app's restorer (per profile: its repositories watch the database).
  BuddyThreadRestorerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyThreadRestorerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyThreadRestorerHash();

  @$internal
  @override
  $ProviderElement<BuddyThreadRestorer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BuddyThreadRestorer create(Ref ref) {
    return buddyThreadRestorer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyThreadRestorer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyThreadRestorer>(value),
    );
  }
}

String _$buddyThreadRestorerHash() =>
    r'5d4c3b88435a6b523ddb2fe3780aa8b814347342';
