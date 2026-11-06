import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate;
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/testing.dart' show ManualClock;
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_service.dart' show SignOutChoice;
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/write_guard.dart' show runAuthorizedWrite;
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/application/sign_out_check.dart';
import 'package:fb_mobile/features/account/presentation/sign_out_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/account/account_fakes.dart' show memoryRegistry;
import '../../core/db/support/db_support.dart' show hlcAt, memoryDatabase;
import '../today/presentation/support/today_support.dart' show phoneApp;

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

const String _profile = 'profile-a';

/// Counts the syncs asked for before a remove ([onSync] runs with each)
/// and the removals; each removal answers the next of `removeAnswers`
/// (`true` = removed, `false` = stopped, ask again).
final class _Actions extends AccountActions {
  new({this.onSync, List<bool>? removeAnswers})
    : _answers = removeAnswers ?? [true];

  final void Function()? onSync;
  final List<bool> _answers;
  final List<void> syncs = [];
  final List<RemoveConfirmation> removals = [];
  final List<SignOutChoice> signOuts = [];

  @override
  Future<void> syncBeforeRemove() async {
    syncs.add(null);
    onSync?.call();
  }

  @override
  Future<bool> removeCopy(RemoveConfirmation confirmed) async {
    removals.add(confirmed);
    return _answers.removeAt(0);
  }

  @override
  Future<void> signOut(SignOutChoice choice) async => signOuts.add(choice);
}

const ValueKey<String> _remove = ValueKey('sign-out-remove-confirm');
const ValueKey<String> _syncFirst = ValueKey('sign-out-sync-first');
const ValueKey<String> _cancel = ValueKey('sign-out-remove-cancel');
const ValueKey<String> _message = ValueKey('sign-out-remove-message');

/// The count from [unsynced] (a fixed stand-in for the live read).
List<Override> _countOverrides(int? Function() unsynced, _Actions actions) => [
  unsyncedChangesProvider.overrideWith(
    (ref) => Stream.value((profileKey: _profile, count: unsynced())),
  ),
  accountActionsProvider.overrideWith(() => actions),
];

/// The real count: the sync store on [db] and an in-memory registry.
List<Override> _realOverrides(AppDatabase db, _Actions actions) => [
  appDatabaseProvider.overrideWith((ref) => db),
  // The sync store takes the clock when it is made; the count never reads it.
  clockProvider.overrideWithValue(ManualClock(DateTime.utc(2026, 11, 6, 12))),
  profileRegistryProvider.overrideWithValue(memoryRegistry()),
  accountActionsProvider.overrideWith(() => actions),
];

