// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auto-disposed when the picker closes; one catalog read per session.
// UX-051 presents the error immediately; the picker owns explicit retry.

@ProviderFor(citySearch)
final citySearchProvider = CitySearchProvider._();

/// Auto-disposed when the picker closes; one catalog read per session.
// UX-051 presents the error immediately; the picker owns explicit retry.

final class CitySearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<CitySearch>,
          CitySearch,
          FutureOr<CitySearch>
        >
    with $FutureModifier<CitySearch>, $FutureProvider<CitySearch> {
  /// Auto-disposed when the picker closes; one catalog read per session.
  // UX-051 presents the error immediately; the picker owns explicit retry.
  CitySearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noAutomaticRetry,
        name: r'citySearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$citySearchHash();

  @$internal
  @override
  $FutureProviderElement<CitySearch> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CitySearch> create(Ref ref) {
    return citySearch(ref);
  }
}

String _$citySearchHash() => r'91b8365e840e61f53b5ce829b6f16237fdc03a35';
