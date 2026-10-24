// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_food_form.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Disposable per-form state; only submit calls the application commands.
/// Each open form passes its own [PersonalFoodFormKey].

@ProviderFor(PersonalFoodFormController)
final personalFoodFormControllerProvider = PersonalFoodFormControllerFamily._();

/// Disposable per-form state; only submit calls the application commands.
/// Each open form passes its own [PersonalFoodFormKey].
final class PersonalFoodFormControllerProvider
    extends
        $AsyncNotifierProvider<
          PersonalFoodFormController,
          PersonalFoodFormState
        > {
  /// Disposable per-form state; only submit calls the application commands.
  /// Each open form passes its own [PersonalFoodFormKey].
  PersonalFoodFormControllerProvider._({
    required PersonalFoodFormControllerFamily super.from,
    required PersonalFoodFormKey super.argument,
  }) : super(
         retry: null,
         name: r'personalFoodFormControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personalFoodFormControllerHash();

  @override
  String toString() {
    return r'personalFoodFormControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PersonalFoodFormController create() => PersonalFoodFormController();

  @override
  bool operator ==(Object other) {
    return other is PersonalFoodFormControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personalFoodFormControllerHash() =>
    r'aaf90e5a09b4efc4f3a97b33bc8838502fc1f202';

/// Disposable per-form state; only submit calls the application commands.
/// Each open form passes its own [PersonalFoodFormKey].

final class PersonalFoodFormControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PersonalFoodFormController,
          AsyncValue<PersonalFoodFormState>,
          PersonalFoodFormState,
          FutureOr<PersonalFoodFormState>,
          PersonalFoodFormKey
        > {
  PersonalFoodFormControllerFamily._()
    : super(
        retry: null,
        name: r'personalFoodFormControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Disposable per-form state; only submit calls the application commands.
  /// Each open form passes its own [PersonalFoodFormKey].

  PersonalFoodFormControllerProvider call(PersonalFoodFormKey key) =>
      PersonalFoodFormControllerProvider._(argument: key, from: this);

  @override
  String toString() => r'personalFoodFormControllerProvider';
}

/// Disposable per-form state; only submit calls the application commands.
/// Each open form passes its own [PersonalFoodFormKey].

abstract class _$PersonalFoodFormController
    extends $AsyncNotifier<PersonalFoodFormState> {
  late final _$args = ref.$arg as PersonalFoodFormKey;
  PersonalFoodFormKey get key => _$args;

  FutureOr<PersonalFoodFormState> build(PersonalFoodFormKey key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PersonalFoodFormState>, PersonalFoodFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PersonalFoodFormState>,
                PersonalFoodFormState
              >,
              AsyncValue<PersonalFoodFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
