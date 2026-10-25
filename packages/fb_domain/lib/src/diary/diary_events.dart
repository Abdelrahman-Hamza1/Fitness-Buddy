import 'package:fb_domain/src/changes/domain_event.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// Something happened to diary entries (A06 D14). Carries only the entry IDs
/// and the affected dates, never food names or numbers: readers (memory,
/// the notification planner) read the rows themselves.
sealed class DiaryEntriesEvent extends DomainEvent {
  new _(this._name, Iterable<String> entryIds, Iterable<LocalDate> dates)
    : entryIds = Set.unmodifiable(entryIds),
      dates = Set.unmodifiable(dates);

  final String _name;

  /// The entries. Unmodifiable.
  final Set<String> entryIds;

  /// The diary days affected. Unmodifiable.
  final Set<LocalDate> dates;

  @override
  bool operator ==(Object other) =>
      other is DiaryEntriesEvent &&
      other.runtimeType == runtimeType &&
      other.entryIds.length == entryIds.length &&
      other.entryIds.containsAll(entryIds) &&
      other.dates.length == dates.length &&
      other.dates.containsAll(dates);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    Object.hashAllUnordered(entryIds),
    Object.hashAllUnordered(dates),
  );

  @override
  String toString() {
    final sorted = dates.toList()..sort();
    return '$_name(${entryIds.length} entries, ${sorted.join(', ')})';
  }
}

/// Entries were logged or copied in.
final class EntriesLogged extends DiaryEntriesEvent {
  /// [entryIds] were logged on [dates].
  new(Iterable<String> entryIds, Iterable<LocalDate> dates)
    : super._('EntriesLogged', entryIds, dates);
}

/// Entries were updated or moved, or their dish group moved or went away.
/// [dates] has the old and the new days.
final class EntryChanged extends DiaryEntriesEvent {
  /// [entryIds] changed, affecting [dates].
  new(Iterable<String> entryIds, Iterable<LocalDate> dates)
    : super._('EntryChanged', entryIds, dates);
}

/// Entries were deleted.
final class EntryDeleted extends DiaryEntriesEvent {
  /// [entryIds] on [dates] were deleted.
  new(Iterable<String> entryIds, Iterable<LocalDate> dates)
    : super._('EntryDeleted', entryIds, dates);
}

/// A day's incomplete mark was set or cleared (DY-004).
final class DayMarked extends DomainEvent {
  /// [date] is now [incomplete] or not.
  const new(this.date, {required this.incomplete});

  /// The day.
  final LocalDate date;

  /// Whether it is marked incomplete now.
  final bool incomplete;

  @override
  bool operator ==(Object other) =>
      other is DayMarked &&
      other.date == date &&
      other.incomplete == incomplete;

  @override
  int get hashCode => Object.hash(DayMarked, date, incomplete);

  @override
  String toString() => 'DayMarked($date, incomplete: $incomplete)';
}

/// Slot identities affected by a customization; no private labels.
final class MealSlotsChanged extends DomainEvent {
  /// Immutable affected identity set.
  new(Iterable<String> slotIds) : slotIds = Set.unmodifiable(slotIds);

  /// Changed meals.
  final Set<String> slotIds;
  @override
  bool operator ==(Object other) =>
      other is MealSlotsChanged &&
      slotIds.length == other.slotIds.length &&
      slotIds.containsAll(other.slotIds);
  @override
  int get hashCode => Object.hashAllUnordered(slotIds);
  @override
  String toString() => 'MealSlotsChanged(${slotIds.length})';
}
