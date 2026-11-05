import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:material_ui/material_ui.dart';

/// Today's slim line under the calories card (HM-005, HM-006, D-093,
/// A57 D5): weight | workout, side by side, always visible. Each half is
/// an [FbGlanceTile], whose height depends only on the text scale, so the
/// line is the same height in every state (loading, error, empty, data).
/// From text scale 1.5 the halves stack: chosen by the scale, never by the
/// state.
class TodayGlanceLine extends StatelessWidget {
  /// Creates the line for [date].
  const new({required this.date, required this.isToday, super.key});

  /// The viewed day.
  final LocalDate date;

  /// Whether [date] is today.
  final bool isToday;

  /// The text scale from which the halves stack.
  static const double stackFromScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final weight = WeightGlance(date: date, isToday: isToday);
    final workout = WorkoutGlance(date: date);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= stackFromScale;
    if (stacked) {
      return Column(
        key: const ValueKey('today-glance-line'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [weight, const Divider(height: 1), workout],
      );
    }
    return SizedBox(
      key: const ValueKey('today-glance-line'),
      height: FbGlanceTile.heightOf(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: weight),
          const VerticalDivider(width: FbSpace.s3, indent: 12, endIndent: 12),
          Expanded(child: workout),
        ],
      ),
    );
  }
}
