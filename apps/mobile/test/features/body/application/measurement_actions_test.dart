import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/application/measurement_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/measurement_harness.dart';

void main() {
  late MeasurementHarness h;
  late ProviderContainer c;

  setUp(() {
    h = MeasurementHarness();
    c = ProviderContainer.test(overrides: h.overrides);
  });

  MeasurementActions actions() => c.read(measurementActionsProvider.notifier);
  UndoStack stack() => c.read(undoStackProvider);

  test('UX-030 logging, editing and deleting push undo entries without values '
      'in their labels; an unchanged edit adds none', () async {
    final logged = await actions().log(measureDraft(92)) as MeasurementDone;
    expect(logged.kind, MeasurementKindOfChange.measurementLogged);
    expect(stack().latest!.label, UndoLabel('measurementLogged'));
    final entry = (await h.live()).measurements.single;
    expect(entry.id, logged.id);

    expect(
      await actions().update(entry, entry.draft),
      isA<MeasurementUnchanged>(),
    );
    expect(stack().latest!.id, logged.undoId);

    final updated =
        await actions().update(entry, measureDraft(91)) as MeasurementDone;
    expect(updated.kind, MeasurementKindOfChange.measurementUpdated);
    final edited = (await h.live()).measurements.single;
    final deleted = await actions().delete(edited) as MeasurementDone;
    expect(deleted.kind, MeasurementKindOfChange.measurementDeleted);
    expect((await h.live()).measurements, isEmpty);
    expect(await stack().undo(deleted.undoId), UndoOutcome.undone);
    expect((await h.live()).measurements.single.value, 91);
  });

  test('refusals map to content-free failures and write nothing', () async {
    final before = await h.raw();
    expect(
      (await actions().log(measureDraft(9)) as MeasurementFailed).reason,
      MeasurementFailure.invalid,
    );
    final future = MeasurementDraft(
      type: waistRef,
      time: EntryTime(measureNow.add(const Duration(minutes: 6)), 180),
      input: const MeasurementInput(90, MeasurementUnit.cm),
    );
    expect(
      (await actions().log(future) as MeasurementFailed).reason,
      MeasurementFailure.future,
    );
    expect(
      (await actions().log(
        measureDraft(40, type: MeasurementTypeRef.custom(tId(1))),
      ) as MeasurementFailed).reason,
      MeasurementFailure.unknownType,
    );
    expect(await h.raw(), before);

    final created = await actions().createType('Calf') as MeasurementDone;
    expect(created.kind, MeasurementKindOfChange.measurementTypeCreated);
    expect(
      (await actions().createType(' calf ') as MeasurementFailed).reason,
      MeasurementFailure.duplicateName,
    );
  });

  test('WB-040 UX-030 add, rename and delete a custom type; undo restores the '
      'type and its entries', () async {
    final created = await actions().createType('Calf') as MeasurementDone;
    final type = (await h.live()).types.single;
    expect(type.id, created.id);
    await actions().log(measureDraft(40, type: type.ref));
    final renamed =
        await actions().renameType(type, 'Left calf') as MeasurementDone;
    expect(renamed.kind, MeasurementKindOfChange.measurementTypeRenamed);
    final data = await h.live();
    final deleted = await actions().deleteType(
      data.types.single,
      data.measurements,
    ) as MeasurementDone;
    expect(deleted.kind, MeasurementKindOfChange.measurementTypeDeleted);
    expect((await h.live()).types, isEmpty);
    expect(await stack().undo(deleted.undoId), UndoOutcome.undone);
    final back = await h.live();
    expect(back.types.single.name, 'Left calf');
    expect(back.measurements, hasLength(1));
  });

  test('a double tap on Save logs once', () async {
    final first = actions().log(measureDraft(92));
    expect(await actions().log(measureDraft(92)), isA<MeasurementPending>());
    expect(await first, isA<MeasurementDone>());
    expect((await h.live()).measurements, hasLength(1));
  });
}
