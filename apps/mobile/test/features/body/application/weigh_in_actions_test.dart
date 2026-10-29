import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/application/weigh_in_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/weigh_in_harness.dart';

void main() {
  late WeighInHarness h;
  late ProviderContainer c;

  setUp(() {
    h = WeighInHarness();
    c = ProviderContainer.test(overrides: h.overrides);
  });

  WeighInActions actions() => c.read(weighInActionsProvider.notifier);

  Future<WeighIn> liveOne(int n) async =>
      (await h.live()).singleWhere((w) => w.id == fixtureId(n));

  Future<UndoOutcome> undo(WeighInOutcome outcome) =>
      c.read(undoStackProvider).undo((outcome as WeighInDone).undoId);

  test('UX-030 logging pushes an undo entry labelled with the typed value; '
      'undo leaves no live weigh-in', () async {
    final before = await h.state();
    final draft = weighInDraft(214, unit: MassUnit.pound, note: 'after Eid');
    final outcome = await actions().log(draft) as WeighInDone;
    expect(outcome.kind, WeighInKind.weighInLogged);
    expect(outcome.args, {'value': 214.0, 'unit': MassUnit.pound});
    final entry = c.read(undoStackProvider).latest!;
    expect(entry.id, outcome.undoId);
    expect(
      entry.label,
      UndoLabel(
        'weighInLogged',
        args: const {'value': 214.0, 'unit': MassUnit.pound},
      ),
    );
    final live = (await h.live()).single;
    expect(live.kg, 97.07);
    expect(live.input, const WeighInInput(214, MassUnit.pound));
    expect(live.note, 'after Eid');
    expect(c.read(weighInActionsProvider), isEmpty);

    expect(await undo(outcome), UndoOutcome.undone);
    expect(await h.live(), isEmpty);
    expect(await h.state(), before);
  });

  test('a double tap on Save logs once', () async {
    final draft = weighInDraft(97.4);
    final first = actions().log(draft);
    expect(c.read(weighInActionsProvider), {WeighInActions.logKey});
    expect(await actions().log(draft), isA<WeighInPending>());
    expect(await first, isA<WeighInDone>());
    expect(await h.live(), hasLength(1));
    expect(c.read(weighInActionsProvider), isEmpty);
  });

  test('an invalid or future draft is refused before anything is '
      'applied', () async {
    final before = await h.raw();
    expect(
      (await actions().log(weighInDraft(19.9)) as WeighInFailed).reason,
      WeighInFailure.invalid,
    );
    final future = WeighInDraft(
      time: EntryTime(harnessNow.add(const Duration(minutes: 6)), 180),
      input: const WeighInInput(97, MassUnit.kilogram),
    );
    expect(
      (await actions().log(future) as WeighInFailed).reason,
      WeighInFailure.future,
    );
    expect(await h.raw(), before);
    expect(c.read(undoStackProvider).latest, isNull);
  });

  group('WB-003 trend choice', () {
    test('WB-003 logging with use-for-trend sets the new weigh-in as the '
        "day's choice in one change set; undo restores the day", () async {
      await h.seed([weighInDraft(97.2, hour: 6)]);
      final early = await liveOne(1);
      final before = await h.state();
      final outcome = await actions().log(
        weighInDraft(97.8, hour: 9),
        trend: WeighInTrendPick(useThis: true, dayOthers: [early]),
      ) as WeighInDone;
      expect(outcome.kind, WeighInKind.weighInLogged);
      final live = await h.live();
      expect(live, hasLength(2));
      final added = live.singleWhere((w) => w.id != early.id);
      expect(added.preferredForDay, isTrue);
      expect(DayChoice.of(live).single.id, added.id);

      expect(await undo(outcome), UndoOutcome.undone);
      expect(await h.state(), before);
    });

    test('WB-003 switching a default choice off picks the earliest other '
        'weigh-in', () async {
      await h.seed([weighInDraft(97.2, hour: 8), weighInDraft(97.4, hour: 9)]);
      final others = await h.live();
      await actions().log(
        weighInDraft(97, hour: 6),
        trend: WeighInTrendPick(useThis: false, dayOthers: others),
      );
      final live = await h.live();
      expect(DayChoice.of(live).single.id, fixtureId(1));
      expect((await liveOne(1)).preferredForDay, isTrue);
    });

    test('WB-003 a day that changed since it was shown is refused as '
        'changed and nothing is written', () async {
      await h.seed([weighInDraft(97.2, hour: 6)]);
      final early = await liveOne(1);
      // Another weigh-in lands on the day after the sheet read it.
      await h.apply([CreateWeighIn(fixtureId(2), weighInDraft(97.3))]);
      final before = await h.raw();
      final outcome = await actions().log(
        weighInDraft(97.8, hour: 9),
        trend: WeighInTrendPick(useThis: true, dayOthers: [early]),
      ) as WeighInFailed;
      expect(outcome.reason, WeighInFailure.changed);
      expect(await h.raw(), before);
    });
  });

  group('edit', () {
    test('edit saves changes with undo; an identical draft is unchanged and '
        'writes nothing', () async {
      await h.seed([weighInDraft(97.4)]);
      final stored = await liveOne(1);
      expect(
        await actions().update(stored, stored.draft),
        isA<WeighInUnchanged>(),
      );
      expect(c.read(undoStackProvider).latest, isNull);

      final before = await h.state();
      final edited = weighInDraft(96.4, note: 'typo fixed');
      final outcome = await actions().update(stored, edited) as WeighInDone;
      expect(outcome.kind, WeighInKind.weighInUpdated);
      expect(outcome.args, {'value': 96.4, 'unit': MassUnit.kilogram});
      final after = await liveOne(1);
      expect(after.kg, 96.4);
      expect(after.note, 'typo fixed');
      expect(after.version, stored.version + 1);

      expect(await undo(outcome), UndoOutcome.undone);
      expect(await h.state(), before);
    });

    test('an edit with a trend choice lists the row at its version after '
        'the update', () async {
      await h.seed([weighInDraft(97.2, hour: 6), weighInDraft(97.8, hour: 9)]);
      final early = await liveOne(1);
      final late = await liveOne(2);
      final outcome = await actions().update(
        late,
        weighInDraft(97.6, hour: 9),
        trend: WeighInTrendPick(useThis: true, dayOthers: [early]),
      ) as WeighInDone;
      expect(outcome.kind, WeighInKind.weighInUpdated);
      final after = await liveOne(2);
      expect(after.kg, 97.6);
      expect(after.preferredForDay, isTrue);
    });

    test('only a trend change is a trend-chosen action', () async {
      await h.seed([weighInDraft(97.2, hour: 6), weighInDraft(97.8, hour: 9)]);
      final early = await liveOne(1);
      final late = await liveOne(2);
      final outcome = await actions().update(
        late,
        late.draft,
        trend: WeighInTrendPick(useThis: true, dayOthers: [early]),
      ) as WeighInDone;
      expect(outcome.kind, WeighInKind.weighInTrendChosen);
      expect((await liveOne(2)).preferredForDay, isTrue);
      expect((await liveOne(2)).kg, 97.8);
    });

    test('edit mode deletes with undo', () async {
      await h.seed([weighInDraft(97.4)]);
      final stored = await liveOne(1);
      final before = await h.state();
      final outcome = await actions().delete(stored) as WeighInDone;
      expect(outcome.kind, WeighInKind.weighInDeleted);
      expect(outcome.args, {'value': 97.4, 'unit': MassUnit.kilogram});
      expect(await h.live(), isEmpty);
      expect(await undo(outcome), UndoOutcome.undone);
      expect(await h.state(), before);
    });

    test('a weigh-in changed meanwhile is refused as changed; a deleted one '
        'as removed', () async {
      await h.seed([weighInDraft(97.4)]);
      final shown = await liveOne(1);
      await h.apply([UpdateWeighIn(shown.id, 1, weighInDraft(97.5))]);
      final before = await h.raw();
      expect(
        (await actions().update(
          shown,
          weighInDraft(97.6),
        ) as WeighInFailed).reason,
        WeighInFailure.changed,
      );
      expect(
        (await actions().delete(shown) as WeighInFailed).reason,
        WeighInFailure.changed,
      );
      expect(await h.raw(), before);

      final current = await liveOne(1);
      await h.apply([DeleteWeighIn(current.versionedId)]);
      expect(
        (await actions().update(
          current,
          weighInDraft(97.6),
        ) as WeighInFailed).reason,
        WeighInFailure.removed,
      );
    });
  });
}
