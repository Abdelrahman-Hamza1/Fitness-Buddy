import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/design_preview/application/gallery_samples.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_section.dart';
import 'package:material_ui/material_ui.dart';

typedef _S = GallerySamples;

/// Buddy's chat and proposal card components (A22).
final List<GallerySection> gallerySectionsBuddy = [
  GallerySection(
    name: 'FbProposalCard',
    covers: const [
      FbProposalCard,
      FbProposalLine,
      FbProposalActions,
      FbProposalResolvedRow,
      FbChangeHighlight,
    ],
    states: (_) => [
      GalleryState(
        'food card',
        FbProposalCard(
          header: _S.cardHeader,
          title: _S.cardDish,
          details: const Column(
            children: [
              FbProposalLine(
                name: _S.egg,
                amount: _S.eggAmount,
                kcal: _S.eggKcal,
                marker: FbSourceBadge(source: FbSource.database),
              ),
              FbChangeHighlight(
                token: null,
                child: FbProposalLine(
                  name: _S.oil,
                  amount: _S.oilAmount,
                  kcal: _S.oilKcal,
                  note: _S.oilNote,
                  marker: FbEstimateMarker(
                    rangeText: _S.oilRange,
                    reason: _S.oilReason,
                  ),
                ),
              ),
            ],
          ),
          assumptions: [FbAssumptionChip(label: _S.assumption, onTap: () {})],
          impact: const Text(_S.cardTotal),
          actions: FbProposalActions(
            discardLabel: _S.discard,
            confirmLabel: _S.logIt,
            onDiscard: () {},
            onConfirm: () {},
          ),
        ),
      ),
      GalleryState(
        'Log it disabled, with its reason',
        FbProposalActions(
          discardLabel: _S.discard,
          confirmLabel: _S.logIt,
          onDiscard: () {},
          onConfirm: null,
          reason: _S.cardReason,
        ),
      ),
      const GalleryState('loading', FbProposalCard.skeleton()),
      GalleryState(
        'logged, with one Undo',
        FbProposalResolvedRow(
          icon: FbIcons.check,
          text: _S.logged,
          undoLabel: _S.undo,
          onUndo: () {},
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbChat',
    covers: const [FbMessageBubble, FbComposer],
    states: (_) => [
      const GalleryState(
        'messages',
        Column(
          spacing: FbSpace.s2,
          children: [
            FbMessageBubble(text: _S.chatUser, fromUser: true),
            FbMessageBubble(text: _S.chatBuddy, fromUser: false),
          ],
        ),
      ),
      GalleryState(
        'composer',
        FbComposer(
          controller: TextEditingController(),
          hint: _S.composerHint,
          sendTooltip: _S.send,
          onSend: () {},
          leading: FbIconButton(
            icon: FbIcons.search,
            tooltip: _S.searchFoods,
            onPressed: () {},
          ),
        ),
      ),
    ],
  ),
];
