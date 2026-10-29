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

/// A weighed-rice-and-egg card: two questions and an oil assumption chip.
ProposalSession _withQuestion() => f.session(
  f.message([
    f.intent([
      f.riceItem(),
      f.item(dimensions: [f.fatDimension()]),
      f.riceItem(amount: 100),
    ]),
  ]),
);

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

/// The card states of exit criterion 3 (AI-030, AI-032, AI-034, AI-035).
final Map<String, Widget Function()> _states = {
  'loading skeleton': () => const FbProposalCard.skeleton(),
  'with question': () =>
      FoodProposalCard(view: FoodCardView.of(_card(_withQuestion()))),
  'with estimate': () =>
      FoodProposalCard(view: FoodCardView.of(_card(_withEstimate()))),
  'after confirm': () {
    final session = f.session(f.message());
    final card = session.cards.single;
    return FoodProposalCard(
      view: FoodCardView.of(
        BuddyCard(
          id: card.id,
          session: session,
          resolution: CardResolution.logged,
          undoEntryId: 'undo',
          logged: LoggedSummary(kcal: card.totals.kcal, preview: card.preview),
        ),
      ),
    );
  },
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
  for (final MapEntry(key: state, value: card) in _states.entries) {
    await goldenTest(
      'AI-030 AI-032 AI-034 AI-035 A22 food card: $state',
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
