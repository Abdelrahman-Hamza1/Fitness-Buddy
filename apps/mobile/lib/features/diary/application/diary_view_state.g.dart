// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_view_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns expansion for the app session.

@ProviderFor(DiaryViewState)
final diaryViewStateProvider = DiaryViewStateProvider._();

/// Owns expansion for the app session.
final class DiaryViewStateProvider
    extends $NotifierProvider<DiaryViewState, DiaryViewChoices> {
  /// Owns expansion for the app session.
  DiaryViewStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryViewStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryViewStateHash();

  @$internal
  @override
  DiaryViewState create() => DiaryViewState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryViewChoices value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryViewChoices>(value),
    );
  }
}

String _$diaryViewStateHash() => r'1585643142e3989d1f686791667694aea4f63d17';

/// Owns expansion for the app session.

abstract class _$DiaryViewState extends $Notifier<DiaryViewChoices> {
  DiaryViewChoices build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DiaryViewChoices, DiaryViewChoices>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryViewChoices, DiaryViewChoices>,
              DiaryViewChoices,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
