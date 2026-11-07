// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_facts_loader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's record facts loader.

@ProviderFor(recordFactsLoader)
final recordFactsLoaderProvider = RecordFactsLoaderProvider._();

/// The app's record facts loader.

final class RecordFactsLoaderProvider
    extends
        $FunctionalProvider<
          RecordFactsLoader,
          RecordFactsLoader,
          RecordFactsLoader
        >
    with $Provider<RecordFactsLoader> {
  /// The app's record facts loader.
  RecordFactsLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordFactsLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordFactsLoaderHash();

  @$internal
  @override
  $ProviderElement<RecordFactsLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecordFactsLoader create(Ref ref) {
    return recordFactsLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordFactsLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordFactsLoader>(value),
    );
  }
}

String _$recordFactsLoaderHash() => r'fdddd7ebd14ec6af51f67108f8057d61fe3ab49b';
