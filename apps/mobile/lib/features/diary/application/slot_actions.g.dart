// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-lived commands with reactive per-slot pending identities.

@ProviderFor(SlotActions)
final slotActionsProvider = SlotActionsProvider._();

/// Session-lived commands with reactive per-slot pending identities.
final class SlotActionsProvider
    extends $NotifierProvider<SlotActions, Set<String>> {
  /// Session-lived commands with reactive per-slot pending identities.
  SlotActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slotActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slotActionsHash();

  @$internal
  @override
  SlotActions create() => SlotActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$slotActionsHash() => r'900f5937317758e080cab5eb5e7aa6522904c666';

/// Session-lived commands with reactive per-slot pending identities.

abstract class _$SlotActions extends $Notifier<Set<String>> {
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
