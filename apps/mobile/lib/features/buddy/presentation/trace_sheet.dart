import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_state.dart';
import 'package:material_ui/material_ui.dart';

/// The trace of one turn (AI-172, A66 D14): each step's tool, arguments,
/// result summary, time, tokens and cost, as the server sent them. Dev and
/// owner builds only; the trace stays on this phone (never synced, never
/// logged). Technical text, shown as is.
Future<void> showBuddyTrace(BuildContext context, List<TraceStepView> steps) =>
    showFbSheet<void>(
      context,
      title: context.l10n.buddyTraceTitle,
      builder: (context) => _TraceList(steps: steps),
    );

class _TraceList extends StatelessWidget {
  const new({required this.steps});

  final List<TraceStepView> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (steps.isEmpty) {
      return Text(l10n.buddyTraceEmpty, style: FbType.body);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final step in steps)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.buddyTraceStep(
                    step.tool,
                    step.ms,
                    step.tokens,
                    '\$${step.usd.toStringAsFixed(4)}',
                  ),
                  style: FbType.label,
                ),
                if (step.args.isNotEmpty)
                  Text(
                    step.args,
                    style: FbType.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (step.resultSummary.isNotEmpty)
                  Text(step.resultSummary, style: FbType.caption),
              ],
            ),
          ),
      ],
    );
  }
}
