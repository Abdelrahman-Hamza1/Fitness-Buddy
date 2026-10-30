import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/assumption_labels.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/proposal_labels.dart';
import 'package:material_ui/material_ui.dart';

/// One item of a food card (AI-031): name, amount + unit, kcal and its
/// source badge, or `~` with the range and reason (AI-032).
///
/// Tapping the amount opens an inline editor under the line (AI-040,
/// UX-022): unit chips and the number pad; every valid key recomputes the
/// card through [onSetAmount]. The system keyboard is closed meanwhile.
class ProposalLineRow extends StatefulWidget {
  /// The row for [line], amounts in [system]; the callbacks are null on a
  /// card that can't be adjusted (being logged).
  const new({
    required this.line,
    required this.system,
    this.onStep,
    this.onSwap,
    this.onSetAmount,
    super.key,
  });

  /// The item.
  final FoodLineView line;

  /// The display unit system.
  final UnitSystem system;

  /// − (`false`) / + (`true`) on an assumed amount (AI-040).
  final ValueChanged<bool>? onStep;

  /// Opens the alternatives and search (AI-041).
  final VoidCallback? onSwap;

  /// Sets the amount from the inline editor (AI-040).
  final ValueChanged<Quantity>? onSetAmount;

  @override
  State<ProposalLineRow> createState() => _ProposalLineRowState();
}

class _ProposalLineRowState extends State<ProposalLineRow> {
  bool _open = false;

  /// What was typed since the editor opened; the first key replaces the
  /// amount shown.
  NumberPadBuffer? _typed;

  FoodLineView get line => widget.line;
  UnitSystem get system => widget.system;

  @override
  void didUpdateWidget(ProposalLineRow old) {
    super.didUpdateWidget(old);
    // Read-only again (being logged, a follow-up in flight): close it.
    if (widget.onSetAmount == null && _open) _open = false;
  }

  void _toggle() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _open = !_open;
      _typed = null;
    });
  }

  void _onKey(NumberPadKey key) {
    final buffer = (_typed ?? const NumberPadBuffer(maxDecimals: 2)).apply(key);
    setState(() => _typed = buffer);
    final value = buffer.value;
    if (value != null && value > 0) {
      widget.onSetAmount?.call(Quantity(value, line.amount.input.unitCode));
    }
  }

  void _onUnit(String code) {
    final value = _typed?.value ?? line.amount.input.amount;
    if (value > 0) widget.onSetAmount?.call(Quantity(value, code));
  }

  String? _note(AppLocalizations l10n) {
    final notes = [
      for (final raw in line.assumptions)
        if (isCardAssumption(raw)) assumptionText(l10n, raw, system: system),
    ];
    return notes.isEmpty ? null : notes.reduce(l10n.proposalNoteJoin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row = _line(context, l10n);
    if (!_open || widget.onSetAmount == null) return row;
    final input = line.amount.input;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        row,
        FbUnitPicker(
          units: [
            for (final code in line.editUnits)
              FbUnitOption(
                id: code,
                label: unitLabel(l10n, code, input.amount, system: system),
              ),
          ],
          selected: input.unitCode,
          onSelected: _onUnit,
        ),
        FbNumberPad(onKey: _onKey, onDone: _toggle),
      ],
    );
  }

  Widget _line(BuildContext context, AppLocalizations l10n) {
    final amount = line.amount;
    final range = line.line.range ?? line.food.provenance.range;
    final reason = line.reason;
    final Widget marker = line.isEstimate
        ? FbEstimateMarker(
            rangeText: range == null
                ? kcalText(l10n, line.line.snapshot.kcal)
                : l10n.proposalEstimateRange(
                    kcalText(l10n, range.lowKcal),
                    kcalText(l10n, range.highKcal),
                  ),
            reason: reason == null ? '' : estimateReasonText(l10n, reason),
          )
        : FbSourceBadge(source: fbSourceOf(line.food.provenance.source));
    final onStep = widget.onStep;
    final stepper = line.amountAssumed;
    final canDecrease = onStep != null && AmountStep.down(amount.input) != null;
    return FbProposalLine(
      stepper: stepper,
      onDecrease: stepper && canDecrease ? () => onStep(false) : null,
      onIncrease: stepper && onStep != null ? () => onStep(true) : null,
      decreaseTooltip: l10n.proposalAmountLess(line.food.names.en),
      increaseTooltip: l10n.proposalAmountMore(line.food.names.en),
      onNameTap: widget.onSwap,
      onAmountTap: widget.onSetAmount == null ? null : _toggle,
      name: line.food.names.en,
      // While typing, the pad's buffer as typed ("1.", "0"), even before
      // it's a valid amount; otherwise the card's amount.
      amount: switch (_open ? _typed?.text : null) {
        final typed? when typed.isNotEmpty => l10n.proposalAmountTyping(
          typed,
          unitLabel(
            l10n,
            amount.input.unitCode,
            _typed?.value ?? 0,
            system: system,
          ),
        ),
        _ => foodAmountText(
          l10n,
          input: amount.input,
          amount: amount.amount,
          basis: amount.basis,
          system: system,
        ),
      },
      kcal: l10n.proposalItemKcal(kcalText(l10n, line.line.snapshot.kcal)),
      marker: marker,
      // What the number rests on (a yield conversion, a share, the oil).
      note: _note(l10n),
    );
  }
}
