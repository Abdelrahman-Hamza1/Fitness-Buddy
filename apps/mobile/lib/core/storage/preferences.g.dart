// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Small key-value settings that are not user data: the device id and the
/// cached `/v1/config` (S06 plan D8, D9). User data lives in the database.
///
/// The async API reads the platform on demand, so creating it does no I/O
/// (UX-001). Tests override it with an in-memory store.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Small key-value settings that are not user data: the device id and the
/// cached `/v1/config` (S06 plan D8, D9). User data lives in the database.
///
/// The async API reads the platform on demand, so creating it does no I/O
/// (UX-001). Tests override it with an in-memory store.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferencesAsync,
          SharedPreferencesAsync,
          SharedPreferencesAsync
        >
    with $Provider<SharedPreferencesAsync> {
  /// Small key-value settings that are not user data: the device id and the
  /// cached `/v1/config` (S06 plan D8, D9). User data lives in the database.
  ///
  /// The async API reads the platform on demand, so creating it does no I/O
  /// (UX-001). Tests override it with an in-memory store.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferencesAsync> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferencesAsync create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferencesAsync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferencesAsync>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'4e2baac92647a5914c46b38ec3c662805cada4cb';
