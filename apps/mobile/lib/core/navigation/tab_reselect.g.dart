// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab_reselect.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The latest tab re-tap (A45 D11, D13): the router fires it, and
/// [ScrollToTopOnTabReselect] scrolls the tab's main list to the top.

@ProviderFor(TabReselectNotifier)
final tabReselectProvider = TabReselectNotifierProvider._();

/// The latest tab re-tap (A45 D11, D13): the router fires it, and
/// [ScrollToTopOnTabReselect] scrolls the tab's main list to the top.
final class TabReselectNotifierProvider
    extends $NotifierProvider<TabReselectNotifier, TabReselect?> {
  /// The latest tab re-tap (A45 D11, D13): the router fires it, and
  /// [ScrollToTopOnTabReselect] scrolls the tab's main list to the top.
  TabReselectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tabReselectProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tabReselectNotifierHash();

  @$internal
  @override
  TabReselectNotifier create() => TabReselectNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TabReselect? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TabReselect?>(value),
    );
  }
}

String _$tabReselectNotifierHash() =>
    r'0fd071212ea394de6f22cf05f96f702b8cb906da';

/// The latest tab re-tap (A45 D11, D13): the router fires it, and
/// [ScrollToTopOnTabReselect] scrolls the tab's main list to the top.

abstract class _$TabReselectNotifier extends $Notifier<TabReselect?> {
  TabReselect? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TabReselect?, TabReselect?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TabReselect?, TabReselect?>,
              TabReselect?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
