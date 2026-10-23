import 'dart:convert';

import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/diary/support/diary_fixtures.dart';
import '../db/support/db_support.dart';
import 'session_fakes.dart';

void main() {
  for (final registered in [false, true]) {
    test(
      'OF-01 terminal auth registered=$registered leaves diary/outbox intact',
      () async {
        final db = memoryDatabase();
        final slot = (await db.select(db.mealSlots).get()).first;
        await runAuthorizedWrite(
          () => db
              .into(db.diaryEntries)
              .insert(entryRow(1, date: '2026-10-23', slotId: slot.id)),
        );
        Future<String> snapshot() async => jsonEncode([
          for (final table in [
            'diary_entries',
            'meal_slots',
            'settings_kv',
            'sync_state',
            'sync_outbox',
          ])
            (await db.customSelect('SELECT * FROM $table').get())
                .map((row) => row.data)
                .toList(),
        ]);
        final before = await snapshot();
        final f = Fixture();
        await f.seed(registered: registered);
        f.auth.rotate = (_) async =>
            throw const AuthFailure(AuthFailureKind.unauthorized);
        try {
          await f.service.startAfterFirstFrame();
        } on SessionFailure {
          /* Registered expiry. */
        }
        expect(await snapshot(), before);
        expect(await outbox(db), isNotEmpty);
        expect(f.auth.creates, registered ? 0 : 1);
      },
    );
  }
}
