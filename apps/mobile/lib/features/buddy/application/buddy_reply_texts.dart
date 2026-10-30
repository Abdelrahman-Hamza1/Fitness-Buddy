/// Buddy's fixed English reply templates (A22 D7, D16; AI-143), rendered
/// from ARB by the presentation layer and handed to the send path, which
/// has no `BuildContext`. Never model text.
final class BuddyReplyTexts {
  /// The templates.
  const new({
    required this.cards,
    required this.updated,
    required this.cardClosed,
    required this.medical,
    required this.notFood,
    required this.noCard,
    required this.unsupported,
  });

  /// A reply with one or more proposal cards.
  final String cards;

  /// A follow-up that updated the open card (A22b E2): "Updated your card."
  final String updated;

  /// A follow-up whose card was logged or discarded before its answer could
  /// be applied: the card is left as it is.
  final String cardClosed;

  /// A medical question: "I can't help with medical questions. …".
  final String medical;

  /// Anything else that isn't food (clarify, out of scope, weigh-in):
  /// "I can log food here. Try something like …".
  final String notFood;

  /// A 200 that couldn't become a card: "I couldn't make a card from that.
  /// Try search instead."
  final String noCard;

  /// An intent this version can't handle yet (B09 D4 `unrecognized`):
  /// "Buddy can't do that in this version yet. …".
  final String unsupported;

  @override
  String toString() => 'BuddyReplyTexts';
}
