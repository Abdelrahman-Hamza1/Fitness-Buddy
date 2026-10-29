// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weigh_in_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Weigh-in commands (A14 D5): every write is one change set through the
/// single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight (`log` for a
/// new weigh-in, else the weigh-in's ID).

@ProviderFor(WeighInActions)
final weighInActionsProvider = WeighInActionsProvider._();

/// Weigh-in commands (A14 D5): every write is one change set through the
/// single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight (`log` for a
/// new weigh-in, else the weigh-in's ID).
final class WeighInActionsProvider
    extends $NotifierProvider<WeighInActions, Set<String>> {
  /// Weigh-in commands (A14 D5): every write is one change set through the
  /// single writer, pushed to the undo stack as a direct action (UX-030).
  /// Session-lived, so an action outlives the sheet that started it. The
  /// state is the set of identities with an action in flight (`log` for a
  /// new weigh-in, else the weigh-in's ID).
  WeighInActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weighInActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weighInActionsHash();

  @$internal
  @override
  WeighInActions create() => WeighInActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$weighInActionsHash() => r'c3fbad14348217b88017a69a070bfc53357e9010';

/// Weigh-in commands (A14 D5): every write is one change set through the
/// single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight (`log` for a
/// new weigh-in, else the weigh-in's ID).

abstract class _$WeighInActions extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
