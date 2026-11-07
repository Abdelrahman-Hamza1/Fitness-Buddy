import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/personal_slice.dart';

/// What of Buddy's memory goes with a turn (A67 D13, `06` §6.4): explicit
/// items as `profile.memory` (≤ 30, newest first), explicit defaults and
/// learned habits as `profile.defaults` (≤ 20), and `readMemory`'s topic
/// match. Shown tips (`nudge`) never leave the phone. Pure.
abstract final class MemorySlice {
  /// The most memory items sent.
  static const memory = 30;

  /// The most defaults sent.
  static const defaults = 20;

  static bool _sent(MemoryItem m) =>
      m.kind != MemoryKinds.nudge &&
      m.key.length <= MemoryItemOp.maxText &&
      m.value.length <= MemoryItemOp.maxText;

  /// The explicit items of [items] (newest first).
  static List<BuddyMemory> profile(List<MemoryItem> items) => [
    for (final m
        in items
            .where((m) => _sent(m) && m.origin == MemoryOrigin.explicit)
            .take(memory))
      BuddyMemory(kind: m.kind, key: m.key, value: m.value),
  ];

  /// Explicit defaults first, then learned habits without one.
  static List<BuddyHabitDefault> habits(List<MemoryItem> items) {
    final explicit = [
      for (final m in items)
        if (m.kind == MemoryKinds.defaultValue && _sent(m)) m,
    ];
    final keys = {for (final m in explicit) m.key};
    final learned = [
      for (final m in items)
        if (m.kind == MemoryKinds.habit && _sent(m) && !keys.contains(m.key)) m,
    ];
    return [
      for (final m in [...explicit, ...learned].take(defaults))
        if (m.key.split(':') case [final kind, final subject, ...]
            when kind.length <= 32)
          BuddyHabitDefault(kind: kind, subject: subject, value: m.value),
    ];
  }

  static String _text(MemoryItem m) =>
      '${m.key.replaceAll(':', ' ').replaceAll('_', ' ')} ${m.value}';

  /// `readMemory`: the items sharing a word with [topic] (every sent one
  /// without a topic), at most [memory].
  static List<BuddyMemory> read(List<MemoryItem> items, String? topic) {
    final words = topic == null ? null : PersonalSlice.wordsOf(topic);
    return [
      for (final m
          in items
              .where(_sent)
              .where(
                (m) =>
                    words == null ||
                    words.isEmpty ||
                    PersonalSlice.wordsOf(_text(m))
                        .intersection(words)
                        .isNotEmpty,
              )
              .take(memory))
        BuddyMemory(kind: m.kind, key: m.key, value: m.value),
    ];
  }
}
