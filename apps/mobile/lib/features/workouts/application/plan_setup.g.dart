// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_setup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The plan setup form's view model (D-089, A52 D5).

@ProviderFor(PlanSetup)
final planSetupProvider = PlanSetupFamily._();

/// The plan setup form's view model (D-089, A52 D5).
final class PlanSetupProvider
    extends $NotifierProvider<PlanSetup, PlanSetupState> {
  /// The plan setup form's view model (D-089, A52 D5).
  PlanSetupProvider._({
    required PlanSetupFamily super.from,
    required PlanSetupKey super.argument,
  }) : super(
         retry: null,
         name: r'planSetupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planSetupHash();

  @override
  String toString() {
    return r'planSetupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlanSetup create() => PlanSetup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanSetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanSetupState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlanSetupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planSetupHash() => r'b974b70f9457835c5a7dd683a13e0724ac28496c';

/// The plan setup form's view model (D-089, A52 D5).

final class PlanSetupFamily extends $Family
    with
        $ClassFamilyOverride<
          PlanSetup,
          PlanSetupState,
          PlanSetupState,
          PlanSetupState,
          PlanSetupKey
        > {
  PlanSetupFamily._()
    : super(
        retry: null,
        name: r'planSetupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The plan setup form's view model (D-089, A52 D5).

  PlanSetupProvider call(PlanSetupKey key) =>
      PlanSetupProvider._(argument: key, from: this);

  @override
  String toString() => r'planSetupProvider';
}

/// The plan setup form's view model (D-089, A52 D5).

abstract class _$PlanSetup extends $Notifier<PlanSetupState> {
  late final _$args = ref.$arg as PlanSetupKey;
  PlanSetupKey get key => _$args;

  PlanSetupState build(PlanSetupKey key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlanSetupState, PlanSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlanSetupState, PlanSetupState>,
              PlanSetupState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
