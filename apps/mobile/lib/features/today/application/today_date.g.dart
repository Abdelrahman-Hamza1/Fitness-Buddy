// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_date.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local today, refreshed one second after midnight; invalidate on resume.

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// Local today, refreshed one second after midnight; invalidate on resume.

final class TodayProvider
    extends
        $FunctionalProvider<AsyncValue<LocalDate>, LocalDate, Stream<LocalDate>>
    with $FutureModifier<LocalDate>, $StreamProvider<LocalDate> {
  /// Local today, refreshed one second after midnight; invalidate on resume.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $StreamProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<LocalDate> create(Ref ref) {
    return today(ref);
  }
}

String _$todayHash() => r'cce18ec8a156a19b20707df95eefaf7e8ec871b3';
