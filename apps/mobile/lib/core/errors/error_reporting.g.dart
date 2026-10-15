// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_reporting.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [ErrorReporting]; `AppBootstrap` starts it after the first
/// frame.

@ProviderFor(errorReporting)
final errorReportingProvider = ErrorReportingProvider._();

/// The app's [ErrorReporting]; `AppBootstrap` starts it after the first
/// frame.

final class ErrorReportingProvider
    extends $FunctionalProvider<ErrorReporting, ErrorReporting, ErrorReporting>
    with $Provider<ErrorReporting> {
  /// The app's [ErrorReporting]; `AppBootstrap` starts it after the first
  /// frame.
  ErrorReportingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorReportingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorReportingHash();

  @$internal
  @override
  $ProviderElement<ErrorReporting> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ErrorReporting create(Ref ref) {
    return errorReporting(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ErrorReporting value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ErrorReporting>(value),
    );
  }
}

String _$errorReportingHash() => r'eb597d57e46cadf30e80c8216150e90f97585087';
