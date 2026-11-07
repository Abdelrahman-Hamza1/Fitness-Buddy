// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [HomeWidgetInputs] now. Follows today (midnight, resume), the day's
/// diary and targets of today and tomorrow (a log, an edit, a target or
/// weigh-in change), the hide setting and the account status, so every
/// change to today rewrites the widgets (UX-084). Local reads only.

@ProviderFor(homeWidgetInputs)
final homeWidgetInputsProvider = HomeWidgetInputsProvider._();

/// The [HomeWidgetInputs] now. Follows today (midnight, resume), the day's
/// diary and targets of today and tomorrow (a log, an edit, a target or
/// weigh-in change), the hide setting and the account status, so every
/// change to today rewrites the widgets (UX-084). Local reads only.

final class HomeWidgetInputsProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeWidgetInputs>,
          HomeWidgetInputs,
          FutureOr<HomeWidgetInputs>
        >
    with $FutureModifier<HomeWidgetInputs>, $FutureProvider<HomeWidgetInputs> {
  /// The [HomeWidgetInputs] now. Follows today (midnight, resume), the day's
  /// diary and targets of today and tomorrow (a log, an edit, a target or
  /// weigh-in change), the hide setting and the account status, so every
  /// change to today rewrites the widgets (UX-084). Local reads only.
  HomeWidgetInputsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetInputsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetInputsHash();

  @$internal
  @override
  $FutureProviderElement<HomeWidgetInputs> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeWidgetInputs> create(Ref ref) {
    return homeWidgetInputs(ref);
  }
}

String _$homeWidgetInputsHash() => r'27ea2d57692e46b3a166daa3c72aebfe7a79f46e';
