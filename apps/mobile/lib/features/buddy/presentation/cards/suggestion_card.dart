import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/suggestions/buddy_suggestions.dart';
import 'package:material_ui/material_ui.dart';

/// Buddy's food suggestions under a reply (AI-120, AI-121): the options
/// that fit what's left today, each with the app's own numbers; a tap makes
/// a food card to confirm. Nothing is logged from here. When none fit, one
/// calm line says so.
class SuggestionCard extends StatelessWidget {
  /// The card of [suggestion]; [onPick] gets an option's index; [enabled]
  /// is off while Buddy still works.
  const new({
    required this.suggestion,
    required this.onPick,
    this.enabled = true,
    super.key,
  });

  /// The options.
  final BuddySuggestion suggestion;

  /// A tap on option `index`.
  final Future<void> Function(int index) onPick;

  /// Whether options can be tapped.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (suggestion.noneFit) {
      return FbInlineBanner(
        kind: FbInlineBannerKind.info,
        message: l10n.buddySuggestionNoneFit,
      );
    }
    return FbCard(
      padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
              vertical: FbSpace.s2,
            ),
            child: Text(l10n.buddySuggestionTitle, style: FbType.label),
          ),
          for (final (i, option) in suggestion.options.indexed)
            FbListRow(
              key: ValueKey('suggestion-$i'),
              title: option.label,
              subtitle: [
                l10n.buddySuggestionFacts(
                  DisplayRounding.kcal(option.kcal),
                  option.protein.round(),
                ),
                if (option.unknownSource)
                  l10n.halalCheckMessage(l10n.halalUnknownSource),
              ].join('\n'),
              trailing: Icon(
                option.picked ? FbIcons.check : FbIcons.add,
                semanticLabel: option.picked
                    ? l10n.buddySuggestionPicked
                    : l10n.buddySuggestionPick,
              ),
              onTap: enabled && !option.picked
                  ? () => unawaited(onPick(i))
                  : null,
            ),
        ],
      ),
    );
  }
}
