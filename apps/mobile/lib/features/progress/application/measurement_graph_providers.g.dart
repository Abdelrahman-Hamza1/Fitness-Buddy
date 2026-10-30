// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_graph_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the [MeasurementGraphWindow] of the type [key]
/// (`MeasurementTypeRef.key`); survives leaving and returning.

@ProviderFor(MeasurementGraphWindowController)
final measurementGraphWindowControllerProvider =
    MeasurementGraphWindowControllerFamily._();

/// Holds the [MeasurementGraphWindow] of the type [key]
/// (`MeasurementTypeRef.key`); survives leaving and returning.
final class MeasurementGraphWindowControllerProvider
    extends
        $NotifierProvider<
          MeasurementGraphWindowController,
          MeasurementGraphWindow
        > {
  /// Holds the [MeasurementGraphWindow] of the type [key]
  /// (`MeasurementTypeRef.key`); survives leaving and returning.
  MeasurementGraphWindowControllerProvider._({
    required MeasurementGraphWindowControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'measurementGraphWindowControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$measurementGraphWindowControllerHash();

  @override
  String toString() {
    return r'measurementGraphWindowControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MeasurementGraphWindowController create() =>
      MeasurementGraphWindowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeasurementGraphWindow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeasurementGraphWindow>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MeasurementGraphWindowControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$measurementGraphWindowControllerHash() =>
    r'5e7a237f7964c47d1387178a0da038b62f37c73f';

/// Holds the [MeasurementGraphWindow] of the type [key]
/// (`MeasurementTypeRef.key`); survives leaving and returning.

final class MeasurementGraphWindowControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MeasurementGraphWindowController,
          MeasurementGraphWindow,
          MeasurementGraphWindow,
          MeasurementGraphWindow,
          String
        > {
  MeasurementGraphWindowControllerFamily._()
    : super(
        retry: null,
        name: r'measurementGraphWindowControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Holds the [MeasurementGraphWindow] of the type [key]
  /// (`MeasurementTypeRef.key`); survives leaving and returning.

  MeasurementGraphWindowControllerProvider call(String key) =>
      MeasurementGraphWindowControllerProvider._(argument: key, from: this);

  @override
  String toString() => r'measurementGraphWindowControllerProvider';
}

/// Holds the [MeasurementGraphWindow] of the type [key]
/// (`MeasurementTypeRef.key`); survives leaving and returning.

abstract class _$MeasurementGraphWindowController
    extends $Notifier<MeasurementGraphWindow> {
  late final _$args = ref.$arg as String;
  String get key => _$args;

  MeasurementGraphWindow build(String key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<MeasurementGraphWindow, MeasurementGraphWindow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MeasurementGraphWindow, MeasurementGraphWindow>,
              MeasurementGraphWindow,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The selected entry's ID on the graph of type [key], or null.

@ProviderFor(SelectedMeasurement)
final selectedMeasurementProvider = SelectedMeasurementFamily._();

/// The selected entry's ID on the graph of type [key], or null.
final class SelectedMeasurementProvider
    extends $NotifierProvider<SelectedMeasurement, String?> {
  /// The selected entry's ID on the graph of type [key], or null.
  SelectedMeasurementProvider._({
    required SelectedMeasurementFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'selectedMeasurementProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectedMeasurementHash();

  @override
  String toString() {
    return r'selectedMeasurementProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SelectedMeasurement create() => SelectedMeasurement();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedMeasurementProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectedMeasurementHash() =>
    r'c28ef622c27b8eb77852c01ff058c599556b089d';

/// The selected entry's ID on the graph of type [key], or null.

final class SelectedMeasurementFamily extends $Family
    with
        $ClassFamilyOverride<
          SelectedMeasurement,
          String?,
          String?,
          String?,
          String
        > {
  SelectedMeasurementFamily._()
    : super(
        retry: null,
        name: r'selectedMeasurementProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The selected entry's ID on the graph of type [key], or null.

  SelectedMeasurementProvider call(String key) =>
      SelectedMeasurementProvider._(argument: key, from: this);

  @override
  String toString() => r'selectedMeasurementProvider';
}

/// The selected entry's ID on the graph of type [key], or null.

abstract class _$SelectedMeasurement extends $Notifier<String?> {
  late final _$args = ref.$arg as String;
  String get key => _$args;

  String? build(String key);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
