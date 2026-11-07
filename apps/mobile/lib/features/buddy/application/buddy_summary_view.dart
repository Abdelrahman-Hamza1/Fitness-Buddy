import 'package:fb_mobile/features/buddy/data/buddy_summary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_summary_view.g.dart';

/// The conversation summary's text, or `null` without one (AI-165).
@riverpod
Stream<String?> buddySummaryText(Ref ref) => ref
    .watch(buddySummaryRepositoryProvider)
    .watch()
    .map((s) => s?.text)
    .distinct();
