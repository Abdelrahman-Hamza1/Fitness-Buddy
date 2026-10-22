import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/application/gallery_samples.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_section.dart';
import 'package:material_ui/material_ui.dart';

typedef _S = GallerySamples;

Widget _start(Widget child) =>
    Align(alignment: AlignmentDirectional.centerStart, child: child);

/// Input, navigation, overlay and chart components.
final List<GallerySection> gallerySectionsInput = [
  GallerySection(
    name: 'FbDateHeader',
    covers: const [FbDateHeader],
    states: (_) => [
      GalleryState(
        'both enabled',
        FbDateHeader(label: _S.yesterday, onPrevious: () {}, onNext: () {}),
      ),
      GalleryState(
        'next disabled',
        FbDateHeader(label: _S.today, onPrevious: () {}),
      ),
      GalleryState(
        'long label',
        FbDateHeader(label: _S.longDate, onPrevious: () {}, onNext: () {}),
      ),
    ],
  ),
  GallerySection(
    name: 'FbInputBar',
    covers: const [FbInputBar],
    states: (_) => [
      GalleryState(
        'text, camera and barcode',
        FbInputBar(
          hint: _S.hint,
          onTap: () {},
          onCamera: () {},
          onBarcode: () {},
        ),
      ),
      GalleryState('text only', FbInputBar(hint: _S.hint, onTap: () {})),
      GalleryState(
        'long hint',
        FbInputBar(
          hint: _S.longHint,
          onTap: () {},
          onCamera: () {},
          onBarcode: () {},
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbSearchField',
    covers: const [FbSearchField],
    states: (_) => const [GalleryState('type to try it', _SearchFieldDemo())],
  ),
  GallerySection(
    name: 'FbAmountDisplay',
    covers: const [FbAmountDisplay],
    states: (_) => [
      GalleryState(
        'idle',
        FbAmountDisplay(
          amount: _S.amountNumber,
          unit: _S.amountUnit,
          semanticLabel: _S.amountLabel,
          onTap: () {},
        ),
      ),
      GalleryState(
        'editing',
        FbAmountDisplay(
          amount: _S.amountNumber,
          unit: _S.amountUnit,
          semanticLabel: _S.amountLabel,
          active: true,
          onTap: () {},
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbNumberPad',
    covers: const [
      FbNumberPad,
      NumberPadBuffer,
      NumberPadKey,
      NumberPadDigit,
      NumberPadDecimal,
      NumberPadBackspace,
    ],
    states: (_) => const [
      GalleryState('decimal (type to try it)', _NumberPadDemo()),
      GalleryState('integer only', _NumberPadDemo(allowDecimal: false)),
    ],
  ),
  GallerySection(
    name: 'FbUnitPicker',
    covers: const [FbUnitPicker, FbUnitOption],
    states: (_) => const [GalleryState('interactive', _UnitPickerDemo())],
  ),
  GallerySection(
    name: 'FbSheet',
    covers: const [FbSheet],
    states: (context) => [
      const GalleryState(
        'titled',
        FbSheet(title: _S.sheetTitle, child: Text(_S.sheetBody)),
      ),
      const GalleryState('untitled', FbSheet(child: Text(_S.sheetBody))),
      GalleryState(
        'as a modal',
        _start(
          FbButton.secondary(
            label: context.l10n.previewOpenSheet,
            onPressed: () => showFbSheet<void>(
              context,
              title: _S.sheetTitle,
              builder: (_) => const Text(_S.sheetBody),
            ),
          ),
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbSnackBar',
    covers: const [FbSnackBarHandle],
    states: (context) => [
      GalleryState(
        'undo (5 s window)',
        _start(
          FbButton.secondary(
            label: context.l10n.previewShowUndoSnackBar,
            onPressed: () => showFbUndoSnackBar(
              context,
              message: _S.loggedOats,
              onUndo: () {},
            ),
          ),
        ),
      ),
      GalleryState(
        'plain',
        _start(
          FbButton.secondary(
            label: context.l10n.previewShowSnackBar,
            onPressed: () => showFbSnackBar(context, _S.weightSaved),
          ),
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbSourceBadge',
    covers: const [FbSourceBadge, FbSource, FbEstimateMarker],
    states: (context) => [
      GalleryState(
        'all sources and the estimate marker (tap one)',
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final source in FbSource.values)
              FbSourceBadge(
                source: source,
                onTap: () => showFbSourceLegend(context),
              ),
            const FbEstimateMarker(
              rangeText: _S.estimateRange,
              reason: _S.estimateReason,
            ),
          ],
        ),
      ),
      GalleryState(
        'source legend sheet',
        _start(
          FbButton.secondary(
            label: context.l10n.previewOpenSourceLegend,
            onPressed: () => showFbSourceLegend(context),
          ),
        ),
      ),
      GalleryState(
        'estimate range sheet',
        _start(
          FbButton.secondary(
            label: context.l10n.previewOpenEstimateRange,
            onPressed: () => showFbEstimateRange(
              context,
              rangeText: _S.estimateRange,
              reason: _S.estimateReason,
            ),
          ),
        ),
      ),
    ],
  ),
  GallerySection(
    name: 'FbTimeSeriesChart',
    covers: const [
      FbTimeSeriesChart,
      FbPoint,
      FbSeries,
      FbSeriesStyle,
      FbBand,
      FbBandPoint,
      FbGoalLine,
      FbChartRange,
    ],
    states: (_) => [
      GalleryState(
        'placeholder',
        FbTimeSeriesChart(
          series: [
            FbSeries(
              points: [
                FbPoint(DateTime(2026, 10), 80),
                FbPoint(DateTime(2026, 10, 8), 79.5),
              ],
            ),
          ],
          range: FbChartRange(
            start: DateTime(2026, 10),
            end: DateTime(2026, 10, 8),
          ),
        ),
      ),
    ],
  ),
];

/// A number pad that fills a buffer, so the keys can be tried.
class _NumberPadDemo extends StatefulWidget {
  const new({this.allowDecimal = true});

  final bool allowDecimal;

  @override
  State<_NumberPadDemo> createState() => _NumberPadDemoState();
}

class _NumberPadDemoState extends State<_NumberPadDemo> {
  NumberPadBuffer _buffer = const NumberPadBuffer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _buffer.isEmpty ? '0' : _buffer.text,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        FbNumberPad(
          allowDecimal: widget.allowDecimal,
          onKey: (key) => setState(() => _buffer = _buffer.apply(key)),
          onDone: () => setState(() => _buffer = const NumberPadBuffer()),
        ),
      ],
    );
  }
}

/// A unit picker that keeps its selection.
class _UnitPickerDemo extends StatefulWidget {
  const new();

  @override
  State<_UnitPickerDemo> createState() => _UnitPickerDemoState();
}

class _UnitPickerDemoState extends State<_UnitPickerDemo> {
  static const _units = [
    FbUnitOption(id: 'g', label: _S.gram),
    FbUnitOption(id: 'ml', label: _S.millilitre),
    FbUnitOption(id: 'piece', label: _S.piece),
    FbUnitOption(id: 'cup', label: _S.cup),
  ];

  String _selected = 'g';

  @override
  Widget build(BuildContext context) {
    return FbUnitPicker(
      units: _units,
      selected: _selected,
      onSelected: (id) => setState(() => _selected = id),
    );
  }
}

/// A search field that keeps its text (the clear button shows with text).
class _SearchFieldDemo extends StatefulWidget {
  const new();

  @override
  State<_SearchFieldDemo> createState() => _SearchFieldDemoState();
}

class _SearchFieldDemoState extends State<_SearchFieldDemo> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FbSearchField(controller: _controller, hint: _S.searchHint);
}
