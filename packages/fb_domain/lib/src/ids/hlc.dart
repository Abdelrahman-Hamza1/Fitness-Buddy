import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/time/clock.dart';

/// A hybrid logical clock timestamp (`updated_hlc`, `05` §1 and §5): wall
/// time, a counter for events within the same wall millisecond, and the
/// device that made it (S08 D10, A6).
///
/// **Text form** (stored and sent), wall ms in 13 digits, counter in 5
/// digits, then the device ID:
///
/// ```text
/// <wall ms>-<counter>-<device id>
/// 1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab
/// ```
///
/// All three
/// parts have a fixed width, digits are zero-padded and the device ID is a
/// lowercase canonical UUID, so the **text order is the logical order**
/// (wall, then counter, then device ID; ties go to the higher device ID) and
/// [compareTo] agrees with comparing the text.
///
/// That only holds under a **binary (code-point) collation**. Databases must
/// compare HLC columns byte by byte: SQLite's default `BINARY` collation
/// (never `NOCASE` or a locale collation) and Postgres `COLLATE "C"` (a
/// locale collation may ignore the `-`). Forward note for S09, S12 and S26.
///
/// 13 digits of milliseconds last until the year 2286.
final class Hlc implements Comparable<Hlc> {
  /// A timestamp. Throws an `ArgumentError` if [wallMs] isn't
  /// 0…[maxWallMs], [counter] isn't 0…[maxCounter] or [deviceId] isn't a
  /// lowercase canonical UUID.
  new({required this.wallMs, required this.counter, required this.deviceId}) {
    if (wallMs < 0 || wallMs > maxWallMs) {
      throw RangeError.range(wallMs, 0, maxWallMs, 'wallMs');
    }
    if (counter < 0 || counter > maxCounter) {
      throw RangeError.range(counter, 0, maxCounter, 'counter');
    }
    checkDeviceId(deviceId);
  }

  /// Parses the text form exactly (fixed widths, lowercase device ID).
  /// Throws a `FormatException` otherwise.
  static Hlc parse(String text) {
    final hlc = tryParse(text);
    if (hlc == null) throw FormatException('not an HLC', text);
    return hlc;
  }

  /// Like [parse], but `null` instead of throwing.
  static Hlc? tryParse(String text) {
    final match = _text.matchAsPrefix(text);
    if (match == null || match.end != text.length) return null;
    final deviceId = match[3]!;
    if (!isUuid(deviceId)) return null;
    return Hlc(
      wallMs: int.parse(match[1]!),
      counter: int.parse(match[2]!),
      deviceId: deviceId,
    );
  }

  static final _text = RegExp(r'(\d{13})-(\d{5})-(.{36})');

  /// The largest wall time the 13-digit text can hold.
  static const int maxWallMs = 9999999999999;

  /// The largest counter the 5-digit text can hold.
  static const int maxCounter = 99999;

  /// [deviceId] if it is a lowercase canonical UUID, else an
  /// `ArgumentError`.
  static String checkDeviceId(String deviceId) {
    if (!isUuid(deviceId)) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'must be a lowercase canonical UUID',
      );
    }
    return deviceId;
  }

  /// Unix milliseconds (logical: never behind any HLC this one follows).
  final int wallMs;

  /// Orders events within the same [wallMs].
  final int counter;

  /// The device that made this timestamp.
  final String deviceId;

  @override
  int compareTo(Hlc other) => wallMs != other.wallMs
      ? wallMs.compareTo(other.wallMs)
      : counter != other.counter
      ? counter.compareTo(other.counter)
      : deviceId.compareTo(other.deviceId);

  /// Whether this timestamp is after [other].
  bool operator >(Hlc other) => compareTo(other) > 0;

  /// Whether this timestamp is before [other].
  bool operator <(Hlc other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.wallMs == wallMs &&
      other.counter == counter &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(wallMs, counter, deviceId);

  /// The text form (see the class comment).
  @override
  String toString() =>
      '${wallMs.toString().padLeft(13, '0')}-'
      '${counter.toString().padLeft(5, '0')}-$deviceId';
}

/// The counter of an HLC would pass [Hlc.maxCounter]: more than 100,000
/// events on one wall millisecond, which means the physical clock is stuck
/// far behind the logical one.
final class HlcOverflowException implements Exception {
  /// The counter ran out on the wall millisecond [wallMs].
  const new(this.wallMs);

  /// The wall millisecond whose counter ran out.
  final int wallMs;

  @override
  String toString() => 'HlcOverflowException: counter exhausted at $wallMs ms';
}

/// The result of [HybridLogicalClock.receive].
sealed class HlcReceive {
  /// The remote timestamp was merged; [hlc] is the new local timestamp.
  const factory ok(Hlc hlc) = HlcReceived;

