// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_report.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The reporter behind the About gesture; tests override it with a fake.

@ProviderFor(testReportSender)
final testReportSenderProvider = TestReportSenderProvider._();

/// The reporter behind the About gesture; tests override it with a fake.

final class TestReportSenderProvider
    extends
        $FunctionalProvider<
          TestReportSender,
          TestReportSender,
          TestReportSender
        >
    with $Provider<TestReportSender> {
  /// The reporter behind the About gesture; tests override it with a fake.
  TestReportSenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testReportSenderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testReportSenderHash();

  @$internal
  @override
  $ProviderElement<TestReportSender> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TestReportSender create(Ref ref) {
    return testReportSender(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TestReportSender value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TestReportSender>(value),
    );
  }
}

String _$testReportSenderHash() => r'6189840e68f588579941544c031adf038bca13ae';
