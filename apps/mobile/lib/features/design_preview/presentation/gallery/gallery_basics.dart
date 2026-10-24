import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/design_preview/application/gallery_samples.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_section.dart';
import 'package:material_ui/material_ui.dart';

typedef _S = GallerySamples;

/// Actions, text and number components.
final List<GallerySection> gallerySectionsBasics = [
  GallerySection(
    name: 'FbButton',
    covers: const [FbButton],
    states: (_) => [
      GalleryState(
        'primary',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.primary(label: _S.logIt, onPressed: () {}),
        ),
      ),
      const GalleryState(
        'primary disabled',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.primary(label: _S.logIt, onPressed: null),
        ),
      ),
      GalleryState(
        'primary with icon',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.primary(
            label: _S.addFood,
            icon: FbIcons.add,
            onPressed: () {},
          ),
        ),
      ),
      GalleryState(
        'primary expand',
        FbButton.primary(label: _S.logIt, expand: true, onPressed: () {}),
      ),
      GalleryState(
        'secondary',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.secondary(label: _S.discard, onPressed: () {}),
        ),
      ),
      const GalleryState(
        'secondary disabled',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.secondary(label: _S.discard, onPressed: null),
        ),
      ),
      GalleryState(
        'secondary with icon',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.secondary(
            label: _S.scan,
            icon: FbIcons.camera,
            onPressed: () {},
          ),
        ),
      ),
      GalleryState(
        'text',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.text(label: _S.notNow, onPressed: () {}),
        ),
      ),
      const GalleryState(
        'text disabled',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.text(label: _S.notNow, onPressed: null),
        ),
      ),
      GalleryState(
        'text with icon',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.text(
            label: _S.more,
            icon: FbIcons.more,
            onPressed: () {},
          ),
        ),
      ),
      GalleryState(
        'long label',
        FbButton.primary(label: _S.longButton, expand: true, onPressed: () {}),
      ),
    ],
  ),
  GallerySection(
    name: 'FbCard',
    covers: const [FbCard],
    states: (_) => [
      const GalleryState('static', FbCard(child: Text(_S.chickenAndRice))),
      GalleryState(
        'tappable',
        FbCard(onTap: () {}, child: const Text(_S.chickenAndRice)),
      ),
      const GalleryState('long text', FbCard(child: Text(_S.longText))),
    ],
  ),
  GallerySection(
    name: 'FbListRow',
    covers: const [FbListRow],
    states: (_) => [
      const GalleryState('plain', FbListRow(title: _S.breakfast)),
      const GalleryState(
        'subtitle',
        FbListRow(title: _S.breakfast, subtitle: _S.twoItems),
      ),
      GalleryState(
        'leading and trailing',
        FbListRow(
          title: _S.oats,
          subtitle: _S.oatsAmount,
          leading: const Icon(FbIcons.diary),
          trailing: const Text(_S.oatsKcal),
          onTap: () {},
        ),
      ),
      const GalleryState(
        'long title',
        FbListRow(
          title: _S.longRowTitle,
          subtitle: _S.longRowSubtitle,
          trailing: Text(_S.chicken650),
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbSectionHeader',
    covers: const [FbSectionHeader],
    states: (_) => [
      const GalleryState('title', FbSectionHeader(title: _S.dinner)),
      GalleryState(
        'trailing',
        FbSectionHeader(
          title: _S.dinner,
          trailing: FbButton.text(label: _S.add, onPressed: () {}),
        ),
      ),
      GalleryState(
        'long title',
        FbSectionHeader(
          title: _S.longSectionTitle,
          trailing: FbButton.text(label: _S.seeAll, onPressed: () {}),
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbBigNumber',
    covers: const [FbBigNumber],
    states: (_) => [
      const GalleryState(
        'under target',
        FbBigNumber(value: _S.kcalLeftValue, caption: _S.kcalLeft),
      ),
      const GalleryState(
        'over target (neutral, never alarm)',
        FbBigNumber(value: _S.kcalOverValue, caption: _S.kcalOver, over: true),
      ),
      const GalleryState(
        'huge number',
        FbBigNumber(value: _S.hugeValue, caption: _S.kcalLeft),
      ),
    ],
  ),
  GallerySection(
    name: 'FbProgressBar',
    covers: const [FbProgressBar],
    states: (_) => [
      const GalleryState('empty', FbProgressBar(value: 0, target: 2000)),
      const GalleryState('half', FbProgressBar(value: 1000, target: 2000)),
      const GalleryState('full', FbProgressBar(value: 2000, target: 2000)),
      const GalleryState('over', FbProgressBar(value: 2400, target: 2000)),
    ],
  ),
  GallerySection(
    name: 'FbMacroBars',
    covers: const [FbMacroBars, FbMacroValue, FbMacroKind],
    states: (_) => [
      const GalleryState(
        'normal',
        FbMacroBars(
          macros: [
            FbMacroValue(
              kind: FbMacroKind.protein,
              value: 82,
              target: 140,
              label: _S.protein,
              valueText: '82 / 140 g',
            ),
            FbMacroValue(
              kind: FbMacroKind.carbs,
              value: 120,
              target: 220,
              label: _S.carbs,
              valueText: '120 / 220 g',
            ),
            FbMacroValue(
              kind: FbMacroKind.fat,
              value: 30,
              target: 70,
              label: _S.fat,
              valueText: '30 / 70 g',
            ),
            FbMacroValue(
              kind: FbMacroKind.fiber,
              value: 12,
              target: 30,
              label: _S.fiber,
              valueText: '12 / 30 g',
            ),
          ],
        ),
      ),
      const GalleryState(
        'protein and fibre over',
        FbMacroBars(
          macros: [
            FbMacroValue(
              kind: FbMacroKind.protein,
              value: 150,
              target: 140,
              label: _S.protein,
              valueText: '10 g over',
            ),
            FbMacroValue(
              kind: FbMacroKind.carbs,
              value: 120,
              target: 220,
              label: _S.carbs,
              valueText: '120 / 220 g',
            ),
            FbMacroValue(
              kind: FbMacroKind.fat,
              value: 30,
              target: 70,
              label: _S.fat,
              valueText: '30 / 70 g',
            ),
            FbMacroValue(
              kind: FbMacroKind.fiber,
              value: 35,
              target: 30,
              label: _S.fiber,
              valueText: '5 g over',
            ),
          ],
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbChips',
    covers: const [
      FbAssumptionChip,
      FbAnswerChip,
      FbQuickAddChip,
      FbQuickAddRow,
      FbIconButton,
    ],
    states: (_) => [
      GalleryState(
        'assumption',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbAssumptionChip(label: _S.assumption, onTap: () {}),
        ),
      ),
      GalleryState(
        'answer: default, default marked, selected',
        Wrap(
          spacing: FbSpace.s2,
          children: [
            FbAnswerChip(label: _S.small, onTap: () {}),
            FbAnswerChip(label: _S.medium, isDefault: true, onTap: () {}),
            FbAnswerChip(label: _S.large, selected: true, onTap: () {}),
          ],
        ),
      ),
      GalleryState(
        'quick add',
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            FbQuickAddChip(label: _S.coffee, onTap: () {}),
            FbQuickAddChip.add(label: _S.banana, onTap: () {}),
            FbQuickAddChip.add(label: _S.yoghurt, onTap: () {}),
          ],
        ),
      ),
      GalleryState(
        'quick add row, with a meal chip and a plus',
        FbQuickAddRow(
          chips: [
            FbQuickAddChip(label: _S.coffee, onTap: () {}),
            FbQuickAddChip(label: _S.banana, icon: FbIcons.meal, onTap: () {}),
            FbQuickAddChip(label: _S.yoghurt, onTap: () {}),
          ],
          addLabel: _S.addFood,
          onAdd: () {},
        ),
      ),
      GalleryState(
        'icon button: enabled, disabled',
        Row(
          children: [
            FbIconButton(
              icon: FbIcons.edit,
              tooltip: _S.rename,
              onPressed: () {},
            ),
            FbIconButton(
              icon: FbIcons.more,
              tooltip: _S.more,
              onPressed: () {},
            ),
            const FbIconButton(
              icon: FbIcons.delete,
              tooltip: _S.delete,
              onPressed: null,
            ),
          ],
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbSkeleton',
    covers: const [FbSkeleton],
    states: (_) => [
      const GalleryState('line', FbSkeleton.line()),
      const GalleryState('short line', FbSkeleton.line(width: 120)),
      const GalleryState(
        'box',
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbSkeleton.box(width: 56, height: 56),
        ),
      ),
      const GalleryState('card', FbSkeleton.card()),
    ],
  ),
  GallerySection(
    name: 'FbEmptyState',
    covers: const [FbEmptyState],
    states: (_) => [
      GalleryState(
        'with action',
        FbEmptyState(
          icon: FbIcons.empty,
          title: _S.emptyTitle,
          message: _S.emptyMessage,
          action: FbButton.primary(label: _S.addFood, onPressed: () {}),
        ),
      ),
      const GalleryState(
        'no action',
        FbEmptyState(
          icon: FbIcons.chart,
          title: _S.emptyTitle,
          message: _S.emptyMessage,
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbInlineBanner',
    covers: const [FbInlineBanner, FbInlineBannerKind],
    states: (_) => [
      const GalleryState(
        'info',
        FbInlineBanner(kind: FbInlineBannerKind.info, message: _S.bannerInfo),
      ),
      const GalleryState(
        'offline',
        FbInlineBanner(
          kind: FbInlineBannerKind.offline,
          message: _S.bannerOffline,
        ),
      ),
      const GalleryState(
        'pending',
        FbInlineBanner(
          kind: FbInlineBannerKind.pending,
          message: _S.bannerPending,
        ),
      ),
      const GalleryState(
        'error',
        FbInlineBanner(kind: FbInlineBannerKind.error, message: _S.bannerError),
      ),
      GalleryState(
        'error with action',
        FbInlineBanner(
          kind: FbInlineBannerKind.error,
          message: _S.bannerErrorLong,
          actionLabel: _S.retry,
          onAction: () {},
        ),
      ),
    ],
  ),
];
