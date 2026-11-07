import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart'
    show
        measurementDiffText,
        measurementInputText,
        measurementTypeName,
        measurementUnitLabel,
        weightUnitLabel;
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/workouts/workouts.dart' show WorkoutText;
import 'package:material_ui/material_ui.dart';

/// How many import rows without flags are listed by name (the rest are
/// counted).
const _shownPlainRows = 3;

/// The details of a workout card (A69 D3, WO-030–033): each exercise with
/// its sets, PR marks and Buddy's assumptions; an unmatched one asks which
/// it is. Taps go to [thread]; nothing here writes.
List<Widget> workoutDetails(
  BuildContext context, {
  required RecordCard card,
  required WorkoutView view,
  required BuddyThreadController thread,
  required bool enabled,
}) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
  final out = <Widget>[];
  for (final e in view.exercises) {
    String setText(int i, LoggedSet s) {
      final text = l10n.setValues(e.type, s.values);
      return e.prSets.contains(i) ? '$text (${l10n.recordWorkoutPr})' : text;
    }

    final sets = [for (final (i, s) in e.sets.indexed) setText(i, s)]
        .where((t) => t.isNotEmpty)
        .join(', ');
    out
      ..add(
        Text(
          e.exercise?.name ?? e.mention,
          style: FbType.body.copyWith(fontWeight: FontWeight.w600),
        ),
      )
      ..add(
        Text(
          sets.isEmpty
              ? l10n.recordWorkoutNoSets
              : l10n.recordWorkoutSets(sets),
          style: e.leftOut ? muted : FbType.body,
        ),
      );
    for (final note in [
      if (e.created) l10n.recordWorkoutCreated,
      if (e.leftOut) l10n.recordWorkoutLeftOut,
      if (e.splitPerDumbbell) l10n.recordWorkoutSplit,
      // The server's notes (English), as sent.
      ...e.assumptions,
    ]) {
      out.add(Text(note, style: muted));
    }
    if (e.needsPick) {
      out
        ..add(Text(l10n.recordWorkoutWhich(e.mention), style: FbType.body))
        ..add(
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              for (final c in e.candidates)
                FbAnswerChip(
                  label: c.name,
                  onTap: enabled
                      ? () => unawaited(
                          thread.pickExercise(card.id, e.index, c.id),
                        )
                      : () {},
                ),
              FbAnswerChip(
                label: l10n.recordWorkoutNew(e.mention),
                onTap: enabled
                    ? () => unawaited(
                        thread.pickExercise(
                          card.id,
                          e.index,
                          RecordAdjust.newExercise,
                        ),
                      )
                    : () {},
              ),
              FbAnswerChip(
                label: l10n.recordWorkoutLeaveOut,
                onTap: enabled
                    ? () => unawaited(
                        thread.pickExercise(
                          card.id,
                          e.index,
                          RecordAdjust.leaveOut,
                        ),
                      )
                    : () {},
              ),
            ],
          ),
        );
    }
  }
  out.add(Text(l10n.recordWorkoutEditLater, style: muted));
  return out;
}

/// The details of a measurement card (A69 D4, WB-040).
List<Widget> measurementDetails(
  BuildContext context, {
  required MeasurementView view,
  required LocalDate referenceDate,
}) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final draft = view.draft;
  return [
    Text(
      '${measurementTypeName(l10n, draft.type)}: '
      '${measurementInputText(l10n, draft.input)} · '
      '${dayLabelInline(context, draft.localDate, referenceDate)}',
      style: FbType.numeric(FbType.headline),
    ),
    if (view.delta case final d?)
      Text(
        l10n.recordMeasurementChange(
          measurementDiffText(l10n, d, draft.input.unit),
        ),
        style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      ),
  ];
}

/// The import review table (A69 D5, WB-031): flagged rows with their flags
/// and Include / Leave out, then the other rows; every row can be shown
/// before Import (A69 review).
List<Widget> importDetails(
  BuildContext context, {
  required RecordCard card,
  required ImportView view,
  required LocalDate referenceDate,
  required BuddyThreadController thread,
  required bool enabled,
}) => [
  _ImportTable(
    card: card,
    view: view,
    referenceDate: referenceDate,
    thread: thread,
    enabled: enabled,
  ),
];