/// Pumps a button that opens the sign-out sheet ([open]: the plain sheet,
/// or [runSignOut]) and picks "Remove from this phone".
Future<void> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  required Future<void> Function(BuildContext context) open,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: phoneApp(
        Builder(
          builder: (context) => Center(
            child: FbButton.primary(
              label: 'open',
              onPressed: () => unawaited(open(context)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_l10n.accountSignOutRemove));
  await tester.pumpAndSettle();
}

/// Opens the plain sheet; the request lands in [result].
Future<void> Function(BuildContext) _into(List<SignOutRequest?> result) =>
    (context) => showSignOutSheet(context).then(result.add);

FbButton _button(WidgetTester tester, Key key) =>
    tester.widget<FbButton>(find.byKey(key));

String? _shown(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(_message)).data;

RemoveConfirmation _confirmed(List<SignOutRequest?> result) =>
    (result.single! as RemoveCopyRequest).confirmation;

void main() {
  testWidgets('AC-004 A65 M1 removing asks to confirm even when everything '
      'is synced; no sync runs', (tester) async {
    final actions = _Actions();
    final result = <SignOutRequest?>[];
    await _pump(
      tester,
      overrides: _countOverrides(() => 0, actions),
      open: _into(result),
    );
    expect(result, isEmpty, reason: 'one tap must not remove');
    expect(find.byKey(_syncFirst), findsNothing);
    expect(actions.syncs, isEmpty);
    await tester.tap(find.byKey(_remove));
    await tester.pumpAndSettle();
    expect(_confirmed(result).profileKey, _profile);
    expect(_confirmed(result).unsynced, 0);
  });

  testWidgets('A65 M1 UX-052 with changes waiting it syncs first; still '
      'waiting, it offers Sync now and Remove anyway', (tester) async {
    final actions = _Actions();
    final result = <SignOutRequest?>[];
    await _pump(
      tester,
      overrides: _countOverrides(() => 3, actions),
      open: _into(result),
    );
    expect(actions.syncs, hasLength(1));
    expect(find.byKey(_syncFirst), findsOneWidget);
    expect(_button(tester, _remove).onPressed, isNotNull);
    await tester.tap(find.byKey(_syncFirst));
    await tester.pumpAndSettle();
    expect(actions.syncs, hasLength(2));
    await tester.tap(find.byKey(_remove));
    await tester.pumpAndSettle();
    expect(_confirmed(result).unsynced, 3, reason: 'bound to the count shown');
  });

  testWidgets('A65 M1 changes that sync away turn the warning into the '
      'plain confirmation', (tester) async {
    var waiting = 2;
    ProviderContainer? container;
    final actions = _Actions(
      onSync: () {
        waiting = 0;
        container?.invalidate(unsyncedChangesProvider);
      },
    );
    await _pump(
      tester,
      overrides: _countOverrides(() => waiting, actions),
      open: _into([]),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(RemoveCopyConfirm)),
    );
    // The first sync ran before the container was captured (the count
    // stayed cached at 2): Sync now re-reads it.
    expect(find.byKey(_syncFirst), findsOneWidget);
    await tester.tap(find.byKey(_syncFirst));
    await tester.pumpAndSettle();
    expect(find.byKey(_syncFirst), findsNothing);
    expect(_button(tester, _remove).onPressed, isNotNull);
  });

  testWidgets('A65 M1 Cancel and a dismissed confirmation sign nothing out', (
    tester,
  ) async {
    final result = <SignOutRequest?>[];
    await _pump(
      tester,
      overrides: _countOverrides(() => 0, _Actions()),
      open: _into(result),
    );
    await tester.tap(find.byKey(_cancel));
    await tester.pumpAndSettle();
    expect(result, [null]);
  });

  testWidgets('A65 review 3 the real count: a waiting row is counted, and a '
      'read that fails later warns instead of keeping the old number', (
    tester,
  ) async {
    final db = memoryDatabase();
    final result = <SignOutRequest?>[];
    final actions = _Actions();
    await _pump(
      tester,
      overrides: _realOverrides(db, actions),
      open: _into(result),
    );
    expect(_shown(tester), _l10n.accountRemoveSynced);

    // A waiting outbox row and a broken table can't come from the applier,
    // so the test writes them through the guard's test scope.
    await runAuthorizedWrite(
      () => db
          .into(db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              entity: 'setting',
              rowId: 'row-1',
              hlc: hlcAt(1),
              deleted: false,
            ),
          ),
    );
    await tester.pumpAndSettle();
    expect(_shown(tester), _l10n.accountRemoveUnsynced(1));

    await runAuthorizedWrite(
      () => db.customStatement('DROP TABLE sync_parked'),
    );
    db.notifyUpdates({TableUpdate.onTable(db.syncOutbox)});
    await tester.pumpAndSettle();
    expect(_shown(tester), _l10n.accountRemoveCheckFailed);
    expect(_button(tester, _remove).busy, isFalse);
    await tester.tap(find.byKey(_remove));
    await tester.pumpAndSettle();
    expect(_confirmed(result).unsynced, isNull);
  });

  testWidgets('A65 review 3 the real count unreadable from the start warns '
      'at once (never "Syncing…" forever) and needs a tap', (tester) async {
    final db = memoryDatabase();
    await runAuthorizedWrite(
      () => db.customStatement('DROP TABLE sync_outbox'),
    );
    final result = <SignOutRequest?>[];
    await _pump(
      tester,
      overrides: _realOverrides(db, _Actions()),
      open: _into(result),
    );
    expect(_shown(tester), _l10n.accountRemoveCheckFailed);
    expect(_button(tester, _remove).onPressed, isNotNull);
    expect(result, isEmpty);
  });

  testWidgets('A65 review 2 a caller gone after choosing Remove gets nothing '
      'and no confirmation opens', (tester) async {
    final shown = ValueNotifier(true);
    final actions = _Actions();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._countOverrides(() => 0, actions)],
        child: phoneApp(
          ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (_, isShown, _) => isShown
                ? Builder(
                    builder: (context) => Center(
                      child: FbButton.primary(
                        label: 'open',
                        onPressed: () =>
                            unawaited(runSignOut(context, actions)),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    shown.value = false;
    await tester.pump();
    await tester.tap(find.text(_l10n.accountSignOutRemove));
    await tester.pumpAndSettle();
    expect(find.byType(RemoveCopyConfirm), findsNothing);
    expect(actions.removals, isEmpty);
    expect(actions.signOuts, isEmpty);
  });

  testWidgets('A65 review 1 a removal stopped by new changes asks again, '
      'says why, and removes only after the new confirmation', (tester) async {
    var waiting = 1;
    final actions = _Actions(removeAnswers: [false, true]);
    await _pump(
      tester,
      overrides: _countOverrides(() => waiting, actions),
      open: (context) => runSignOut(context, actions),
    );
    await tester.tap(find.byKey(_remove));
    await tester.pumpAndSettle();
    expect(actions.removals.single.unsynced, 1);
    // Asked again with the new count.
    expect(
      find.byKey(const ValueKey('sign-out-remove-changed')),
      findsOneWidget,
    );
    waiting = 2;
    ProviderScope.containerOf(tester.element(find.byType(RemoveCopyConfirm)))
        .invalidate(unsyncedChangesProvider);
    await tester.pumpAndSettle();
    expect(_shown(tester), _l10n.accountRemoveUnsynced(2));
    await tester.tap(find.byKey(_remove));
    await tester.pumpAndSettle();
    expect(actions.removals.map((c) => c.unsynced), [1, 2]);
    expect(find.byType(RemoveCopyConfirm), findsNothing);
  });

  test('A65 review 1 the final count never exceeds what was confirmed', () {
    const shown = RemoveConfirmation(profileKey: _profile, unsynced: 2);
    expect(shown.covers(2), isTrue);
    expect(shown.covers(0), isTrue);
    expect(shown.covers(3), isFalse);
    expect(shown.covers(null), isFalse, reason: 'unreadable now');
    const unknown = RemoveConfirmation(profileKey: _profile, unsynced: null);
    expect(unknown.covers(null), isTrue, reason: 'the warning was accepted');
    expect(unknown.covers(0), isTrue);
    expect(unknown.covers(1), isFalse, reason: 'ask again with the number');
  });

  testWidgets('AC-004 Keep a copy needs no confirmation', (tester) async {
    final result = <SignOutRequest?>[];
    await tester.pumpWidget(
      ProviderScope(
        child: phoneApp(
          Builder(
            builder: (context) => Center(
              child: FbButton.primary(
                label: 'open',
                onPressed: () =>
                    unawaited(showSignOutSheet(context).then(result.add)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.accountSignOutKeep));
    await tester.pumpAndSettle();
    expect(result.single, isA<KeepCopyRequest>());
  });
}
