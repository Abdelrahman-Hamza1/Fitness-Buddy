import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marks [date] not fasting, or fasting again, and says so with Undo
/// (LC-034, A41a D7, fix round 1): a change to the Ramadan season's
/// setting, never to the diary's day marks. The container and the root
/// context are taken before the await (the starting widget may be gone).
Future<void> markNotFastingWithUndo(
  BuildContext context,
  LocalDate date, {
  required bool notFasting,
}) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await container
      .read(settingsActionsProvider)
      .setNotFasting(date, notFasting: notFasting);
  if (!host.mounted) return;
  reportSettingsOutcome(
    host,
    outcome,
    () => notFasting
        ? host.l10n.ramadanMarkedNotFasting
        : host.l10n.ramadanMarkedFasting,
  );
}
