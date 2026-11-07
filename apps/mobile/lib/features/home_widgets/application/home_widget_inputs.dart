import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/home_widget/home_widget_store.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_inputs.g.dart';

/// What one widget snapshot is built from (A71 D5), read from the open
/// profile. Content-free [toString].
final class HomeWidgetInputs {
  /// The inputs.
  const new({
    required this.generation,
    required this.profileTag,
    required this.hidden,
    required this.signedOut,
    this.epoch = 0,
    this.days = const [],
  });

  /// The widget store's epoch when the read started (`HomeWidgetStore.epoch`):
  /// a read from before or during an account transition is never written.
  final int epoch;

  /// The profile generation they were read in.
  final int generation;

  /// The open profile's tag.
  final String profileTag;

  /// "Hide numbers" is on (UX-085).
  final bool hidden;

  /// The open profile is a read-only copy after sign-out.
  final bool signedOut;

  /// Today's and tomorrow's numbers as Today shows them; empty when
  /// [hidden] or [signedOut] (nothing else is read then).
  final List<(LocalDate, TodayNumbersView)> days;

  @override
  String toString() => 'HomeWidgetInputs(${days.length} days)';
}

/// The [HomeWidgetInputs] now. Follows today (midnight, resume), the day's
/// diary and targets of today and tomorrow (a log, an edit, a target or
/// weigh-in change), the hide setting and the account status, so every
/// change to today rewrites the widgets (UX-084). Local reads only.
@riverpod
Future<HomeWidgetInputs> homeWidgetInputs(Ref ref) async {
  final generation = ref.watch(profileGenerationProvider);
  final epoch = ref.read(homeWidgetStoreProvider).epoch;
  final tagFuture = ref.watch(homeWidgetProfileProvider.future);
  final hiddenFuture = ref.watch(widgetNumbersHiddenProvider.future);
  final statusFuture = ref.watch(accountStatusProvider.future);
  final todayFuture = ref.watch(todayProvider.future);
  final tag = await tagFuture;
  final hidden = await hiddenFuture;
  final signedOut = await statusFuture == AccountStatus.readOnlyCopy;
  if (hidden || signedOut) {
    return HomeWidgetInputs(
      generation: generation,
      epoch: epoch,
      profileTag: tag,
      hidden: hidden,
      signedOut: signedOut,
    );
  }
  final today = await todayFuture;
  final dates = [today, today.plusDays(1)];
  final read = await Future.wait<Object?>([
    for (final d in dates) ref.watch(dayProvider(d).future),
    for (final d in dates) ref.watch(dayTargetsProvider(d).future),
  ]);
  final days = [
    for (final (i, date) in dates.indexed)
      (
        date,
        TodayNumbersView.of(
          (read[i]! as DiaryDay).intake,
          read[dates.length + i] as DayTargets?,
        ),
      ),
  ];
  return HomeWidgetInputs(
    generation: generation,
    epoch: epoch,
    profileTag: tag,
    hidden: false,
    signedOut: false,
    days: days,
  );
}
