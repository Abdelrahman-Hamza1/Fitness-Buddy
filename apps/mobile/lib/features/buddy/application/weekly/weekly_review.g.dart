// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_review.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Buddy's review of the week from [weekStart] (AI-130–132, A68 D6), as
/// stored, now and on each change; null until one was written.

@ProviderFor(weeklyReview)
final weeklyReviewProvider = WeeklyReviewFamily._();

/// Buddy's review of the week from [weekStart] (AI-130–132, A68 D6), as
/// stored, now and on each change; null until one was written.

final class WeeklyReviewProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// Buddy's review of the week from [weekStart] (AI-130–132, A68 D6), as
  /// stored, now and on each change; null until one was written.
  WeeklyReviewProvider._({
    required WeeklyReviewFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'weeklyReviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weeklyReviewHash();

  @override
  String toString() {
    return r'weeklyReviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return weeklyReview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyReviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weeklyReviewHash() => r'82e1debf2bdf756383aeddedecd624223093be76';

/// Buddy's review of the week from [weekStart] (AI-130–132, A68 D6), as
/// stored, now and on each change; null until one was written.

final class WeeklyReviewFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, LocalDate> {
  WeeklyReviewFamily._()
    : super(
        retry: null,
        name: r'weeklyReviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Buddy's review of the week from [weekStart] (AI-130–132, A68 D6), as
  /// stored, now and on each change; null until one was written.

  WeeklyReviewProvider call(LocalDate weekStart) =>
      WeeklyReviewProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'weeklyReviewProvider';
}

/// Writes the review of the week from its [build] argument at most once
/// per profile session unless the user taps Try again (A68 D6): a
/// `weeklyReview` turn with the week's aggregates only, through the turn
/// runner (no phone tools, no cards). Only an `answered` review is stored,
/// per week in a synced setting (`Origin.system`, no undo: it isn't the
/// user's data to edit). Kept alive for the profile session (reopening the
/// screen never asks again); a profile switch resets it and stops a
/// running turn. The local tiles never wait for it. Nothing here logs.

@ProviderFor(WeeklyReviewWriter)
final weeklyReviewWriterProvider = WeeklyReviewWriterFamily._();

/// Writes the review of the week from its [build] argument at most once
/// per profile session unless the user taps Try again (A68 D6): a
/// `weeklyReview` turn with the week's aggregates only, through the turn
/// runner (no phone tools, no cards). Only an `answered` review is stored,
/// per week in a synced setting (`Origin.system`, no undo: it isn't the
/// user's data to edit). Kept alive for the profile session (reopening the
/// screen never asks again); a profile switch resets it and stops a
/// running turn. The local tiles never wait for it. Nothing here logs.
final class WeeklyReviewWriterProvider
    extends $NotifierProvider<WeeklyReviewWriter, WeeklyReviewWriting> {
  /// Writes the review of the week from its [build] argument at most once
  /// per profile session unless the user taps Try again (A68 D6): a
  /// `weeklyReview` turn with the week's aggregates only, through the turn
  /// runner (no phone tools, no cards). Only an `answered` review is stored,
  /// per week in a synced setting (`Origin.system`, no undo: it isn't the
  /// user's data to edit). Kept alive for the profile session (reopening the
  /// screen never asks again); a profile switch resets it and stops a
  /// running turn. The local tiles never wait for it. Nothing here logs.
  WeeklyReviewWriterProvider._({
    required WeeklyReviewWriterFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'weeklyReviewWriterProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weeklyReviewWriterHash();

  @override
  String toString() {
    return r'weeklyReviewWriterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WeeklyReviewWriter create() => WeeklyReviewWriter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeeklyReviewWriting value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeeklyReviewWriting>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyReviewWriterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weeklyReviewWriterHash() =>
    r'bc2fd848c58b88581e659d16b1ca86dab0f15529';

/// Writes the review of the week from its [build] argument at most once
/// per profile session unless the user taps Try again (A68 D6): a
/// `weeklyReview` turn with the week's aggregates only, through the turn
/// runner (no phone tools, no cards). Only an `answered` review is stored,
/// per week in a synced setting (`Origin.system`, no undo: it isn't the
/// user's data to edit). Kept alive for the profile session (reopening the
/// screen never asks again); a profile switch resets it and stops a
/// running turn. The local tiles never wait for it. Nothing here logs.

final class WeeklyReviewWriterFamily extends $Family
    with
        $ClassFamilyOverride<
          WeeklyReviewWriter,
          WeeklyReviewWriting,
          WeeklyReviewWriting,
          WeeklyReviewWriting,
          LocalDate
        > {
  WeeklyReviewWriterFamily._()
    : super(
        retry: null,
        name: r'weeklyReviewWriterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Writes the review of the week from its [build] argument at most once
  /// per profile session unless the user taps Try again (A68 D6): a
  /// `weeklyReview` turn with the week's aggregates only, through the turn
  /// runner (no phone tools, no cards). Only an `answered` review is stored,
  /// per week in a synced setting (`Origin.system`, no undo: it isn't the
  /// user's data to edit). Kept alive for the profile session (reopening the
  /// screen never asks again); a profile switch resets it and stops a
  /// running turn. The local tiles never wait for it. Nothing here logs.

  WeeklyReviewWriterProvider call(LocalDate weekStart) =>
      WeeklyReviewWriterProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'weeklyReviewWriterProvider';
}

/// Writes the review of the week from its [build] argument at most once
/// per profile session unless the user taps Try again (A68 D6): a
/// `weeklyReview` turn with the week's aggregates only, through the turn
/// runner (no phone tools, no cards). Only an `answered` review is stored,
/// per week in a synced setting (`Origin.system`, no undo: it isn't the
/// user's data to edit). Kept alive for the profile session (reopening the
/// screen never asks again); a profile switch resets it and stops a
/// running turn. The local tiles never wait for it. Nothing here logs.

abstract class _$WeeklyReviewWriter extends $Notifier<WeeklyReviewWriting> {
  late final _$args = ref.$arg as LocalDate;
  LocalDate get weekStart => _$args;

  WeeklyReviewWriting build(LocalDate weekStart);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WeeklyReviewWriting, WeeklyReviewWriting>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WeeklyReviewWriting, WeeklyReviewWriting>,
              WeeklyReviewWriting,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
