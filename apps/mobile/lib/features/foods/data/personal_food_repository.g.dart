// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_food_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only repository composition stays in data (application-db rule).

@ProviderFor(personalFoodRepository)
final personalFoodRepositoryProvider = PersonalFoodRepositoryProvider._();

/// Read-only repository composition stays in data (application-db rule).

final class PersonalFoodRepositoryProvider
    extends
        $FunctionalProvider<
          PersonalFoodRepository,
          PersonalFoodRepository,
          PersonalFoodRepository
        >
    with $Provider<PersonalFoodRepository> {
  /// Read-only repository composition stays in data (application-db rule).
  PersonalFoodRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalFoodRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalFoodRepositoryHash();

  @$internal
  @override
  $ProviderElement<PersonalFoodRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PersonalFoodRepository create(Ref ref) {
    return personalFoodRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonalFoodRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonalFoodRepository>(value),
    );
  }
}

String _$personalFoodRepositoryHash() =>
    r'd62cc9c7fc88bc1d984e431a2a83535b903cdc50';
