import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart' show CatalogSanity;
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/foods/application/food_amount_controller.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/foods/application/log_food.dart';
import 'package:fb_mobile/features/foods/presentation/food_sheet_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// The most digits and decimals the amount pad takes (A07 D8).
const NumberPadBuffer _emptyPad = NumberPadBuffer(maxDecimals: 2);

/// The content of the food sheet (A07 WP4): the food, the amount with its
/// calories and macros, the unit, the state choice, the meal and Add.
///
/// It is the body for `showFbSheet`; [openFoodSheet] shows it. It pops with
/// the [FoodLogged] outcome once the food is added, so the caller can close
/// itself and show the undo snackbar (UX-030). The sheet knows its food only
/// by the structured [FoodPick], so A08 (swap) and A28 (scan) can open it too.
class FoodSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [pick].
  const new({required this.pick, super.key});

  /// The tapped result and where the log goes.
  final FoodPick pick;

  @override
  ConsumerState<FoodSheet> createState() => _FoodSheetState();
}

class _FoodSheetState extends ConsumerState<FoodSheet> {
  late final FoodAmountControllerProvider _provider =
      foodAmountControllerProvider(
        widget.pick.row.choiceRef,
        widget.pick.date ?? EntryTime.now(ref.read(clockProvider)).localDate,
        slotId: widget.pick.slotId,
        carried: widget.pick.carried,
      );

  /// The number pad is shown while the amount is being edited.
  bool _padOpen = false;

  /// What has been typed on the pad; `null` until the first key.
  NumberPadBuffer? _typed;

  /// The optional nutrients under "More" are shown.
  bool _more = false;

  /// Adding failed (the sheet stays open).
  bool _failed = false;

  FoodAmountController get _controller => ref.read(_provider.notifier);

  void _onKey(NumberPadKey key, FoodAmountState state) {
    // The first key replaces the prefilled amount (D8); backspace edits it.
    final buffer = _typed == null && key is! NumberPadBackspace
        ? _emptyPad
        : _typed ??
              NumberPadBuffer(maxDecimals: 2, text: _plain(state.amountBuffer));
    final next = buffer.apply(key);
    setState(() {
      _typed = next;
      _failed = false;
    });
    _controller.setAmount(next.text);
  }

  Future<void> _add() async {
    final outcome = await _controller.submit();
    if (!mounted) return;
    switch (outcome) {
      case FoodLogged():
        Navigator.of(context).pop(outcome);
      case FoodLogFailed():
        setState(() => _failed = true);
    }
  }

  Future<void> _chooseSlot(List<MealSlot> slots, String? current) async {
    final l10n = context.l10n;
    final chosen = await showFbSheet<String>(
      context,
      title: l10n.foodSheetSlotTitle,
      builder: (sheet) => Column(
        children: [
          for (final slot in slots)
            FbListRow(
              title: slotLabel(l10n, slot),
              trailing: slot.id == current ? const Icon(FbIcons.check) : null,
              onTap: () => Navigator.of(sheet).pop(slot.id),
            ),
        ],
      ),
    );
    if (chosen != null && mounted) _controller.setSlot(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (ref.watch(_provider)) {
      AsyncData(:final value) => _body(context, value),
      AsyncError() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.foodSheetLoadFailed,
            actionLabel: l10n.foodTryAgain,
            onAction: () {
              ref
                ..invalidate(foodChoiceProvider(widget.pick.row.choiceRef))
                ..invalidate(foodSlotsProvider)
                ..invalidate(_provider);
            },
          ),
          FbButton.text(
            label: l10n.foodSheetClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      _ => const Column(
        spacing: FbSpace.s3,
        children: [
          FbSkeleton.line(height: 24),
          FbSkeleton.line(height: 56),
          FbSkeleton.line(height: 40),
        ],
      ),
    };
  }

  Widget _body(BuildContext context, FoodAmountState state) {
    final l10n = context.l10n;
    final food = state.food;
    final scheme = Theme.of(context).colorScheme;
    final text = _typed?.text ?? _plain(state.amountBuffer);
    final count = double.tryParse(text) ?? 1;
    String unitName(String code) =>
        unitLabel(l10n, code, count, serving: food.measures.servingUnits[code]);
    final slots = [
      for (final slot in ref.watch(foodSlotsProvider).value ?? <MealSlot>[])
        if (slot.active) slot,
    ];
    final slot = slots.where((s) => s.id == state.slotId).firstOrNull;
    final yieldNote = state.yieldNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        _Header(food: food),
        if (food.sanity == CatalogSanity.warn)
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.foodSheetSanityWarn,
          ),
        FbAmountDisplay(
          amount: _shown(l10n, text),
          unit: unitName(state.unit),
          semanticLabel: l10n.foodSheetAmountLabel(
            _shown(l10n, text),
            unitName(state.unit),
          ),
          active: _padOpen,
          onTap: () => setState(() => _padOpen = !_padOpen),
        ),
        _Nutrition(snapshot: state.snapshot),
        FbUnitPicker(
          units: [
            for (final code in state.units)
              FbUnitOption(id: code, label: unitName(code)),
          ],
          selected: state.unit,
          onSelected: (code) {
            setState(() => _failed = false);
            _controller.setUnit(code);
          },
        ),
        if (food.siblings.isNotEmpty)
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              for (final sibling in food.siblings)
                FbAnswerChip(
                  label: l10n.foodSheetLogAs(sibling.nameEn),
                  onTap: () {
                    if (_controller.switchState(sibling.id)) {
                      setState(() => _failed = false);
                    }
                  },
                ),
            ],
          ),
        if (yieldNote != null)
          Text(
            l10n.foodSheetYieldNote(
              DisplayRounding.foodAmount(yieldNote.fromAmount.grams),
              l10n.foodStateWord(yieldNote.fromState.code),
              yieldNote.toGramsForNote,
              l10n.foodStateWord(yieldNote.toState.code),
            ),
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbQuickAddChip(
            label: l10n.foodSheetSlot(
              slot == null ? l10n.foodSheetSlotNone : slotLabel(l10n, slot),
            ),
            onTap: () => _chooseSlot(slots, state.slotId),
          ),
        ),
        if (_padOpen)
          FbNumberPad(
            onKey: (key) => _onKey(key, state),
            onDone: () => setState(() => _padOpen = false),
          ),
        if (_failed)
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.foodSheetAddFailed,
          ),
        FbButton.primary(
          label: l10n.foodSheetAdd,
          expand: true,
          onPressed: state.canAdd ? _add : null,
        ),
        _PerHundred(
          food: food,
          showMore: _more,
          onToggleMore: () => setState(() => _more = !_more),
        ),
      ],
    );
  }
}

