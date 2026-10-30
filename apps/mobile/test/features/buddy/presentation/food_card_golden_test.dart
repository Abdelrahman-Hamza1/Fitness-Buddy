import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/food_proposal_card.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    as f;
import '../../today/presentation/support/today_support.dart' show phoneApp;

/// A family-plate card Buddy estimated (a `~` range).
ProposalSession _withEstimate() => f.session(
  f.message([
    f.intent([
      f.item(amount: 250, unit: 'g')
        ..['match'] = null
        ..['estimate'] = {
          'range': {'low': f.n(120), 'high': f.n(180)},
          'reason': 'noMatch',
        },
      f.item(),
    ]),
  ]),
);

BuddyCard _card(ProposalSession session) =>
    BuddyCard(id: session.cards.single.id, session: session);

/// The one card golden: a card with a `~` estimate, which also guards the
/// visible estimate badge (rule 1). Every other state is a behaviour test.
final Map<String, Widget Function()> _states = {
  'with estimate': () =>
      FoodProposalCard(view: FoodCardView.of(_card(_withEstimate()))),
};

/// Metric units and the four default meals.
final List<Override> _overrides = [
  unitSystemProvider.overrideWith((ref) => Stream.value(UnitSystem.metric)),
  slotRecordsProvider.overrideWith(
    (ref) => Stream.value([
      for (final slot in [
        DefaultSlots.breakfast,
        DefaultSlots.lunch,
        DefaultSlots.dinner,
        DefaultSlots.snacks,
      ])
        SlotRecord(slot, 1),
    ]),
  ),
];

Widget _cell(Widget card, Brightness brightness, double scale) => SizedBox(
  width: 360,
  child: ProviderScope(
    overrides: _overrides,
    child: phoneApp(
      Material(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(FbSpace.s3),
          child: card,
        ),
      ),
      brightness: brightness,
      textScale: scale,
    ),
  ),
);

Future<void> main() async {
  await _goldens('AI-030 AI-032 A22', _states);
}

Future<void> _goldens(
  String prefix,
  Map<String, Widget Function()> states,
) async {
  for (final MapEntry(key: state, value: card) in states.entries) {
    await goldenTest(
      '$prefix food card: $state',
      fileName: 'food_card_${state.replaceAll(' ', '_')}',
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          for (final scale in const [1.0, 2.0])
            for (final (label, brightness) in const [
              ('light', Brightness.light),
              ('dark', Brightness.dark),
            ])
              GoldenTestScenario(
                name: '$label, x$scale',
                constraints: BoxConstraints.tightFor(
                  width: 360,
                  height: scale == 1 ? 760 : 1800,
                ),
                child: _cell(card(), brightness, scale),
              ),
        ],
      ),
    );
  }
}
