import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Widget _food({VoidCallback? onConfirm, String? reason}) => FbProposalCard(
  header: 'Breakfast · 08:40',
  title: 'Eggs with oil',
  details: const Column(
    children: [
      FbProposalLine(
        name: 'Egg, boiled',
        amount: '2 pieces (100 g)',
        kcal: '155 kcal',
        marker: FbSourceBadge(source: FbSource.database),
      ),
      FbProposalLine(
        name: 'Olive oil',
        amount: '1 tsp (4.5 g)',
        kcal: '40 kcal',
        note: 'Most of the cooking oil counted',
        marker: FbEstimateMarker(rangeText: '30–50 kcal', reason: 'Guessed'),
      ),
    ],
  ),
  assumptions: [FbAssumptionChip(label: '1 tsp of oil', onTap: () {})],
  questions: Wrap(
    spacing: FbSpace.s2,
    children: [
      FbAnswerChip(label: 'Raw', onTap: () {}, selected: true, isDefault: true),
      FbAnswerChip(label: 'Cooked', onTap: () {}),
    ],
  ),
  impact: const Text('195 kcal · Today after this: 1,045 left'),
  actions: FbProposalActions(
    discardLabel: 'Discard',
    confirmLabel: 'Log it',
    onDiscard: () {},
    onConfirm: onConfirm,
    reason: reason,
  ),
);

/// A phone-wide cell, padded like a screen.
Widget _cell(Widget child) => fbGoldenPad(
  SizedBox(width: fbGoldenCellWidth - 2 * FbSpace.s4, child: child),
);

Future<void> main() => fbGoldenMatrix(
  'UX-020 UX-021 UX-026 A22 proposal card shell golden matrix',
  fileName: 'proposal_card',
  states: {
    'food card': (_) => _cell(_food(onConfirm: () {})),
    'disabled with reason': (_) =>
        _cell(_food(reason: 'Add an amount to log this.')),
    'before and after': (_) => _cell(
      FbProposalCard(
        header: 'Change to your diary · Lunch',
        details: const Text('Rice 200 g → 150 g'),
        impact: const Text('Left today: 900 → 965 kcal'),
        actions: FbProposalActions(
          discardLabel: 'Discard',
          confirmLabel: 'Apply change',
          onDiscard: () {},
          onConfirm: () {},
        ),
      ),
    ),
    'skeleton': (_) => _cell(const FbProposalCard.skeleton()),
    'resolved': (_) => _cell(
      Column(
        children: [
          FbProposalResolvedRow(
            icon: FbIcons.check,
            text: 'Logged ✓ 195 kcal · 1,045 left today',
            undoLabel: 'Undo',
            onUndo: () {},
          ),
          const FbProposalResolvedRow(icon: FbIcons.info, text: 'Undone'),
          const FbMessageBubble(
            text: '2 eggs and a tsp of oil',
            fromUser: true,
          ),
          const FbMessageBubble(text: "Here's your meal.", fromUser: false),
        ],
      ),
    ),
  },
);
