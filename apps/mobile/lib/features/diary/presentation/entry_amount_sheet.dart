import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:fb_mobile/features/diary/presentation/live_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// Opens the amount sheet for [entry] (DY-021): the amount and unit, the
/// calories and macros it gives, and Save. The sheet closes itself once the
/// change is made; the Undo snackbar shows on the root messenger.
Future<void> showEntryAmountSheet(BuildContext context, DiaryEntry entry) =>
    showFbSheet<void>(
      context,
      title: entry.food.names.en,
      builder: (_) => EntryAmountSheet(entry: entry),
    );

/// The body of the amount sheet. Units come from the entry itself, so it
/// works offline for every entry; the numbers use the entry's own per-100
/// values, which keeps a nutrient override (A08 D6).
class EntryAmountSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [entry], at the version it was opened with.
  const new({required this.entry, super.key});

  /// The item.
  final DiaryEntry entry;

  @override
  ConsumerState<EntryAmountSheet> createState() => _EntryAmountSheetState();
}

class _EntryAmountSheetState extends ConsumerState<EntryAmountSheet> {
  /// What has been typed on the pad; the first key replaces the amount.
  NumberPadBuffer? _typed;

  /// The unit the user picked; null while untouched, so a reload takes the
  /// reloaded item's own unit.
  String? _unit;

  /// The pad is open from the start: the sheet exists to type.
  bool _padOpen = true;
  bool _saving = false;
  DiaryActionFailure? _failure;

  /// The typed amount, else the item's own (untouched fields follow a
  /// reload; typed ones are kept).
  String _textOf(DiaryEntry entry) =>
      _typed?.text ?? _plain(entry.amount.input.amount.toString());

  void _onKey(NumberPadKey key, DiaryEntry entry) {
    final buffer = _typed == null && key is! NumberPadBackspace
        ? const NumberPadBuffer(maxDecimals: 2)
        : _typed ?? NumberPadBuffer(maxDecimals: 2, text: _textOf(entry));
    setState(() {
      _typed = buffer.apply(key);
      _failure = null;
    });
  }

  Future<void> _save(DiaryEntry entry, Quantity input) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    final outcome = await ref
        .read(diaryActionsControllerProvider.notifier)
        .changeAmount(entry, input);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case DiaryActionFailed(:final reason):
        setState(() => _failure = reason);
      case DiaryActionUnchanged():
        nav.pop();
      case DiaryActionDone():
        nav.pop();
        if (host.mounted) {
          reportDiaryOutcome(
            host,
            outcome,
            () => host.l10n.diaryAmountChanged(
              entry.food.names.en,
              host.l10n.foodResultServing(
                input.amount,
                unitLabel(
                  host.l10n,
                  input.unitCode,
                  input.amount,
                  serving: EntryMeasures.of(entry).servingUnits[input.unitCode],
                ),
              ),
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) =>
      LiveEntryBuilder(opened: widget.entry, builder: _content);

  Widget _content(BuildContext context, LiveEntry live) {
    final l10n = context.l10n;
    final entry = live.entry;
    final measures = EntryMeasures.of(entry);
    final units = UnitOptions.of(measures);
    // A reload may take away the unit that was chosen: fall back to the
    // basis, keep the number.
    final chosen = _unit ?? entry.amount.input.unitCode;
    final unit = units.contains(chosen) ? chosen : measures.basis.unitCode;
    final text = _textOf(entry);
    final typedAmount = double.tryParse(text);
    final input =
        typedAmount == null || !typedAmount.isFinite || typedAmount <= 0
        ? null
        : Quantity(typedAmount, unit);
    final snapshot = input == null
        ? null
        : switch (const NutritionCalculator().compute(
            per100: entry.food.per100,
            measures: measures,
            input: input,
          )) {
            Computed(:final snapshot) => snapshot.nutrients,
            NotComputed() => null,
          };
    String unitName(String code) => unitLabel(
      l10n,
      code,
      typedAmount ?? 1,
      serving: measures.servingUnits[code],
    );
    final pending = ref.watch(
      diaryActionsControllerProvider.select(
        (s) => s.pending.contains(entry.id),
      ),
    );
    final canSave =
        live.canSave &&
        snapshot != null &&
        !_saving &&
        !pending &&
        input != null;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        StaleEntryBanner(freshness: live.freshness, onReload: live.reload),
        FbAmountDisplay(
          amount: _shown(l10n, text),
          unit: unitName(unit),
          semanticLabel: l10n.foodSheetAmountLabel(
            _shown(l10n, text),
            unitName(unit),
          ),
          active: _padOpen,
          onTap: () => setState(() => _padOpen = !_padOpen),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snapshot == null
                  ? l10n.foodSheetNoKcal
                  : l10n.foodSheetKcal(DisplayRounding.kcal(snapshot.kcal)),
              style: FbType.numeric(FbType.headline)
                  .copyWith(color: scheme.onSurface),
            ),
            if (snapshot != null)
              Text(
                l10n.foodSheetMacros(
                  DisplayRounding.nutrientGrams(snapshot.protein),
                  DisplayRounding.nutrientGrams(snapshot.carbs),
                  DisplayRounding.nutrientGrams(snapshot.fat),
                  DisplayRounding.nutrientGrams(snapshot.fiber),
                ),
                style: FbType.numeric(FbType.bodySmall)
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        FbUnitPicker(
          units: [
            for (final code in units)
              FbUnitOption(id: code, label: unitName(code)),
          ],
          selected: unit,
          onSelected: (code) => setState(() {
            _unit = code;
            _failure = null;
          }),
        ),
        if (_padOpen)
          FbNumberPad(
            onKey: (key) => _onKey(key, entry),
            onDone: () => setState(() => _padOpen = false),
          ),
        if (_failure == DiaryActionFailure.invalid)
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.diaryActionFailed,
          )
        // A refused save is never silent: say what happened, unless the live
        // banner above already says it (D12(4)).
        else if (_failure != null && live.freshness == EntryFreshness.fresh)
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: _failure == DiaryActionFailure.removed
                ? l10n.diaryActionRemoved
                : l10n.diaryItemChanged,
          ),
        if (input == null)
          Text(
            l10n.diaryAmountNeeded,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        FbButton.primary(
          label: l10n.diarySave,
          expand: true,
          onPressed: canSave ? () => _save(entry, input) : null,
        ),
      ],
    );
  }
}

/// `100.0` becomes `100`, `1.5` stays `1.5`: the amount as the pad would
/// have typed it.
String _plain(String buffer) {
  final value = double.tryParse(buffer);
  if (value == null) return buffer;
  final fixed = value.toStringAsFixed(2);
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
}

/// The typed [text] with the locale's decimal separator; empty reads as 0.
String _shown(AppLocalizations l10n, String text) {
  if (text.isEmpty) return '0';
  final separator = NumberFormat.decimalPattern(l10n.localeName)
      .symbols
      .DECIMAL_SEP;
  return text.replaceFirst('.', separator);
}