class _ImportTable extends StatefulWidget {
  const new({
    required this.card,
    required this.view,
    required this.referenceDate,
    required this.thread,
    required this.enabled,
  });

  final RecordCard card;
  final ImportView view;
  final LocalDate referenceDate;
  final BuddyThreadController thread;
  final bool enabled;

  @override
  State<_ImportTable> createState() => _ImportTableState();
}

class _ImportTableState extends State<_ImportTable> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final view = widget.view;
    final referenceDate = widget.referenceDate;
    final thread = widget.thread;
    final enabled = widget.enabled;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    String unitText(String? code) {
      if (MassUnit.fromCode(code ?? '') case final m?) {
        return weightUnitLabel(l10n, m);
      }
      if (MeasurementUnit.fromCode(code ?? '') case final m?) {
        return measurementUnitLabel(l10n, m);
      }
      return code ?? '';
    }

    String flagText(ImportFlag flag, String? unit) => switch (flag) {
      ImportFlag.unclearDate => l10n.recordImportFlagUnclearDate,
      ImportFlag.noValue => l10n.recordImportFlagNoValue,
      ImportFlag.unknownUnit => l10n.recordImportFlagUnknownUnit,
      ImportFlag.outOfRange => l10n.recordImportFlagOutOfRange,
      ImportFlag.future => l10n.recordImportFlagFuture,
      ImportFlag.unitInferred => l10n.recordImportFlagUnitInferred(
        unitText(unit),
      ),
      ImportFlag.unitMissing => l10n.recordImportFlagUnitMissing(
        unitText(unit),
      ),
      ImportFlag.duplicate => l10n.recordImportFlagDuplicate,
      ImportFlag.implausible => l10n.recordImportFlagImplausible,
      ImportFlag.sameDay => l10n.recordImportFlagSameDay,
    };

    final rows = view.rows;
    final flagged = [
      for (final r in rows)
        if (r.flags.isNotEmpty) r,
    ];
    final plain = [
      for (final r in rows)
        if (r.flags.isEmpty) r,
    ];
    final out = <Widget>[
      Text(
        l10n.recordImportSummary(view.includedCount, rows.length),
        style: FbType.body,
      ),
    ];
    Widget line(ImportRowView r) => Text(
      l10n.recordImportRow(
        r.date == null
            ? l10n.recordImportNoDate
            : dayLabelInline(context, r.date!, referenceDate),
        r.value == null ? r.original : '${r.value} ${unitText(r.unit)}'.trim(),
      ),
      style: FbType.body.copyWith(
        color: r.included ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
    );
    for (final r in [
      ...flagged,
      ...(_all ? plain : plain.take(_shownPlainRows)),
    ]) {
      out.add(line(r));
      if (r.flags.isNotEmpty) {
        out.add(
          Text(
            [
              for (final f in r.flags) flagText(f, r.unit),
              // The row as pasted (user content).
              '“${r.original}”',
            ].join(' · '),
            style: muted,
          ),
        );
      }
      if (r.canAccept) {
        out.add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbAnswerChip(
              label: r.accepted
                  ? l10n.recordImportExclude
                  : l10n.recordImportInclude,
              onTap: enabled
                  ? () => unawaited(
                      thread.acceptImportRow(card.id, r.index, on: !r.accepted),
                    )
                  : () {},
            ),
          ),
        );
      }
    }
    if (plain.length > _shownPlainRows) {
      out
        ..add(
          Text(
            _all
                ? l10n.recordImportAllShown
                : l10n.recordImportOthers(plain.length - _shownPlainRows),
            style: muted,
          ),
        )
        ..add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbButton.text(
              key: const ValueKey('import-show-all'),
              label: _all
                  ? l10n.recordImportShowFewer
                  : l10n.recordImportShowAll(rows.length),
              onPressed: () => setState(() => _all = !_all),
            ),
          ),
        );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s1,
      children: out,
    );
  }
}
