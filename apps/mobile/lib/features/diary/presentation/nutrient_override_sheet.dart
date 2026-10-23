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

/// Opens the sheet that sets one nutrient of [entry] to the user's own value
/// (AI-072, A08 D8). The value is for the logged amount; the item is then
/// marked "edited by you".
Future<void> showNutrientOverrideSheet(
  BuildContext context,
  DiaryEntry entry,
  NutrientField field,
) => showFbSheet<void>(
  context,
  title: field == NutrientField.kcal
      ? context.l10n.diaryOverrideTitleEnergy
      : context.l10n.diaryOverrideTitle(nutrientLabel(context.l10n, field)),
  builder: (_) => NutrientOverrideSheet(entry: entry, field: field),
);

/// The body of the override sheet: the typed value, the number pad and Save.
class NutrientOverrideSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [field] of [entry], at the version it was opened
  /// with.
  const new({required this.entry, required this.field, super.key});

  /// The item.
  final DiaryEntry entry;

  /// The nutrient to set.
  final NutrientField field;

  @override
  ConsumerState<NutrientOverrideSheet> createState() =>
      _NutrientOverrideSheetState();
}

class _NutrientOverrideSheetState extends ConsumerState<NutrientOverrideSheet> {
  /// Whole numbers for kcal and mg, one decimal for grams.
  late final int _decimals = widget.field.unit == 'g' ? 1 : 0;
  late final int _digits = widget.field.unit == 'g' ? 4 : 5;

  NumberPadBuffer? _typed;
  bool _padOpen = true;
  bool _saving = false;
  DiaryActionFailure? _failure;

  /// The typed value, else the item's own (an untouched value follows a
  /// reload; a typed one is kept).
  String _textOf(DiaryEntry entry) =>
      _typed?.text ??
      _initial(entry.snapshot.valueOf(widget.field) ?? 0, _decimals);

  void _onKey(NumberPadKey key, DiaryEntry entry) {
    final empty = NumberPadBuffer(maxDigits: _digits, maxDecimals: _decimals);
    final buffer = _typed == null && key is! NumberPadBackspace
        ? empty
        : _typed ??
              NumberPadBuffer(
                maxDigits: _digits,
                maxDecimals: _decimals,
                text: _textOf(entry),
              );
    setState(() {
      _typed = buffer.apply(key);
      _failure = null;
    });
  }

  Future<void> _save(DiaryEntry entry, double value) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    final outcome = await ref
        .read(diaryActionsControllerProvider.notifier)
        .overrideNutrients(entry, {widget.field: value});
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
            () => host.l10n.diaryNutrientEdited(
              nutrientLabel(host.l10n, widget.field),
              entry.food.names.en,
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
    final scheme = Theme.of(context).colorScheme;
    final entry = live.entry;
    final field = widget.field;
    final text = _textOf(entry);
    final value = double.tryParse(text);
    final tooBig = value != null && value > field.maxValue;
    final unit = switch (field.unit) {
      'kcal' => l10n.diaryUnitKcal,
      'mg' => l10n.diaryUnitMg,
      _ => l10n.unitG,
    };
    final name = nutrientLabel(l10n, field);
    final shown = _shown(l10n, text);
    final pending = ref.watch(
      diaryActionsControllerProvider.select(
        (s) => s.pending.contains(entry.id),
      ),
    );
    final canSave =
        live.canSave &&
        value != null &&
        value.isFinite &&
        !tooBig &&
        !_saving &&
        !pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        StaleEntryBanner(freshness: live.freshness, onReload: live.reload),
        Text(
          entry.food.names.en,
          style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        ),
        FbAmountDisplay(
          amount: shown,
          unit: unit,
          semanticLabel: l10n.diaryOverrideAmountLabel(name, shown, unit),
          active: _padOpen,
          onTap: () => setState(() => _padOpen = !_padOpen),
        ),
        Text(
          l10n.diaryOverrideNote,
          style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (tooBig)
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.diaryOverrideOutOfRange(
              NumberFormat.decimalPattern(l10n.localeName)
                  .format(field.maxValue),
              unit,
            ),
          ),
        if (_padOpen)
          FbNumberPad(
            onKey: (key) => _onKey(key, entry),
            onDone: () => setState(() => _padOpen = false),
            allowDecimal: _decimals > 0,
          ),
        if (_failure == DiaryActionFailure.invalid)
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.diaryOverrideInvalid,
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
        if (value == null && !tooBig)
          Text(
            l10n.diaryValueNeeded,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        FbButton.primary(
          label: l10n.diarySave,
          expand: true,
          onPressed: canSave ? () => _save(entry, value) : null,
        ),
      ],
    );
  }
}

/// `165.0` becomes `165`, `1.60` becomes `1.6`: a stored value as the pad
/// would have typed it.
String _initial(double value, int decimals) {
  final fixed = value.toStringAsFixed(decimals);
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
