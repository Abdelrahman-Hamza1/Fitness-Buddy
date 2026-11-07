import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/chat/chat_text.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';

/// Buddy's conversation summary writes (A66 D9, `06` §6.1, AI-165): the
/// server's `summary` event is stored only when the phone's revision is
/// still the one the compaction named, and "Buddy remembers" can clear it.
/// Bookkeeping like the chat transcript: no undo.
sealed class BuddySummaryOp implements ChangeOp {
  const new _();

  /// The stable handler family.
  static const familyName = 'buddySummary';

  /// The longest summary (`buddySummary.text`, UTF-16 units).
  static const maxText = 1500;

  @override
  String get family => familyName;
}

/// Why a summary op is refused.
enum InvalidBuddySummary {
  /// Not well-formed, or longer than [BuddySummaryOp.maxText].
  text('buddySummaryText'),

  /// Revision below 1, or not the expected revision + 1.
  revision('buddySummaryRevision'),

  /// The watermark isn't a UUID.
  watermark('buddySummaryWatermark'),

  /// The stored revision isn't the expected one any more.
  stale('buddySummaryStale');

  new(this.code);

  /// The rejection code.
  final String code;
}

/// Stores summary [text] at [revision] summarising up to [watermark], when
/// the stored revision (0 for none, the highest live one otherwise) is
/// still [expectedRevision]. The handler writes the one natural-ID row
/// (`naturalId('buddySummary', 'self')`), reviving it after a Clear, and
/// tombstones any other live row (a competing row from before).
final class SaveBuddySummary extends BuddySummaryOp {
  /// The summary.
  const new({
    required this.text,
    required this.revision,
    required this.watermark,
    required this.expectedRevision,
  }) : super._();

  /// The summary. User content: never logged.
  final String text;

  /// Its revision (= [expectedRevision] + 1).
  final int revision;

  /// The last summarised message.
  final String watermark;

  /// The revision the phone held when it asked.
  final int expectedRevision;

  /// The first rule this op breaks, or `null`.
  InvalidBuddySummary? validate() {
    if (!ChatText.admits(text, limit: BuddySummaryOp.maxText)) {
      return InvalidBuddySummary.text;
    }
    if (expectedRevision < 0 || revision != expectedRevision + 1) {
      return InvalidBuddySummary.revision;
    }
    if (!isUuid(watermark)) return InvalidBuddySummary.watermark;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is SaveBuddySummary &&
      other.text == text &&
      other.revision == revision &&
      other.watermark == watermark &&
      other.expectedRevision == expectedRevision;

  @override
  int get hashCode => Object.hash(
    SaveBuddySummary,
    text,
    revision,
    watermark,
    expectedRevision,
  );

  @override
  String toString() => 'SaveBuddySummary(r$revision)';
}

/// Clears the summary ("Buddy remembers", AI-165): every live row is
/// tombstoned with its text scrubbed.
final class ClearBuddySummary extends BuddySummaryOp {
  /// The clear.
  const new() : super._();

  @override
  bool operator ==(Object other) => other is ClearBuddySummary;

  @override
  int get hashCode => (ClearBuddySummary).hashCode;

  @override
  String toString() => 'ClearBuddySummary';
}
