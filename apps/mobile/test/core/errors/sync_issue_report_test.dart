import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/errors/pii_scrubber.dart';
import 'package:fb_mobile/core/errors/sync_issue_codes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../db/support/db_support.dart';

String? _scrubbedValue(SentryEvent event) =>
    PiiScrubber.scrubEvent(event, Hint()).exceptions!.single.value;

void main() {
  // A34 fix round 1, finding 8.
  test('an allowlisted sync issue keeps its codes through the scrubber', () {
    final value = SyncIssueCodes.value(
      'parked',
      'diaryEntry',
      'invalidPayload',
    )!;
    expect(
      _scrubbedValue(ErrorReporting.syncIssueEvent(value)),
      'parked/diaryEntry/invalidPayload',
    );
  });

  test('anything else in a SyncIssue value is scrubbed', () {
    for (final value in [
      'parked/diaryEntry/a lunch note',
      'parked/diaryEntry/invalidPayload/extra',
      'deferred/0199e3c2-5b1a-7c3d-8e4f-0123456789ab/unreadable',
      'parked/notAnEntity/tooLarge',
    ]) {
      expect(
        _scrubbedValue(ErrorReporting.syncIssueEvent(value)),
        PiiScrubber.scrubbed,
        reason: value,
      );
    }
    expect(SyncIssueCodes.value('parked', 'diaryEntry', 'free text'), isNull);
    // Another exception type never keeps an allowlisted-looking value.
    final other = SentryEvent(
      exceptions: [
        SentryException(type: 'Other', value: 'parked/diaryEntry/tooLarge'),
      ],
    );
    expect(_scrubbedValue(other), PiiScrubber.scrubbed);
  });

  test('the entity allowlist is exactly the synced tables', () {
    final db = memoryDatabase();
    expect(SyncIssueCodes.entities, {
      for (final t in db.syncedTables) t.entity,
    });
  });
}