  /// The remote timestamp is more than the allowed drift ahead of the local
  /// physical clock and was ignored.
  const factory driftRejected({
    required Hlc remote,
    required Duration aheadBy,
  }) = HlcDriftRejected;

  const new _();
}

/// The remote timestamp was merged; [hlc] is after both it and every
/// earlier local timestamp.
final class HlcReceived extends HlcReceive {
  /// The merge produced [hlc].
  const new(this.hlc) : super._();

  /// The new local timestamp.
  final Hlc hlc;
}

/// The remote timestamp was too far in the future and was not merged; the
/// clock is unchanged. What sync does with it is S26's policy.
final class HlcDriftRejected extends HlcReceive {
  /// [remote] is [aheadBy] ahead of the local physical clock.
  const new({required this.remote, required this.aheadBy}) : super._();

  /// The rejected timestamp.
  final Hlc remote;

  /// How far [remote] is ahead of the local physical clock.
  final Duration aheadBy;
}

/// One device's hybrid logical clock (Kulkarni et al.; `05` §5.2): every
/// timestamp it gives out is after every timestamp it gave out or received
/// before, even if the physical clock goes backwards, and stays close to
/// the physical clock.
///
/// The app restores [last] from storage at startup (the highest HLC it has
/// written), so the order also holds across restarts.
final class HybridLogicalClock {
  /// A clock for [deviceId] (a lowercase canonical UUID) reading physical
  /// time from `clock`. [maxForwardDrift] (default 24 h) is how far ahead of
  /// the physical clock a received timestamp may be. [last], if given,
  /// is the latest timestamp from before (its wall time and counter are
  /// used; its device ID may differ).
  new({
    required this._clock,
    required String deviceId,
    this.maxForwardDrift = const Duration(hours: 24),
    Hlc? last,
  }) : deviceId = Hlc.checkDeviceId(deviceId),
       _last = last == null
           ? null
           : Hlc(
               wallMs: last.wallMs,
               counter: last.counter,
               deviceId: deviceId,
             ) {
    if (maxForwardDrift.isNegative) {
      throw ArgumentError.value(maxForwardDrift, 'maxForwardDrift', 'is < 0');
    }
  }

  final Clock _clock;

  /// The device every timestamp from this clock carries.
  final String deviceId;

  /// How far ahead of the local physical clock a received timestamp may be.
  final Duration maxForwardDrift;

  Hlc? _last;

  /// The latest timestamp given out or merged, or `null` before the first.
  Hlc? get last => _last;

  /// A timestamp for a local event (a write, or a send): after [last].
  /// Throws an [HlcOverflowException] if the counter is exhausted.
  Hlc now() {
    final physical = _physicalMs();
    final last = _last;
    if (last == null || physical > last.wallMs) {
      return _set(physical, 0);
    }
    return _set(last.wallMs, _next(last.counter, last.wallMs));
  }

  /// Merges a timestamp [remote] from another device: the result is after
  /// [last] and after [remote]. A [remote] more than [maxForwardDrift] ahead
  /// of the physical clock is not merged ([HlcDriftRejected]), so one phone
  /// with a wrong clock can't drag every later write into the future. Throws
  /// an [HlcOverflowException] if the counter is exhausted.
  HlcReceive receive(Hlc remote) {
    final physical = _physicalMs();
    final ahead = remote.wallMs - physical;
    if (ahead > maxForwardDrift.inMilliseconds) {
      return HlcReceive.driftRejected(
        remote: remote,
        aheadBy: Duration(milliseconds: ahead),
      );
    }
    final last = _last;
    final localWall = last?.wallMs ?? -1;
    final wall = [physical, localWall, remote.wallMs].reduce(_max);
    final int counter;
    if (wall == localWall && wall == remote.wallMs) {
      counter = _next(_max(last!.counter, remote.counter), wall);
    } else if (wall == localWall) {
      counter = _next(last!.counter, wall);
    } else if (wall == remote.wallMs) {
      counter = _next(remote.counter, wall);
    } else {
      counter = 0;
    }
    return HlcReceive.ok(_set(wall, counter));
  }

  int _physicalMs() {
    final ms = _clock.nowUtc().millisecondsSinceEpoch;
    if (ms < 0 || ms > Hlc.maxWallMs) {
      throw StateError('clock out of the HLC range: $ms ms');
    }
    return ms;
  }

  static int _next(int counter, int wallMs) {
    if (counter >= Hlc.maxCounter) throw HlcOverflowException(wallMs);
    return counter + 1;
  }

  static int _max(int a, int b) => a > b ? a : b;

  Hlc _set(int wallMs, int counter) =>
      _last = Hlc(wallMs: wallMs, counter: counter, deviceId: deviceId);
}
