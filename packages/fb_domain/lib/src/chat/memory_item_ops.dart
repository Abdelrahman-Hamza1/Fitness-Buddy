import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/chat/chat_text.dart';
import 'package:fb_domain/src/diary/diary_entry.dart'
    show checkRowVersion, checkUuid;

/// Where a memory item came from (`memoryItem.createdFrom`, 06 §6.2).
enum MemoryOrigin {
  /// The user said it, or confirmed it on a card (AI-055).
  explicit('explicit'),

  /// Learned from confirmed data (AI-081): habits, shown tips.
  learned('learned');

  new(this.code);

  /// The wire code.
  final String code;

  /// The origin of [code], or `null` for an unknown one.
  static MemoryOrigin? fromCode(String code) {
    for (final o in values) {
      if (o.code == code) return o;
    }
    return null;
  }
}

/// The memory kinds the app writes (`memoryItem.kind` is open, ≤ 32).
abstract final class MemoryKinds {
  /// A default the cards apply (`<dimension>:<group>` → value).
  static const defaultValue = 'default';

  /// A usual amount of a food (`<food>` → `<amount> <unit>`).
  static const portion = 'portion';

  /// Another name for a food.
  static const alias = 'alias';

  /// A favourite brand.
  static const brand = 'brand';

  /// A nickname.
  static const nickname = 'nickname';

  /// A learned choice (`<question kind>` → option code, AI-065).
  static const habit = 'habit';

  /// A weighing tip shown (`<food>` → ISO day, AI-084).
  static const nudge = 'nudge';
}

/// One remembered item (`memoryItem` v1). User content: never logged.
final class MemoryItem {
  /// Item [id] at [version].
  new({
    required this.id,
    required this.version,
    required this.kind,
    required this.key,
    required this.value,
    required this.origin,
    required this.createdAt,
  }) {
    checkUuid(id, 'id');
    checkRowVersion(version);
  }

  /// Row ID (`naturalId('memoryItem', kind + key)`).
  final String id;

  /// Observed version.
  final int version;

  /// The open kind ([MemoryKinds]).
  final String kind;

  /// What it is about.
  final String key;

  /// What is remembered.
  final String value;

  /// Explicit or learned.
  final MemoryOrigin origin;

  /// When it was first written, UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is MemoryItem &&
      other.id == id &&
      other.version == version &&
      other.kind == kind &&
      other.key == key &&
      other.value == value &&
      other.origin == origin &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, version, kind, key, value, origin, createdAt);

  @override
  String toString() => 'MemoryItem($id@v$version, $kind)';
}

/// Buddy's memory writes (A67 D10, AI-055, AI-082): saved by a confirmed
/// card (undoable by its change set), deleted or cleared on "Buddy
/// remembers".
sealed class MemoryItemOp implements ChangeOp {
  const new _();

  /// The stable handler family.
  static const familyName = 'memoryItem';

  /// The longest kind (UTF-16 units).
  static const maxKind = 32;

  /// The longest key or value (UTF-16 units).
  static const maxText = 200;

  @override
  String get family => familyName;
}

/// Why a memory op is refused.
enum InvalidMemoryItem {
  /// Kind empty, too long or not well-formed.
  kind('memoryItemKind'),

  /// Key or value empty, too long or not well-formed.
  text('memoryItemText'),

  /// The row isn't there any more, or changed.
  stale('memoryItemStale');

  new(this.code);

  /// The rejection code.
  final String code;
}

/// Saves [value] for [kind] + [key]: the one natural-ID row of that pair,
/// written or revived (an overwrite replaces the value). With [checked] (a
/// confirmed card, A67 review) the row must still be as the card showed
/// it: absent when [expectedVersion] is `null`, else live at that version;
/// otherwise `memoryItemStale` (no overwrite of a newer value, no revival
/// of one deleted meanwhile).
final class SaveMemoryItem extends MemoryItemOp {
  /// The item.
  const new({
    required this.kind,
    required this.key,
    required this.value,
    this.origin = MemoryOrigin.explicit,
    this.checked = false,
    this.expectedVersion,
  }) : super._();

  /// Whether the row must be as shown.
  final bool checked;

  /// The live row's version as shown, or `null` for none.
  final int? expectedVersion;

  /// The kind.
  final String kind;

  /// The subject. User content.
  final String key;

  /// The value. User content.
  final String value;

  /// Explicit or learned.
  final MemoryOrigin origin;

  /// The first rule this op breaks, or `null`.
  InvalidMemoryItem? validate() {
    if (kind.trim().isEmpty ||
        !ChatText.admits(kind, limit: MemoryItemOp.maxKind)) {
      return InvalidMemoryItem.kind;
    }
    for (final t in [key, value]) {
      if (t.trim().isEmpty ||
          !ChatText.admits(t, limit: MemoryItemOp.maxText)) {
        return InvalidMemoryItem.text;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is SaveMemoryItem &&
      other.kind == kind &&
      other.key == key &&
      other.value == value &&
      other.origin == origin &&
      other.checked == checked &&
      other.expectedVersion == expectedVersion;

  @override
  int get hashCode => Object.hash(
    SaveMemoryItem,
    kind,
    key,
    value,
    origin,
    checked,
    expectedVersion,
  );

  @override
  String toString() => 'SaveMemoryItem($kind)';
}

/// Deletes item [id] when it is still at [expectedVersion] (tombstoned,
/// its key and value scrubbed).
final class DeleteMemoryItem extends MemoryItemOp {
  /// The delete.
  new(this.id, this.expectedVersion) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion);
  }

  /// The row.
  final String id;

  /// The version shown.
  final int expectedVersion;

  @override
  bool operator ==(Object other) =>
      other is DeleteMemoryItem &&
      other.id == id &&
      other.expectedVersion == expectedVersion;

  @override
  int get hashCode => Object.hash(DeleteMemoryItem, id, expectedVersion);

  @override
  String toString() => 'DeleteMemoryItem($id@v$expectedVersion)';
}

/// Clears every live item ("Buddy remembers" › Clear all).
final class ClearMemoryItems extends MemoryItemOp {
  /// The clear.
  const new() : super._();

  @override
  bool operator ==(Object other) => other is ClearMemoryItems;

  @override
  int get hashCode => (ClearMemoryItems).hashCode;

  @override
  String toString() => 'ClearMemoryItems';
}
