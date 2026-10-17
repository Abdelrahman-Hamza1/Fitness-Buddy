// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The diary for [date] (slots, groups, entries, mark), live. Local data
/// only, so it never shows a spinner for long (UX-001).

@ProviderFor(day)
final dayProvider = DayFamily._();

/// The diary for [date] (slots, groups, entries, mark), live. Local data
/// only, so it never shows a spinner for long (UX-001).

final class DayProvider
    extends
        $FunctionalProvider<AsyncValue<DiaryDay>, DiaryDay, Stream<DiaryDay>>
    with $FutureModifier<DiaryDay>, $StreamProvider<DiaryDay> {
  /// The diary for [date] (slots, groups, entries, mark), live. Local data
  /// only, so it never shows a spinner for long (UX-001).
  DayProvider._({
    required DayFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'dayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayHash();

  @override
  String toString() {
    return r'dayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DiaryDay> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DiaryDay> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return day(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayHash() => r'90a77fe5a1e0fda6b2f8f27dc8638bc5ae13a2a5';

/// The diary for [date] (slots, groups, entries, mark), live. Local data
/// only, so it never shows a spinner for long (UX-001).

final class DayFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DiaryDay>, LocalDate> {
  DayFamily._()
    : super(
        retry: null,
        name: r'dayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The diary for [date] (slots, groups, entries, mark), live. Local data
  /// only, so it never shows a spinner for long (UX-001).

  DayProvider call(LocalDate date) => DayProvider._(argument: date, from: this);

  @override
  String toString() => r'dayProvider';
}

/// The totals of [date]: the sum of the entries' stored snapshots.

@ProviderFor(dayTotals)
final dayTotalsProvider = DayTotalsFamily._();

/// The totals of [date]: the sum of the entries' stored snapshots.

final class DayTotalsProvider
    extends
        $FunctionalProvider<AsyncValue<Nutrients>, Nutrients, Stream<Nutrients>>
    with $FutureModifier<Nutrients>, $StreamProvider<Nutrients> {
  /// The totals of [date]: the sum of the entries' stored snapshots.
  DayTotalsProvider._({
    required DayTotalsFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'dayTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayTotalsHash();

  @override
  String toString() {
    return r'dayTotalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Nutrients> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Nutrients> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return dayTotals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DayTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayTotalsHash() => r'138b91392457d52e92a903600f3051039886833e';

/// The totals of [date]: the sum of the entries' stored snapshots.

final class DayTotalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Nutrients>, LocalDate> {
  DayTotalsFamily._()
    : super(
        retry: null,
        name: r'dayTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The totals of [date]: the sum of the entries' stored snapshots.

  DayTotalsProvider call(LocalDate date) =>
      DayTotalsProvider._(argument: date, from: this);

  @override
  String toString() => r'dayTotalsProvider';
}
