// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_summary_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The summary repository of the open profile.

@ProviderFor(buddySummaryRepository)
final buddySummaryRepositoryProvider = BuddySummaryRepositoryProvider._();

/// The summary repository of the open profile.

final class BuddySummaryRepositoryProvider
    extends
        $FunctionalProvider<
          BuddySummaryRepository,
          BuddySummaryRepository,
          BuddySummaryRepository
        >
    with $Provider<BuddySummaryRepository> {
  /// The summary repository of the open profile.
  BuddySummaryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddySummaryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddySummaryRepositoryHash();

  @$internal
  @override
  $ProviderElement<BuddySummaryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BuddySummaryRepository create(Ref ref) {
    return buddySummaryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddySummaryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddySummaryRepository>(value),
    );
  }
}

String _$buddySummaryRepositoryHash() =>
    r'9c9b2e10cbe227f8162dc185620b263075d1bd0c';
