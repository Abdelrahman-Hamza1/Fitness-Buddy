import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_view_state.dart';
import 'package:fb_mobile/features/diary/presentation/large_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dish inside an opened meal (DY-024): its name, how many items and the
/// dish's calories. Open by default, so its items are as close as any other
/// item (UX-013); a tap folds them away and the choice is remembered.
class DishGroupTile extends ConsumerWidget {
  /// Creates the row for [item].
  const new({required this.item, required this.expanded, super.key});

  /// The dish with its members and their total.
  final GroupItem item;

  /// Whether the members are shown below.
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = l10n.diaryGroupItems(item.members.length);
    final kcal = l10n.diaryKcal(DisplayRounding.kcal(item.totals.kcal));
    final large = usesLargeText(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: FbSpace.s4),
      child: FbDisclosureRow(
        title: item.group.name,
        subtitle: large ? kcal : count,
        expanded: expanded,
        trailing: large ? null : Text(kcal),
        onToggle: () => ref
            .read(diaryViewStateProvider.notifier)
            .toggleGroup(item.group.id),
      ),
    );
  }
}
