import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marks [date] incomplete, or counts it again, and says so with Undo
/// (DY-004, UX-030, A16 D11). Shared by Progress's bar details and Today's
/// day menu. The container and the root context are taken before the
/// await: the widget that started it may be gone by then.
Future<void> markDayWithUndo(
  BuildContext context,
  LocalDate date, {
  required bool incomplete,
}) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await container
      .read(diaryActionsControllerProvider.notifier)
      .markDay(date, incomplete: incomplete);
  if (!host.mounted) return;
  reportDiaryOutcome(
    host,
    outcome,
    () => incomplete
        ? host.l10n.diaryDayMarkedIncomplete
        : host.l10n.diaryDayCounted,
  );
}
