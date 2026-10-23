import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:fb_mobile/features/diary/presentation/live_meal.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// The longest name of a saved meal.
const int savedMealNameMaxLength = 60;

/// Opens the sheet that saves the items of [section] of [date] as a saved
/// meal (DY-023, A08 D11). The saved meals' list arrives with A09.
Future<void> showSaveMealSheet(
  BuildContext context, {
  required SlotSection section,
  required LocalDate date,
}) => showFbSheet<void>(
  context,
  title: context.l10n.diarySaveTitle,
  builder: (_) => SaveMealSheet(section: section, date: date),
);

/// The body of the save sheet: a name (1 to 60 characters) and Save.
class SaveMealSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [section] of [date].
  const new({required this.section, required this.date, super.key});

  /// The meal as shown when the sheet opened.
  final SlotSection section;

  /// The meal's day.
  final LocalDate date;

  @override
  ConsumerState<SaveMealSheet> createState() => _SaveMealSheetState();
}

class _SaveMealSheetState extends ConsumerState<SaveMealSheet> {
  // Prefilled with the meal's name and selected, so typing replaces it. Made
  // on first use (the first build), when the strings are reachable.
  late final TextEditingController _name = _newController();
  bool _touched = false;
  bool _saving = false;
  DiaryActionFailure? _failure;

  TextEditingController _newController() {
    final l10n = context.l10n;
    final slot = widget.section.slot;
    final text = slot == null ? l10n.diarySlotOther : slotLabel(l10n, slot);
    return TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _trimmed => _name.text.trim();

  bool get _validName =>
      _trimmed.isNotEmpty && _trimmed.length <= savedMealNameMaxLength;

  Future<void> _save(LiveMeal live) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final name = _trimmed;
    setState(() => _saving = true);
    final outcome = await ref
        .read(diaryActionsControllerProvider.notifier)
        .saveMeal(live.section, name);
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
            () => host.l10n.diaryMealSaved(name),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) => LiveMealBuilder(
    opened: widget.section,
    date: widget.date,
    builder: _content,
  );

  Widget _content(BuildContext context, LiveMeal live) {
    final l10n = context.l10n;
    final canSave = live.usable && _validName && !_saving;
    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          StaleMealBanner(live: live),
          Text(
            l10n.diaryMealSummary(
              mealEntries(live.section).length,
              mealKcal(live.section),
            ),
            style: FbType.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          FbTextField(
            controller: _name,
            label: l10n.diarySaveName,
            maxLength: savedMealNameMaxLength,
            autofocus: true,
            textInputAction: TextInputAction.done,
            errorText: _touched && _trimmed.isEmpty
                ? l10n.diarySaveNameEmpty
                : null,
            onChanged: (_) => setState(() {
              _touched = true;
              _failure = null;
            }),
            onSubmitted: (_) {
              if (canSave) unawaited(_save(live));
            },
          ),
          if (_failure == DiaryActionFailure.invalid)
            FbInlineBanner(
              kind: FbInlineBannerKind.error,
              message: l10n.diaryActionFailed,
            )
          else if (_failure != null)
            FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: l10n.diaryMealChangedSave,
            ),
          FbButton.primary(
            label: l10n.diarySave,
            expand: true,
            onPressed: canSave ? () => _save(live) : null,
          ),
        ],
      ),
    );
  }
}
