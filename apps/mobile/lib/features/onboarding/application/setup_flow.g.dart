// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setup_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The question screens' view model (D9/D10, A51): opens on the stored
/// preferences, keeps every answer in memory, moves along the run's
/// [SetupDraft.pages] and saves once through
/// [TargetsActions.completeSetup]. Disposed with the screen.

@ProviderFor(SetupFlow)
final setupFlowProvider = SetupFlowFamily._();

/// The question screens' view model (D9/D10, A51): opens on the stored
/// preferences, keeps every answer in memory, moves along the run's
/// [SetupDraft.pages] and saves once through
/// [TargetsActions.completeSetup]. Disposed with the screen.
final class SetupFlowProvider
    extends $AsyncNotifierProvider<SetupFlow, SetupDraft> {
  /// The question screens' view model (D9/D10, A51): opens on the stored
  /// preferences, keeps every answer in memory, moves along the run's
  /// [SetupDraft.pages] and saves once through
  /// [TargetsActions.completeSetup]. Disposed with the screen.
  SetupFlowProvider._({
    required SetupFlowFamily super.from,
    required SetupMode super.argument,
  }) : super(
         retry: null,
         name: r'setupFlowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$setupFlowHash();

  @override
  String toString() {
    return r'setupFlowProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SetupFlow create() => SetupFlow();

  @override
  bool operator ==(Object other) {
    return other is SetupFlowProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$setupFlowHash() => r'723096db52201c9cc6a389a9fb9afea694dc027d';

/// The question screens' view model (D9/D10, A51): opens on the stored
/// preferences, keeps every answer in memory, moves along the run's
/// [SetupDraft.pages] and saves once through
/// [TargetsActions.completeSetup]. Disposed with the screen.

final class SetupFlowFamily extends $Family
    with
        $ClassFamilyOverride<
          SetupFlow,
          AsyncValue<SetupDraft>,
          SetupDraft,
          FutureOr<SetupDraft>,
          SetupMode
        > {
  SetupFlowFamily._()
    : super(
        retry: null,
        name: r'setupFlowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The question screens' view model (D9/D10, A51): opens on the stored
  /// preferences, keeps every answer in memory, moves along the run's
  /// [SetupDraft.pages] and saves once through
  /// [TargetsActions.completeSetup]. Disposed with the screen.

  SetupFlowProvider call(SetupMode mode) =>
      SetupFlowProvider._(argument: mode, from: this);

  @override
  String toString() => r'setupFlowProvider';
}

/// The question screens' view model (D9/D10, A51): opens on the stored
/// preferences, keeps every answer in memory, moves along the run's
/// [SetupDraft.pages] and saves once through
/// [TargetsActions.completeSetup]. Disposed with the screen.

abstract class _$SetupFlow extends $AsyncNotifier<SetupDraft> {
  late final _$args = ref.$arg as SetupMode;
  SetupMode get mode => _$args;

  FutureOr<SetupDraft> build(SetupMode mode);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SetupDraft>, SetupDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SetupDraft>, SetupDraft>,
              AsyncValue<SetupDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
