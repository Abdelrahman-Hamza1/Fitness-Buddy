import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/proposal_labels.dart';
import 'package:fb_mobile/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    show localFood;

FoodChipView _chip(ProposalDimensionKind kind, ProposalEffect effect) {
  final option = ProposalOption('d/o', 'v', effect);
  return FoodChipView(
    lineId: 'line',
    foodName: 'Rice',
    dimension: ProposalDimension('d', kind, [option]),
    selected: option,
    origin: ProposalChoiceOrigin.fallback,
  );
}

void main() {
  final l10n = AppLocalizationsEn();

  // rule: A22 chip-context
  test('AI-033 assumption chips name what they are about', () {
    String label(ProposalDimensionKind kind, ProposalEffect effect) =>
        chipLabel(l10n, _chip(kind, effect), system: UnitSystem.metric);
    expect(
      label(ProposalDimensionKind.state, ProposalFoodEffect(localFood())),
      'Rice: cooked',
    );
    expect(
      label(
        ProposalDimensionKind.portion,
        ProposalQuantityEffect(Quantity(150, 'g')),
      ),
      'Rice: 150 g',
    );
    expect(
      label(
        ProposalDimensionKind.oilRetention,
        const ProposalRetentionEffect(0.5),
      ),
      'Most oil eaten',
    );
    expect(
      label(
        ProposalDimensionKind.oilRetention,
        const ProposalRetentionEffect(1),
      ),
      'All oil eaten',
    );
    expect(
      label(ProposalDimensionKind.share, const ProposalShareEffect(0.5)),
      'Your share: 50%',
    );
    expect(
      label(
        ProposalDimensionKind.fat,
        ProposalComponentEffect(null, Quantity(0, 'tsp')),
      ),
      'No oil',
    );
    expect(inlineFoodName('Rice, white'), 'rice, white');
  });
}
