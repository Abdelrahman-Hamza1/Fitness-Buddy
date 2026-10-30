// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Existing single-writer port, injectable for command-race tests.

@ProviderFor(diaryApply)
final diaryApplyProvider = DiaryApplyProvider._();

/// Existing single-writer port, injectable for command-race tests.

final class DiaryApplyProvider
    extends
        $FunctionalProvider<
          Future<ApplyResult> Function(ChangeSet),
          Future<ApplyResult> Function(ChangeSet),
          Future<ApplyResult> Function(ChangeSet)
        >
    with $Provider<Future<ApplyResult> Function(ChangeSet)> {
  /// Existing single-writer port, injectable for command-race tests.
  DiaryApplyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryApplyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryApplyHash();

  @$internal
  @override
  $ProviderElement<Future<ApplyResult> Function(ChangeSet)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<ApplyResult> Function(ChangeSet) create(Ref ref) {
    return diaryApply(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<ApplyResult> Function(ChangeSet) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<ApplyResult> Function(ChangeSet)>(value),
    );
  }
}

String _$diaryApplyHash() => r'c0df1c226b5aa8232a767cb4b417696ead432eb0';

/// Direct commands survive eviction of the originating day.

@ProviderFor(DiaryActionsController)
final diaryActionsControllerProvider = DiaryActionsControllerProvider._();

/// Direct commands survive eviction of the originating day.
final class DiaryActionsControllerProvider
    extends $NotifierProvider<DiaryActionsController, DiaryActionsState> {
  /// Direct commands survive eviction of the originating day.
  DiaryActionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryActionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryActionsControllerHash();

  @$internal
  @override
  DiaryActionsController create() => DiaryActionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryActionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryActionsState>(value),
    );
  }
}

String _$diaryActionsControllerHash() =>
    r'2ef1b475a4458a0348d3df0123bbbc7c18f5df84';

/// Direct commands survive eviction of the originating day.

abstract class _$DiaryActionsController extends $Notifier<DiaryActionsState> {
  DiaryActionsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DiaryActionsState, DiaryActionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryActionsState, DiaryActionsState>,
              DiaryActionsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
