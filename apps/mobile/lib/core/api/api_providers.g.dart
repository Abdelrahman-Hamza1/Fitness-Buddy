// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The HTTP transport under [dio]: the platform's client. Tests override it
/// with a fake adapter. Creating it opens no connection.

@ProviderFor(httpClientAdapter)
final httpClientAdapterProvider = HttpClientAdapterProvider._();

/// The HTTP transport under [dio]: the platform's client. Tests override it
/// with a fake adapter. Creating it opens no connection.

final class HttpClientAdapterProvider
    extends
        $FunctionalProvider<
          HttpClientAdapter,
          HttpClientAdapter,
          HttpClientAdapter
        >
    with $Provider<HttpClientAdapter> {
  /// The HTTP transport under [dio]: the platform's client. Tests override it
  /// with a fake adapter. Creating it opens no connection.
  HttpClientAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpClientAdapterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpClientAdapterHash();

  @$internal
  @override
  $ProviderElement<HttpClientAdapter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HttpClientAdapter create(Ref ref) {
    return httpClientAdapter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HttpClientAdapter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HttpClientAdapter>(value),
    );
  }
}

String _$httpClientAdapterHash() => r'd6d7d82a45dac968f5737b7d9b7b6bcd8e8096df';

/// The [Dio] every API call goes through (S06 plan D8, A1): the flavor's
/// base URL, the timeouts, the client headers and the upgrade signal.
///
/// Only `core/` and `data/` folders use it; screens never do (A3).

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// The [Dio] every API call goes through (S06 plan D8, A1): the flavor's
/// base URL, the timeouts, the client headers and the upgrade signal.
///
/// Only `core/` and `data/` folders use it; screens never do (A3).

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// The [Dio] every API call goes through (S06 plan D8, A1): the flavor's
  /// base URL, the timeouts, the client headers and the upgrade signal.
  ///
  /// Only `core/` and `data/` folders use it; screens never do (A3).
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'5e9c3fc11f1f3812cd43402d2220be03e87f063b';

/// The generated API client (`fb_api_client`) on [dio].

@ProviderFor(fbApi)
final fbApiProvider = FbApiProvider._();

/// The generated API client (`fb_api_client`) on [dio].

final class FbApiProvider extends $FunctionalProvider<FbApi, FbApi, FbApi>
    with $Provider<FbApi> {
  /// The generated API client (`fb_api_client`) on [dio].
  FbApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fbApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fbApiHash();

  @$internal
  @override
  $ProviderElement<FbApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FbApi create(Ref ref) {
    return fbApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FbApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FbApi>(value),
    );
  }
}

String _$fbApiHash() => r'3aee1d1a1658447417171b7113408088ab0274a0';
