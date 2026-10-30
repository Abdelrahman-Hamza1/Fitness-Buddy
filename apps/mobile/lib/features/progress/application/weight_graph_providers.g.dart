// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_graph_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the [WeightGraphWindow]; survives leaving and returning.

@ProviderFor(WeightGraphWindowController)
final weightGraphWindowControllerProvider =
    WeightGraphWindowControllerProvider._();

/// Holds the [WeightGraphWindow]; survives leaving and returning.
final class WeightGraphWindowControllerProvider
    extends $NotifierProvider<WeightGraphWindowController, WeightGraphWindow> {
  /// Holds the [WeightGraphWindow]; survives leaving and returning.
  WeightGraphWindowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightGraphWindowControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightGraphWindowControllerHash();

  @$internal
  @override
  WeightGraphWindowController create() => WeightGraphWindowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeightGraphWindow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeightGraphWindow>(value),
    );
  }
}

String _$weightGraphWindowControllerHash() =>
    r'a4504cc06f4f19f19204760167001b64a51be1cb';

/// Holds the [WeightGraphWindow]; survives leaving and returning.

abstract class _$WeightGraphWindowController
    extends $Notifier<WeightGraphWindow> {
  WeightGraphWindow build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WeightGraphWindow, WeightGraphWindow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WeightGraphWindow, WeightGraphWindow>,
              WeightGraphWindow,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Highlighted periods for every chart (WB-021): empty for now. **A41
/// supplies Ramadan periods here**, labelled "Ramadan" by the screen.

@ProviderFor(chartHighlightPeriods)
final chartHighlightPeriodsProvider = ChartHighlightPeriodsProvider._();

/// Highlighted periods for every chart (WB-021): empty for now. **A41
/// supplies Ramadan periods here**, labelled "Ramadan" by the screen.

final class ChartHighlightPeriodsProvider
    extends
        $FunctionalProvider<
          List<({LocalDate end, LocalDate start})>,
          List<({LocalDate end, LocalDate start})>,
          List<({LocalDate end, LocalDate start})>
        >
    with $Provider<List<({LocalDate end, LocalDate start})>> {
  /// Highlighted periods for every chart (WB-021): empty for now. **A41
  /// supplies Ramadan periods here**, labelled "Ramadan" by the screen.
  ChartHighlightPeriodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartHighlightPeriodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chartHighlightPeriodsHash();

  @$internal
  @override
  $ProviderElement<List<({LocalDate end, LocalDate start})>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<({LocalDate end, LocalDate start})> create(Ref ref) {
    return chartHighlightPeriods(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<({LocalDate end, LocalDate start})> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<List<({LocalDate end, LocalDate start})>>(value),
    );
  }
}

String _$chartHighlightPeriodsHash() =>
    r'cf9aaa3aa57ad5c331d4e129ed68e8f0b061ab5b';

/// The [WeightGraphModel] from the weigh-ins, the trend, the goal phases and
/// the targets' TG-011 rate. Follows Today's local date
/// ([todayProvider]: refreshed after midnight and on resume). No automatic
/// retry: the screen shows the error with Try again (UX-052).

@ProviderFor(weightGraph)
final weightGraphProvider = WeightGraphProvider._();

/// The [WeightGraphModel] from the weigh-ins, the trend, the goal phases and
/// the targets' TG-011 rate. Follows Today's local date
/// ([todayProvider]: refreshed after midnight and on resume). No automatic
/// retry: the screen shows the error with Try again (UX-052).

final class WeightGraphProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeightGraphModel>,
          WeightGraphModel,
          FutureOr<WeightGraphModel>
        >
    with $FutureModifier<WeightGraphModel>, $FutureProvider<WeightGraphModel> {
  /// The [WeightGraphModel] from the weigh-ins, the trend, the goal phases and
  /// the targets' TG-011 rate. Follows Today's local date
  /// ([todayProvider]: refreshed after midnight and on resume). No automatic
  /// retry: the screen shows the error with Try again (UX-052).
  WeightGraphProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noAutomaticRetry,
        name: r'weightGraphProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightGraphHash();

  @$internal
  @override
  $FutureProviderElement<WeightGraphModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeightGraphModel> create(Ref ref) {
    return weightGraph(ref);
  }
}

String _$weightGraphHash() => r'a5749e32148a13915eda6ce412b8e086c99b3ebf';

/// The selected weigh-in's ID on the weight graph, or null.

@ProviderFor(SelectedWeighIn)
final selectedWeighInProvider = SelectedWeighInProvider._();

/// The selected weigh-in's ID on the weight graph, or null.
final class SelectedWeighInProvider
    extends $NotifierProvider<SelectedWeighIn, String?> {
  /// The selected weigh-in's ID on the weight graph, or null.
  SelectedWeighInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedWeighInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedWeighInHash();

  @$internal
  @override
  SelectedWeighIn create() => SelectedWeighIn();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedWeighInHash() => r'3e5a02be0ad694fd133da4afaa09ef7c37956e4b';

/// The selected weigh-in's ID on the weight graph, or null.

abstract class _$SelectedWeighIn extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
