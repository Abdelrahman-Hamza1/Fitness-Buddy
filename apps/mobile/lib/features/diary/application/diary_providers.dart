import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/features/diary/data/diary_day.dart';

part 'diary_providers.g.dart';

/// The diary for [date] (slots, groups, entries, mark), live. Local data
/// only, so it never shows a spinner for long (UX-001).
@riverpod
Stream<DiaryDay> day(Ref ref, LocalDate date) =>
    ref.watch(diaryRepositoryProvider).watchDay(date);

/// The totals of [date]: the sum of the entries' stored snapshots.
@riverpod
Stream<Nutrients> dayTotals(Ref ref, LocalDate date) =>
    ref.watch(diaryRepositoryProvider).watchDay(date).map((day) => day.totals);
