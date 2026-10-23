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
      const GalleryState('tap the date to pick one', _DatePickerDemo()),
    ],
  ),
  GallerySection(
    name: 'FbDisclosureRow',
    covers: const [FbDisclosureRow],
    states: (_) => const [
      GalleryState('tap to open and close', _DisclosureDemo()),
      GalleryState('title only', _DisclosureDemo(withDetails: false)),
    ],
  ),
  GallerySection(
    name: 'FbSwipeActions',
    covers: const [FbSwipeActions, FbSwipeAction],
    states: (context) => [
      GalleryState(
        'swipe either way (delete leaves, move snaps back)',
        _SwipeDemo(
          onDelete: () => showFbSnackBar(context, _S.deleted),
          onMove: () => showFbSnackBar(context, _S.moveAsked),
        ),
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
    name: 'FbChoiceChip',
    covers: const [FbChoiceChip],
    states: (_) => [
      GalleryState(
        'label and value',
        _start(
          FbChoiceChip(label: _S.mealChipLabel, value: _S.lunch, onTap: () {}),
        ),
      ),
      GalleryState(
        'selected',
        _start(
          FbChoiceChip(
            label: _S.mealChipLabel,
            value: _S.lunch,
            selected: true,
            onTap: () {},
          ),
        ),
      ),
      const GalleryState(
        'disabled',
        FbChoiceChip(label: _S.mealChipLabel, value: _S.lunch, onTap: null),
      ),
      GalleryState(
        'label only, no arrow',
        _start(
          FbChoiceChip(label: _S.assumption, dropdown: false, onTap: () {}),
        ),
      ),
      const GalleryState('tap to pick a time', _TimeChipDemo()),
    ],
  ),
  GallerySection(
    name: 'FbTextField',
    covers: const [FbTextField],
    states: (_) => const [
      GalleryState('type to try it (60 characters)', _TextFieldDemo()),
      GalleryState('error', _TextFieldDemo(errorText: _S.nameFieldError)),
    ],
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

/// A text field with a counter and a clear button.
class _TextFieldDemo extends StatefulWidget {
  const new({this.errorText});

  final String? errorText;

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FbTextField(
    controller: _controller,
    label: _S.nameFieldLabel,
    hint: _S.nameFieldHint,
    maxLength: 60,
    errorText: widget.errorText,
    textInputAction: TextInputAction.done,
  );
}

/// A time chip whose tap opens the time picker and shows the picked time.
class _TimeChipDemo extends StatefulWidget {
  const new();

  @override
  State<_TimeChipDemo> createState() => _TimeChipDemoState();
}

class _TimeChipDemoState extends State<_TimeChipDemo> {
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 30);

  @override
  Widget build(BuildContext context) => _start(
    FbChoiceChip(
      label: _S.timeChipLabel,
      value: MaterialLocalizations.of(context).formatTimeOfDay(_time),
      onTap: () async {
        final picked = await showFbTimePicker(context, initialTime: _time);
        if (picked != null) setState(() => _time = picked);
      },
    ),
  );
}

/// A date header whose date opens the picker and shows the picked day.
class _DatePickerDemo extends StatefulWidget {
  const new();

  @override
  State<_DatePickerDemo> createState() => _DatePickerDemoState();
}

class _DatePickerDemoState extends State<_DatePickerDemo> {
  // Sample days, not "today": the gallery shows a fixed calendar.
  static final _last = DateTime(2026, 10, 20);
  DateTime _day = DateTime(2026, 10, 15);

  @override
  Widget build(BuildContext context) => FbDateHeader(
    label: MaterialLocalizations.of(context).formatMediumDate(_day),
    onPrevious: () =>
        setState(() => _day = _day.subtract(const Duration(days: 1))),
    onNext: _day.isBefore(_last)
        ? () => setState(() => _day = _day.add(const Duration(days: 1)))
        : null,
    onLabelTap: () async {
      final picked = await showFbDatePicker(
        context,
        initialDate: _day,
        lastDate: _last,
      );
      if (picked != null) setState(() => _day = picked);
    },
  );
}

/// A disclosure row that opens and closes a few rows below it.
class _DisclosureDemo extends StatefulWidget {
  const new({this.withDetails = true});

  final bool withDetails;

  @override
  State<_DisclosureDemo> createState() => _DisclosureDemoState();
}

class _DisclosureDemoState extends State<_DisclosureDemo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FbDisclosureRow(
        title: _S.chickenAndRiceDish,
        subtitle: widget.withDetails ? _S.threeItems : null,
        leading: widget.withDetails ? const Icon(FbIcons.diary) : null,
        trailing: widget.withDetails ? const Text(_S.dishKcal) : null,
        expanded: _open,
        onToggle: () => setState(() => _open = !_open),
      ),
      if (_open) ...const [
        FbListRow(title: _S.oats, trailing: Text(_S.oatsKcal)),
        FbListRow(title: _S.banana, trailing: Text(_S.oatsKcal)),
      ],
    ],
  );
}

/// A row with both swipe actions; the callbacks come from the section.
class _SwipeDemo extends StatefulWidget {
  const new({required this.onDelete, required this.onMove});

  final VoidCallback onDelete;
  final VoidCallback onMove;

  @override
  State<_SwipeDemo> createState() => _SwipeDemoState();
}

class _SwipeDemoState extends State<_SwipeDemo> {
  bool _deleted = false;

  @override
  Widget build(BuildContext context) {
    if (_deleted) return const SizedBox.shrink();
    return FbSwipeActions(
      dismissAction: FbSwipeAction(
        label: _S.swipeDelete,
        icon: FbIcons.delete,
        onTriggered: () {
          widget.onDelete();
          setState(() => _deleted = true);
        },
      ),
      confirmAction: FbSwipeAction(
        label: _S.swipeMove,
        icon: FbIcons.move,
        onTriggered: widget.onMove,
      ),
      child: const FbListRow(
        title: _S.oats,
        subtitle: _S.oatsAmount,
        trailing: Text(_S.oatsKcal),
      ),
    );
  }
}
