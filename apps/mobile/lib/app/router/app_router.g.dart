// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's single [AppRouter]; also serves as the [AppNavigator]
/// (`lib/app/app_scope.dart`). Follows [updateRequiredProvider].

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// The app's single [AppRouter]; also serves as the [AppNavigator]
/// (`lib/app/app_scope.dart`). Follows [updateRequiredProvider].

final class AppRouterProvider
    extends $FunctionalProvider<AppRouter, AppRouter, AppRouter>
    with $Provider<AppRouter> {
  /// The app's single [AppRouter]; also serves as the [AppNavigator]
  /// (`lib/app/app_scope.dart`). Follows [updateRequiredProvider].
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<AppRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppRouter>(value),
    );
  }
}

String _$appRouterHash() => r'51ee6e20ececd49fec60f054bd7472d18860c0d0';
