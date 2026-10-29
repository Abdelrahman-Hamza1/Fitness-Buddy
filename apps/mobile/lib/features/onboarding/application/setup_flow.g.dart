// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setup_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The setup flow's view model (D9/D10): opens on the stored preferences,
/// keeps every page's input in memory, moves between pages and saves once
/// through [TargetsActions.completeSetup]. Disposed with the setup screen.

@ProviderFor(SetupFlow)
final setupFlowProvider = SetupFlowProvider._();

/// The setup flow's view model (D9/D10): opens on the stored preferences,
/// keeps every page's input in memory, moves between pages and saves once
/// through [TargetsActions.completeSetup]. Disposed with the setup screen.
final class SetupFlowProvider
    extends $AsyncNotifierProvider<SetupFlow, SetupDraft> {
  /// The setup flow's view model (D9/D10): opens on the stored preferences,
  /// keeps every page's input in memory, moves between pages and saves once
  /// through [TargetsActions.completeSetup]. Disposed with the setup screen.
  SetupFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setupFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setupFlowHash();

  @$internal
  @override
  SetupFlow create() => SetupFlow();
}

String _$setupFlowHash() => r'df70f40186efe35c3324bbb563454a445bd67ad6';

/// The setup flow's view model (D9/D10): opens on the stored preferences,
/// keeps every page's input in memory, moves between pages and saves once
/// through [TargetsActions.completeSetup]. Disposed with the setup screen.

abstract class _$SetupFlow extends $AsyncNotifier<SetupDraft> {
  FutureOr<SetupDraft> build();
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
    return element.handleCreate(ref, build);
  }
}
