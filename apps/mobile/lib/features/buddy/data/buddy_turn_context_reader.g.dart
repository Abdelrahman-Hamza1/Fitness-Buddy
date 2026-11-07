// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_context_reader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The turn context reader of the open profile.

@ProviderFor(buddyTurnContextReader)
final buddyTurnContextReaderProvider = BuddyTurnContextReaderProvider._();

/// The turn context reader of the open profile.

final class BuddyTurnContextReaderProvider
    extends
        $FunctionalProvider<
          BuddyTurnContextReader,
          BuddyTurnContextReader,
          BuddyTurnContextReader
        >
    with $Provider<BuddyTurnContextReader> {
  /// The turn context reader of the open profile.
  BuddyTurnContextReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyTurnContextReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyTurnContextReaderHash();

  @$internal
  @override
  $ProviderElement<BuddyTurnContextReader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BuddyTurnContextReader create(Ref ref) {
    return buddyTurnContextReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyTurnContextReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyTurnContextReader>(value),
    );
  }
}

String _$buddyTurnContextReaderHash() =>
    r'280cedbfd3bb9986d021e975d713f0279a13f327';