/// `100.0` → `100`, `1.5` → `1.5`: the amount as the pad would have typed it.
String _plain(String buffer) {
  final value = double.tryParse(buffer);
  if (value == null) return buffer;
  final fixed = value.toStringAsFixed(2);
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
}

/// The typed [text] with the locale's decimal separator; an empty amount
/// reads as 0.
String _shown(AppLocalizations l10n, String text) {
  if (text.isEmpty) return '0';
  final separator = NumberFormat.decimalPattern(l10n.localeName)
      .symbols
      .DECIMAL_SEP;
  return text.replaceFirst('.', separator);
}

class _Header extends StatelessWidget {
  const new({required this.food});

  final FoodChoice food;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ar = food.names.ar;
    final state = food.state;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FbSourceBadge(source: fbSourceOf(food.badge)),
        const SizedBox(width: FbSpace.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  ar == null
                      ? food.names.en
                      : l10n.foodSheetNames(food.names.en, ar),
                  style: FbType.title.copyWith(color: scheme.onSurface),
                ),
              ),
              if (state != null)
                Text(
                  l10n.foodSheetState(l10n.foodStateWord(state.code)),
                  style: FbType.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Calories (large) and the four macros of the chosen amount.
class _Nutrition extends StatelessWidget {
  const new({required this.snapshot});

  final NutrientSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final n = snapshot?.nutrients;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n == null
              ? l10n.foodSheetNoKcal
              : l10n.foodSheetKcal(DisplayRounding.kcal(n.kcal)),
          style: FbType.numeric(FbType.headline)
              .copyWith(color: scheme.onSurface),
        ),
        if (n != null)
          Text(
            l10n.foodSheetMacros(
              DisplayRounding.nutrientGrams(n.protein),
              DisplayRounding.nutrientGrams(n.carbs),
              DisplayRounding.nutrientGrams(n.fat),
              DisplayRounding.nutrientGrams(n.fiber),
            ),
            style: FbType.numeric(FbType.bodySmall)
                .copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// The values per 100 g or ml, with the optional ones under "More" (FD-002).
class _PerHundred extends StatelessWidget {
  const new({
    required this.food,
    required this.showMore,
    required this.onToggleMore,
  });

  final FoodChoice food;
  final bool showMore;
  final VoidCallback onToggleMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final n = food.per100;
    final extras = [
      for (final key in NutrientKey.values)
        if (n.extra(key) case final value?) (key, value),
    ];
    String grams(double v) =>
        l10n.foodNutrientGrams(DisplayRounding.nutrientGrams(v));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: scheme.outlineVariant),
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s1),
          child: Semantics(
            header: true,
            child: Text(
              food.basis == NutrientBasis.per100g
                  ? l10n.foodSheetPer100g
                  : l10n.foodSheetPer100ml,
              style: FbType.label.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
        _NutrientRow(
          l10n.foodNutrientEnergy,
          l10n.foodSheetKcal(DisplayRounding.kcal(n.kcal)),
        ),
        _NutrientRow(l10n.foodNutrientProtein, grams(n.protein)),
        _NutrientRow(l10n.foodNutrientCarbs, grams(n.carbs)),
        _NutrientRow(l10n.foodNutrientFat, grams(n.fat)),
        _NutrientRow(l10n.foodNutrientFiber, grams(n.fiber)),
        if (extras.isNotEmpty) ...[
          if (showMore)
            for (final (key, value) in extras)
              _NutrientRow(
                nutrientKeyLabel(l10n, key),
                key.unit == NutrientUnit.milligram
                    ? l10n.foodNutrientMilligrams(
                        DisplayRounding.milligrams(value).toDouble(),
                      )
                    : grams(value),
              ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbButton.text(
              label: showMore ? l10n.foodSheetLess : l10n.foodSheetMore,
              onPressed: onToggleMore,
            ),
          ),
        ],
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const new(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: FbSpace.s3),
            Text(
              value,
              style: FbType.numeric(FbType.bodySmall)
                  .copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
