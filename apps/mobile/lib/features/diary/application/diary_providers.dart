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

/// The live entry [id] wherever it is now (any day or slot), or `null` once
/// deleted. Open edit sheets watch it (A08 D12(4), PA4).
@riverpod
Stream<DiaryEntry?> entry(Ref ref, String id) =>
    ref.watch(diaryRepositoryProvider).watchEntry(id);
