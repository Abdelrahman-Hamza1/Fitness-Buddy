// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_memory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everything Buddy remembers, newest first ("Buddy remembers", AI-082).

@ProviderFor(buddyMemoryItems)
final buddyMemoryItemsProvider = BuddyMemoryItemsProvider._();

/// Everything Buddy remembers, newest first ("Buddy remembers", AI-082).

final class BuddyMemoryItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemoryItem>>,
          List<MemoryItem>,
          Stream<List<MemoryItem>>
        >
    with $FutureModifier<List<MemoryItem>>, $StreamProvider<List<MemoryItem>> {
  /// Everything Buddy remembers, newest first ("Buddy remembers", AI-082).
  BuddyMemoryItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyMemoryItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyMemoryItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<MemoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MemoryItem>> create(Ref ref) {
    return buddyMemoryItems(ref);
  }
}

String _$buddyMemoryItemsHash() => r'f713e2938999981409288d3cb8791c696433503a';

/// The app's memory commands.

@ProviderFor(buddyMemoryActions)
final buddyMemoryActionsProvider = BuddyMemoryActionsProvider._();

/// The app's memory commands.

final class BuddyMemoryActionsProvider
    extends
        $FunctionalProvider<
          BuddyMemoryActions,
          BuddyMemoryActions,
          BuddyMemoryActions
        >
    with $Provider<BuddyMemoryActions> {
  /// The app's memory commands.
  BuddyMemoryActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyMemoryActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyMemoryActionsHash();

  @$internal
  @override
  $ProviderElement<BuddyMemoryActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BuddyMemoryActions create(Ref ref) {
    return buddyMemoryActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyMemoryActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyMemoryActions>(value),
    );
  }
}

String _$buddyMemoryActionsHash() =>
    r'b6806f1685c8c8fd0875c687254835185016a88f';
