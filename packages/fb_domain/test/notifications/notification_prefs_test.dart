import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  test('NT-020 NT-021 spec/17 defaults: master on, quiet 23:00–07:00, log '
      '21:00, pending on, weigh-in 08:00, summary 09:00 on; workout 18:00, '
      'protein 20:00, measurement off', () {
    final d = NotificationPrefs.defaults;
    expect(d.enabled, isTrue);
    expect((d.quietStart, d.quietEnd), (23 * 60, 7 * 60));
    expect(d.weighInDay, isNull);
    expect(
      {
        for (final t in NotificationType.values)
          t: (d.of(t).enabled, d.of(t).minute),
      },
      {
        NotificationType.logReminder: (true, 21 * 60),
        NotificationType.pendingProposal: (true, 0),
        NotificationType.weighIn: (true, 8 * 60),
        NotificationType.weeklySummary: (true, 9 * 60),
        NotificationType.workout: (false, 18 * 60),
        NotificationType.proteinCheck: (false, 20 * 60),
        NotificationType.measurement: (false, 9 * 60),
        NotificationType.suhoor: (true, 0),
        NotificationType.iftar: (false, 0),
      },
    );
  });

  test('A40 D3 the stored form round-trips through JSON text', () {
    final prefs =
        NotificationPrefs(
          enabled: false,
          quietStart: 22 * 60,
          quietEnd: 6 * 60 + 30,
          weighInDay: DayOfWeek.monday,
        ).withType(
          NotificationType.workout,
          NotificationTypePrefs(enabled: true, minute: 17 * 60 + 15),
        );
    final back = NotificationPrefs.fromJson(
      jsonDecode(jsonEncode(prefs.toJson())),
    );
    expect(back, prefs);
    expect(back.hashCode, prefs.hashCode);
  });

  test('A40 D3 an unreadable value falls back field by field and never '
      'throws', () {
    final rows = <(Object?, NotificationPrefs)>[
      (null, NotificationPrefs.defaults),
      ('text', NotificationPrefs.defaults),
      (<String, Object?>{}, NotificationPrefs.defaults),
      (
        {
          'enabled': 'yes',
          'quietStart': 9999,
          'quietEnd': -1,
          'weighInDay': 'funday',
        },
        NotificationPrefs.defaults,
      ),
      (
        {
          'types': {
            'workout': {'enabled': true, 'minute': 1440},
            'logReminder': {'enabled': 1, 'minute': 20 * 60},
            'suhoor': {'enabled': true, 'minute': 0}, // a newer type
            'weighIn': 'broken',
          },
        },
        NotificationPrefs.defaults
            .withType(
              NotificationType.workout,
              NotificationTypePrefs(enabled: true, minute: 18 * 60),
            )
            .withType(
              NotificationType.logReminder,
              NotificationTypePrefs(enabled: true, minute: 20 * 60),
            ),
      ),
    ];
    for (final (json, expected) in rows) {
      expect(NotificationPrefs.fromJson(json), expected, reason: '$json');
    }
  });

  test(
    'NT-021 quiet hours: across midnight, within a day, none when equal',
    () {
      final rows = [
        (23 * 60, 7 * 60, 23 * 60, true),
        (23 * 60, 7 * 60, 0, true),
        (23 * 60, 7 * 60, 7 * 60, false),
        (13 * 60, 14 * 60, 13 * 60 + 59, true),
        (13 * 60, 14 * 60, 12 * 60, false),
        (8 * 60, 8 * 60, 8 * 60, false),
      ];
      for (final (start, end, minute, quiet) in rows) {
        final prefs = NotificationPrefs(quietStart: start, quietEnd: end);
        expect(prefs.isQuiet(minute), quiet, reason: '$start–$end $minute');
      }
    },
  );

  test('copies replace only what they name; out-of-range minutes throw', () {
    final p = NotificationPrefs(weighInDay: DayOfWeek.sunday);
    expect(p.copyWith(enabled: false).weighInDay, DayOfWeek.sunday);
    expect(p.copyWith(clearWeighInDay: true).weighInDay, isNull);
    expect(p.copyWith(quietEnd: 6 * 60).quietEnd, 6 * 60);
    expect(
      NotificationPrefs.defaults
          .of(NotificationType.logReminder)
          .copyWith(minute: 5)
          .minute,
      5,
    );
    expect(() => NotificationPrefs(quietStart: 1440), throwsRangeError);
    expect(
      () => NotificationTypePrefs(enabled: true, minute: -1),
      throwsRangeError,
    );
  });
}
