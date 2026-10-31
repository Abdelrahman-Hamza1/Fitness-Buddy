// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_summary.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today's targets for Me, or null before setup (or with no version in
/// effect today). Follows every targets change.

@ProviderFor(meTargetsSummary)
final meTargetsSummaryProvider = MeTargetsSummaryProvider._();

/// Today's targets for Me, or null before setup (or with no version in
/// effect today). Follows every targets change.

final class MeTargetsSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<MeTargetsSummary?>,
          MeTargetsSummary?,
          FutureOr<MeTargetsSummary?>
        >
    with
        $FutureModifier<MeTargetsSummary?>,
        $FutureProvider<MeTargetsSummary?> {
  /// Today's targets for Me, or null before setup (or with no version in
  /// effect today). Follows every targets change.
  MeTargetsSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meTargetsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meTargetsSummaryHash();

  @$internal
  @override
  $FutureProviderElement<MeTargetsSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MeTargetsSummary?> create(Ref ref) {
    return meTargetsSummary(ref);
  }
}

String _$meTargetsSummaryHash() => r'59b34573789967143c32fbf0b0231f5a5d3b517a';
