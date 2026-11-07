// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_summary_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The conversation summary's text, or `null` without one (AI-165).

@ProviderFor(buddySummaryText)
final buddySummaryTextProvider = BuddySummaryTextProvider._();

/// The conversation summary's text, or `null` without one (AI-165).

final class BuddySummaryTextProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// The conversation summary's text, or `null` without one (AI-165).
  BuddySummaryTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buddySummaryTextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buddySummaryTextHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return buddySummaryText(ref);
  }
}

String _$buddySummaryTextHash() => r'c99408290b97a0c313526df8bc205224c135e300';
