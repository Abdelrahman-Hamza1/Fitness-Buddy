// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_navigator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [AppNavigator]. `main` overrides it with the router
/// (`lib/app/app_scope.dart`); tests may override it with a fake.

@ProviderFor(appNavigator)
final appNavigatorProvider = AppNavigatorProvider._();

/// The app's [AppNavigator]. `main` overrides it with the router
/// (`lib/app/app_scope.dart`); tests may override it with a fake.

final class AppNavigatorProvider
    extends $FunctionalProvider<AppNavigator, AppNavigator, AppNavigator>
    with $Provider<AppNavigator> {
  /// The app's [AppNavigator]. `main` overrides it with the router
  /// (`lib/app/app_scope.dart`); tests may override it with a fake.
  AppNavigatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appNavigatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appNavigatorHash();

  @$internal
  @override
  $ProviderElement<AppNavigator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppNavigator create(Ref ref) {
    return appNavigator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppNavigator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppNavigator>(value),
    );
  }
}

String _$appNavigatorHash() => r'469a34fbc0a395d9e49e79c89685e47ddb1f67f4';
