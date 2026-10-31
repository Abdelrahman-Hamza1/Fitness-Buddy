// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_slide.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-only slide shared by every day page (D-092).

@ProviderFor(TodaySlide)
final todaySlideProvider = TodaySlideProvider._();

/// Session-only slide shared by every day page (D-092).
final class TodaySlideProvider extends $NotifierProvider<TodaySlide, int> {
  /// Session-only slide shared by every day page (D-092).
  TodaySlideProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todaySlideProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todaySlideHash();

  @$internal
  @override
  TodaySlide create() => TodaySlide();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$todaySlideHash() => r'35c5848111a27835682e99ff3bfb8b778c8e89b8';

/// Session-only slide shared by every day page (D-092).

abstract class _$TodaySlide extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
