// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reschedules at slot boundaries, local midnight, or at most 30 minutes.
/// An on-resume invalidation also refreshes zone changes after backgrounding.

@ProviderFor(quickAddContext)
final quickAddContextProvider = QuickAddContextProvider._();

/// Reschedules at slot boundaries, local midnight, or at most 30 minutes.
/// An on-resume invalidation also refreshes zone changes after backgrounding.

final class QuickAddContextProvider
    extends
        $FunctionalProvider<QuickAddContext, QuickAddContext, QuickAddContext>
    with $Provider<QuickAddContext> {
  /// Reschedules at slot boundaries, local midnight, or at most 30 minutes.
  /// An on-resume invalidation also refreshes zone changes after backgrounding.
  QuickAddContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddContextHash();

  @$internal
  @override
  $ProviderElement<QuickAddContext> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuickAddContext create(Ref ref) {
    return quickAddContext(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickAddContext value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickAddContext>(value),
    );
  }
}

String _$quickAddContextHash() => r'2ebdf37079389557769efc31d646b7abf0dd76ed';

/// Rebuildable 60-day usage input, never subscribed before the day's first
/// data frame has been drawn.

@ProviderFor(quickAddWindow)
final quickAddWindowProvider = QuickAddWindowFamily._();

/// Rebuildable 60-day usage input, never subscribed before the day's first
/// data frame has been drawn.

final class QuickAddWindowProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DiaryEntry>>,
          List<DiaryEntry>,
          Stream<List<DiaryEntry>>
        >
    with $FutureModifier<List<DiaryEntry>>, $StreamProvider<List<DiaryEntry>> {
  /// Rebuildable 60-day usage input, never subscribed before the day's first
  /// data frame has been drawn.
  QuickAddWindowProvider._({
    required QuickAddWindowFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'quickAddWindowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quickAddWindowHash();

  @override
  String toString() {
    return r'quickAddWindowProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<DiaryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DiaryEntry>> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return quickAddWindow(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QuickAddWindowProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quickAddWindowHash() => r'32b6b8f6a1e4ac34a1d8e1079038f86b310390ab';

/// Rebuildable 60-day usage input, never subscribed before the day's first
/// data frame has been drawn.

final class QuickAddWindowFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<DiaryEntry>>, LocalDate> {
  QuickAddWindowFamily._()
    : super(
        retry: null,
        name: r'quickAddWindowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Rebuildable 60-day usage input, never subscribed before the day's first
  /// data frame has been drawn.

  QuickAddWindowProvider call(LocalDate today) =>
      QuickAddWindowProvider._(argument: today, from: this);

  @override
  String toString() => r'quickAddWindowProvider';
}

/// False until the frame that first showed the viewed day's data has been
/// drawn, then true (A09 D14). The day's own frame stays free of chip work: no
/// history, meal, personal-food or slot subscription and no ranking happens
/// before this flips. A post-frame step, not a timer, so it follows the frame
/// however long that frame takes.

@ProviderFor(QuickAddActivation)
final quickAddActivationProvider = QuickAddActivationFamily._();

/// False until the frame that first showed the viewed day's data has been
/// drawn, then true (A09 D14). The day's own frame stays free of chip work: no
/// history, meal, personal-food or slot subscription and no ranking happens
/// before this flips. A post-frame step, not a timer, so it follows the frame
/// however long that frame takes.
final class QuickAddActivationProvider
    extends $NotifierProvider<QuickAddActivation, bool> {
  /// False until the frame that first showed the viewed day's data has been
  /// drawn, then true (A09 D14). The day's own frame stays free of chip work: no
  /// history, meal, personal-food or slot subscription and no ranking happens
  /// before this flips. A post-frame step, not a timer, so it follows the frame
  /// however long that frame takes.
  QuickAddActivationProvider._({
    required QuickAddActivationFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'quickAddActivationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quickAddActivationHash();

  @override
  String toString() {
    return r'quickAddActivationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  QuickAddActivation create() => QuickAddActivation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuickAddActivationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quickAddActivationHash() =>
    r'a7e0467b8468d60b3e054f0c6fdba4c5e79732a5';

/// False until the frame that first showed the viewed day's data has been
/// drawn, then true (A09 D14). The day's own frame stays free of chip work: no
/// history, meal, personal-food or slot subscription and no ranking happens
/// before this flips. A post-frame step, not a timer, so it follows the frame
/// however long that frame takes.

final class QuickAddActivationFamily extends $Family
    with $ClassFamilyOverride<QuickAddActivation, bool, bool, bool, LocalDate> {
  QuickAddActivationFamily._()
    : super(
        retry: null,
        name: r'quickAddActivationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// False until the frame that first showed the viewed day's data has been
  /// drawn, then true (A09 D14). The day's own frame stays free of chip work: no
  /// history, meal, personal-food or slot subscription and no ranking happens
  /// before this flips. A post-frame step, not a timer, so it follows the frame
  /// however long that frame takes.

  QuickAddActivationProvider call(LocalDate viewedDate) =>
      QuickAddActivationProvider._(argument: viewedDate, from: this);

  @override
  String toString() => r'quickAddActivationProvider';
}

/// False until the frame that first showed the viewed day's data has been
/// drawn, then true (A09 D14). The day's own frame stays free of chip work: no
/// history, meal, personal-food or slot subscription and no ranking happens
/// before this flips. A post-frame step, not a timer, so it follows the frame
/// however long that frame takes.

abstract class _$QuickAddActivation extends $Notifier<bool> {
  late final _$args = ref.$arg as LocalDate;
  LocalDate get viewedDate => _$args;

  bool build(LocalDate viewedDate);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Scoped to the viewed day; its raw entries independently drive suppression.

@ProviderFor(quickAddChips)
final quickAddChipsProvider = QuickAddChipsFamily._();

/// Scoped to the viewed day; its raw entries independently drive suppression.

final class QuickAddChipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<QuickAddChip>>,
          AsyncValue<List<QuickAddChip>>,
          AsyncValue<List<QuickAddChip>>
        >
    with $Provider<AsyncValue<List<QuickAddChip>>> {
  /// Scoped to the viewed day; its raw entries independently drive suppression.
  QuickAddChipsProvider._({
    required QuickAddChipsFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'quickAddChipsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quickAddChipsHash();

  @override
  String toString() {
    return r'quickAddChipsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<QuickAddChip>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<QuickAddChip>> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return quickAddChips(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<QuickAddChip>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<QuickAddChip>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuickAddChipsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quickAddChipsHash() => r'e5d7508f6129cda196a8cdf6c0625d37d13934c0';

/// Scoped to the viewed day; its raw entries independently drive suppression.

final class QuickAddChipsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<QuickAddChip>>, LocalDate> {
  QuickAddChipsFamily._()
    : super(
        retry: null,
        name: r'quickAddChipsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Scoped to the viewed day; its raw entries independently drive suppression.

  QuickAddChipsProvider call(LocalDate viewedDate) =>
      QuickAddChipsProvider._(argument: viewedDate, from: this);

  @override
  String toString() => r'quickAddChipsProvider';
}
