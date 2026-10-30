// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The template editor (WO-020, A37 D17): name, lines of sets × reps
/// exercises (time and cardio can't be lines), Save and Delete as direct
/// actions with undo.

@ProviderFor(TemplateEditor)
final templateEditorProvider = TemplateEditorFamily._();

/// The template editor (WO-020, A37 D17): name, lines of sets × reps
/// exercises (time and cardio can't be lines), Save and Delete as direct
/// actions with undo.
final class TemplateEditorProvider
    extends $AsyncNotifierProvider<TemplateEditor, TemplateEditorState> {
  /// The template editor (WO-020, A37 D17): name, lines of sets × reps
  /// exercises (time and cardio can't be lines), Save and Delete as direct
  /// actions with undo.
  TemplateEditorProvider._({
    required TemplateEditorFamily super.from,
    required TemplateEditorKey super.argument,
  }) : super(
         retry: null,
         name: r'templateEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$templateEditorHash();

  @override
  String toString() {
    return r'templateEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TemplateEditor create() => TemplateEditor();

  @override
  bool operator ==(Object other) {
    return other is TemplateEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$templateEditorHash() => r'e08c7fd6ca4117852eee84479ac0a677d354d825';

/// The template editor (WO-020, A37 D17): name, lines of sets × reps
/// exercises (time and cardio can't be lines), Save and Delete as direct
/// actions with undo.

final class TemplateEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          TemplateEditor,
          AsyncValue<TemplateEditorState>,
          TemplateEditorState,
          FutureOr<TemplateEditorState>,
          TemplateEditorKey
        > {
  TemplateEditorFamily._()
    : super(
        retry: null,
        name: r'templateEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The template editor (WO-020, A37 D17): name, lines of sets × reps
  /// exercises (time and cardio can't be lines), Save and Delete as direct
  /// actions with undo.

  TemplateEditorProvider call(TemplateEditorKey key) =>
      TemplateEditorProvider._(argument: key, from: this);

  @override
  String toString() => r'templateEditorProvider';
}

/// The template editor (WO-020, A37 D17): name, lines of sets × reps
/// exercises (time and cardio can't be lines), Save and Delete as direct
/// actions with undo.

abstract class _$TemplateEditor extends $AsyncNotifier<TemplateEditorState> {
  late final _$args = ref.$arg as TemplateEditorKey;
  TemplateEditorKey get key => _$args;

  FutureOr<TemplateEditorState> build(TemplateEditorKey key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TemplateEditorState>, TemplateEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TemplateEditorState>, TemplateEditorState>,
              AsyncValue<TemplateEditorState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
