import 'package:fb_domain/fb_domain.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Which cards each assistant message's session still holds (A23 D7): a
/// follow-up or a fact rebuild moves a card to a new message, but the
/// in-memory session of the source message still contains it. Members are
/// the session's cards minus the cards that departed from its message.
///
/// Also remembers which messages are follow-up replies, for the confirmed
/// outcome (A23 D9). A restored session already excludes its departed cards
/// (the engine reads them from the stored budget).
@immutable
final class SessionMembership {
  /// Departed card IDs by source message, and the follow-up reply IDs.
  const new({this._departed = const {}, this._followUps = const {}});

  final Map<String, Set<String>> _departed;
  final Set<String> _followUps;

  /// The message whose budget [session] is: its cards' `budgetMessageId`,
  /// or `null` for a session without cards.
  static String? messageOf(ProposalSession session) =>
      session.cards.firstOrNull?.budgetMessageId;

  /// The cards that left message [messageId] for another one.
  Set<String> departedFrom(String messageId) =>
      _departed[messageId] ?? const {};

  /// The cards of [session] that still belong to its message.
  List<ProposalCard> members(ProposalSession session) {
    final message = messageOf(session);
    final gone = message == null ? const <String>{} : departedFrom(message);
    return [
      for (final c in session.cards)
        if (!gone.contains(c.id) && c.budgetMessageId == message) c,
    ];
  }

  /// Whether assistant message [messageId] is a follow-up reply (it answers
  /// a user message about an existing card).
  bool isFollowUp(String messageId) => _followUps.contains(messageId);

  /// After card [cardId] moved from [from] to follow-up reply [to].
  SessionMembership followedUp(String cardId, String from, String to) =>
      SessionMembership(
        departed: {
          ..._departed,
          from: {...departedFrom(from), cardId},
        },
        followUps: {..._followUps, to},
      );

  /// After card [cardId] moved from [from] to a rebuild message (not a
  /// follow-up, A23 D11).
  SessionMembership rebuilt(String cardId, String from) => SessionMembership(
    departed: {
      ..._departed,
      from: {...departedFrom(from), cardId},
    },
    followUps: _followUps,
  );

  /// With [other]'s departures and follow-ups added (a restored page).
  SessionMembership merge(SessionMembership other) => SessionMembership(
    departed: {
      for (final key in {..._departed.keys, ...other._departed.keys})
        key: {...departedFrom(key), ...other.departedFrom(key)},
    },
    followUps: {..._followUps, ...other._followUps},
  );

  @override
  String toString() =>
      'SessionMembership(${_departed.length} sources, '
      '${_followUps.length} follow-ups)';
}
