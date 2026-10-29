// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_issues.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reports the issue's type only (`ErrorReporting.reportKind`).

@ProviderFor(buddyIssueSink)
final buddyIssueSinkProvider = BuddyIssueSinkProvider._();

/// Reports the issue's type only (`ErrorReporting.reportKind`).

final class BuddyIssueSinkProvider
    extends $FunctionalProvider<BuddyIssueSink, BuddyIssueSink, BuddyIssueSink>
    with $Provider<BuddyIssueSink> {
  /// Reports the issue's type only (`ErrorReporting.reportKind`).
  BuddyIssueSinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddyIssueSinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddyIssueSinkHash();

  @$internal
  @override
  $ProviderElement<BuddyIssueSink> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BuddyIssueSink create(Ref ref) {
    return buddyIssueSink(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuddyIssueSink value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuddyIssueSink>(value),
    );
  }
}

String _$buddyIssueSinkHash() => r'588ae08ec0d2571d053e3badf737be5077b2ace1';
