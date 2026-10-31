import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// A lazily built, named page of an [FbSlideCard].
class FbSlide {
  /// Creates the component with localized labels and session state.
  const new({required this.label, required this.builder});

  /// Localized name announced by assistive technology.
  final String label;

  /// Builds this slide only when the pager needs it.
  final WidgetBuilder builder;
}

/// A fixed-height summary pager. Drags stay here, including at its edges.
class FbSlideCard extends StatefulWidget {
  /// Creates the component with localized labels and session state.
  const new({
    required this.slides,
    required this.index,
    required this.onIndexChanged,
    required this.height,
    required this.semanticLabel,
    this.pagerKey,
    super.key,
  });

  /// Pages in their display order.
  final List<FbSlide> slides;

  /// The selected page, shared with the parent.
  final int index;

  /// Reports a user-selected page.
  final ValueChanged<int> onIndexChanged;

  /// Final content height in logical pixels, resolved by the caller.
  /// Text scaling is deliberately not applied again inside this pager.
  final double height;

  /// Localized page name and position.
  final String Function(String name, int n, int count) semanticLabel;

  /// Optional identity for the inner pager.
  final Key? pagerKey;
  @override
  State<FbSlideCard> createState() => _FbSlideCardState();
}

class _FbSlideCardState extends State<FbSlideCard> {
  late final PageController _controller = PageController(
    initialPage: widget.index,
  );
  @override
  void didUpdateWidget(FbSlideCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index &&
        _controller.hasClients &&
        _controller.page?.round() != widget.index) {
      _controller.jumpToPage(widget.index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index < 0 || index >= widget.slides.length) return;
    final motion = FbMotion.of(context);
    if (motion == Duration.zero) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(index, duration: motion, curve: FbMotion.curve);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: widget.semanticLabel(
      widget.slides[widget.index].label,
      widget.index + 1,
      widget.slides.length,
    ),
    onIncrease: widget.index < widget.slides.length - 1
        ? () => _select(widget.index + 1)
        : null,
    onDecrease: widget.index > 0 ? () => _select(widget.index - 1) : null,
    child: Column(
      children: [
        FbCard(
          key: const ValueKey('fb-slide-card'),
          padding: EdgeInsetsDirectional.zero,
          child: SizedBox(
            height: widget.height,
            child: ClipRect(
              child: PageView.builder(
                key: widget.pagerKey,
                controller: _controller,
                itemCount: widget.slides.length,
                onPageChanged: (index) {
                  if (index != widget.index) {
                    widget.onIndexChanged(index);
                    unawaited(
                      SemanticsService.sendAnnouncement(
                        View.of(context),
                        widget.semanticLabel(
                          widget.slides[index].label,
                          index + 1,
                          widget.slides.length,
                        ),
                        Directionality.of(context),
                      ),
                    );
                  }
                },
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: FbDensity.cardPadding,
                    vertical: FbDensity.blockGap,
                  ),
                  child: widget.slides[index].builder(context),
                ),
              ),
            ),
          ),
        ),
        FbPageDots(
          count: widget.slides.length,
          index: widget.index,
          labels: [for (final slide in widget.slides) slide.label],
          onSelect: _select,
        ),
      ],
    ),
  );
}

/// Named, selected dots with 48 dp touch targets and a wider active pill.
class FbPageDots extends StatelessWidget {
  /// Creates the component with localized labels and session state.
  const new({
    required this.count,
    required this.index,
    required this.labels,
    required this.onSelect,
    super.key,
  });

  /// Number of page targets.
  final int count;

  /// The selected page, shared with the parent.
  final int index;

  /// Localized names of the page targets.
  final List<String> labels;

  /// Selects a page by tapping its dot.
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        Semantics(
          label: labels[i],
          selected: i == index,
          button: true,
          child: InkWell(
            key: ValueKey('fb-slide-dot-$i'),
            onTap: () => onSelect(i),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: i == index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: i == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
