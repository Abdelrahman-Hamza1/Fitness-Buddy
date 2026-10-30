import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/body/application/measurement_actions.dart';
import 'package:fb_mobile/features/body/application/measurement_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the custom type sheet (WB-040, A15b D18): a name for a new custom
/// measurement (a length), or a new name for [rename]. Resolves to the
/// type's ID once saved (null when dismissed); the Undo snackbar shows on
/// the root messenger.
Future<String?> showCustomTypeSheet(
  BuildContext context, {
  MeasurementType? rename,
}) => showFbStatefulSheet<String>(
  context,
  builder: (_) => CustomTypeSheet(rename: rename),
);

/// The body of the custom type sheet.
class CustomTypeSheet extends ConsumerStatefulWidget {
  /// Creates a type, or renames [rename].
  const new({this.rename, super.key});

  /// The type to rename, at the version shown; `null` to create one.
  final MeasurementType? rename;

  @override
  ConsumerState<CustomTypeSheet> createState() => _CustomTypeSheetState();
}

class _CustomTypeSheetState extends ConsumerState<CustomTypeSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.rename?.name ?? '',
  );
  bool _saving = false;
  bool _edited = false;
  MeasurementFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The message under the field, or null. Empty only after an edit.
  String? _error(BuildContext context, List<MeasurementTypeView> views) {
    final l10n = context.l10n;
    final name = _name.text;
    final issue = CustomTypeName.validate(name);
    if (issue == CustomTypeNameIssue.empty) {
      return _edited ? l10n.measurementCustomEmpty : null;
    }
    if (issue == CustomTypeNameIssue.tooLong) {
      return l10n.measurementCustomTooLong;
    }
    if (issue == CustomTypeNameIssue.invalid) {
      return l10n.measurementCustomInvalid;
    }
    final clash = views.any(
      (v) =>
          v.type != null &&
          v.type!.id != widget.rename?.id &&
          CustomTypeName.same(v.type!.name, name),
    );
    if (clash || _failure == MeasurementFailure.duplicateName) {
      return l10n.measurementCustomDuplicate;
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = CustomTypeName.normalize(_name.text);
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final actions = ref.read(measurementActionsProvider.notifier);
    setState(() {
      _saving = true;
      _failure = null;
    });
    final rename = widget.rename;
    final outcome = rename == null
        ? await actions.createType(name)
        : await actions.renameType(rename, name);
    if (mounted) setState(() => _saving = false);
    switch (outcome) {
      case MeasurementDone(:final undoId, :final id):
        if (mounted) nav.pop(id);
        if (host.mounted) {
          final l10n = host.l10n;
          showUndoFeedback(
            host,
            message: rename == null
                ? l10n.measurementTypeCreated(name)
                : l10n.measurementTypeRenamed(name),
            undoEntryId: undoId,
          );
        }
      case MeasurementUnchanged():
        if (mounted) nav.pop(rename?.id);
      case MeasurementPending():
        break;
      case MeasurementFailed(:final reason):
        if (mounted) setState(() => _failure = reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final views =
        ref.watch(latestByTypeProvider).value ?? const <MeasurementTypeView>[];
    final error = _error(context, views);
    final canSave =
        !_saving &&
        error == null &&
        CustomTypeName.validate(_name.text) == null;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FbSheet(
        title: widget.rename == null
            ? l10n.measurementCustomTitle
            : l10n.measurementRenameTitle,
        actions: FbButton.primary(
          label: l10n.measurementSave,
          expand: true,
          onPressed: canSave ? () => unawaited(_save()) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s3,
          children: [
            FbTextField(
              controller: _name,
              label: l10n.measurementCustomName,
              hint: l10n.measurementCustomHint,
              autofocus: true,
              errorText: error,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {
                _edited = true;
                if (_failure == MeasurementFailure.duplicateName) {
                  _failure = null;
                }
              }),
              onSubmitted: (_) {
                if (canSave) unawaited(_save());
              },
            ),
            Text(
              l10n.measurementCustomNote,
              style: FbType.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_failure case final failure?
                when failure != MeasurementFailure.duplicateName)
              FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: failure == MeasurementFailure.removed
                    ? l10n.measurementFailedType
                    : l10n.measurementCustomFailed,
              ),
          ],
        ),
      ),
    );
  }
}
