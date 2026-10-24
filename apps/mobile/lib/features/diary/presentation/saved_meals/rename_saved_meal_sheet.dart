import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/saved_meal_actions.dart';
import 'package:fb_mobile/features/diary/application/saved_meals.dart';
import 'package:fb_mobile/features/diary/presentation/save_meal_sheet.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet that renames [meal] (DY-031, A09 D11): a name of 1 to 60
/// characters and Save, a direct action with Undo.
Future<void> showRenameSavedMealSheet(BuildContext context, SavedMeal meal) =>
    showFbSheet<void>(
      context,
      title: context.l10n.savedMealRenameTitle,
      builder: (_) => RenameSavedMealSheet(opened: meal),
    );

/// How the open sheet's meal compares with the stored one (A08 D12(4)).
enum _Freshness { fresh, removed, renamed }

/// The body of the rename sheet. It watches its meal by ID: deleted means
/// Save is off, renamed elsewhere offers Reload (what was typed stays), and
/// a change to the items only is harmless (Save expects the new version).
class RenameSavedMealSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for the meal as it was [opened].
  const new({required this.opened, super.key});

  /// The meal as shown when the sheet opened.
  final SavedMeal opened;

  @override
  ConsumerState<RenameSavedMealSheet> createState() =>
      _RenameSavedMealSheetState();
}

class _RenameSavedMealSheetState extends ConsumerState<RenameSavedMealSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.opened.name)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.opened.name.length,
        );
  late SavedMeal _base = widget.opened;
  bool _touched = false;
  bool _saving = false;
  SavedMealFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _trimmed => _name.text.trim();

  bool get _validName =>
      _trimmed.isNotEmpty && _trimmed.length <= savedMealNameMaxLength;

  Future<void> _save(SavedMeal meal) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await ref
        .read(savedMealActionsProvider)
        .rename(meal, _trimmed);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case SavedMealFailed(:final reason):
        setState(() => _failure = reason);
      case SavedMealUnchanged():
        nav.pop();
      case SavedMealPending():
        break;
      case SavedMealDone(:final undoEntryId, :final args):
        nav.pop();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: host.l10n.savedMealRenamedMessage('${args['name']}'),
            undoEntryId: undoEntryId,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stored = ref.watch(savedMealProvider(_base.id));
    var freshness = _Freshness.fresh;
    var meal = _base;
    SavedMeal? current;
    if (stored case AsyncData(value: final latest)) {
      if (latest == null) {
        freshness = _Freshness.removed;
      } else if (latest.name != _base.name) {
        freshness = _Freshness.renamed;
        current = latest;
      } else {
        meal = latest;
      }
    }
    final canSave = freshness == _Freshness.fresh && _validName && !_saving;
    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          if (freshness == _Freshness.removed)
            FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: l10n.savedMealRenameGone,
            )
          else if (freshness == _Freshness.renamed)
            FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: l10n.savedMealRenameChanged,
              actionLabel: l10n.diaryReload,
              onAction: () => setState(() => _base = current!),
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
              if (canSave) unawaited(_save(meal));
            },
          ),
          if (_failure == SavedMealFailure.invalid)
            FbInlineBanner(
              kind: FbInlineBannerKind.error,
              message: l10n.diaryActionFailed,
            )
          else if (_failure != null)
            FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: l10n.savedMealChangedRename,
            ),
          FbButton.primary(
            label: l10n.diarySave,
            expand: true,
            onPressed: canSave ? () => _save(meal) : null,
          ),
        ],
      ),
    );
  }
}
