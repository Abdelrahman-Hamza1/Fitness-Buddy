// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_bootstrap.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [AppBootstrap].

@ProviderFor(appBootstrap)
final appBootstrapProvider = AppBootstrapProvider._();

/// The app's [AppBootstrap].

final class AppBootstrapProvider
    extends $FunctionalProvider<AppBootstrap, AppBootstrap, AppBootstrap>
    with $Provider<AppBootstrap> {
  /// The app's [AppBootstrap].
  AppBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appBootstrapHash();

  @$internal
  @override
  $ProviderElement<AppBootstrap> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppBootstrap create(Ref ref) {
    return appBootstrap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppBootstrap value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppBootstrap>(value),
    );
  }
}

String _$appBootstrapHash() => r'49b6afa527a2ce4d96f88acafd5139005c97b86e';
