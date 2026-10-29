import 'package:fb_domain/src/changes/domain_event.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// A workout session was logged (WO-010, WO-061): calorie shifting and the
/// weekly summary react to it. Carries IDs and the date only, never content.
final class WorkoutSessionLogged extends DomainEvent {
  /// Session [sessionId] was logged for [date].
  const new(this.sessionId, this.date);

  /// The session.
  final String sessionId;

  /// Its training day.
  final LocalDate date;

  @override
  bool operator ==(Object other) =>
      other is WorkoutSessionLogged &&
      other.sessionId == sessionId &&
      other.date == date;

  @override
  int get hashCode => Object.hash(WorkoutSessionLogged, sessionId, date);

  @override
  String toString() => 'WorkoutSessionLogged($sessionId, $date)';
}
