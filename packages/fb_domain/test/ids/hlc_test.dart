import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

const _device = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _other = '0199e3c2-0000-7000-8000-000000000001';
const _base = 1760351234567;

Hlc _hlc(int wallMs, int counter, [String deviceId = _device]) =>
    Hlc(wallMs: wallMs, counter: counter, deviceId: deviceId);

Hlc _ok(HlcReceive result) => switch (result) {
  HlcReceived(:final hlc) => hlc,
  HlcDriftRejected(:final aheadBy) => fail('rejected, ahead by $aheadBy'),
};

/// A step for the receive property: the physical clock, then either a local
/// event or a remote timestamp near it.
typedef _Step = ({
  int physical,
  bool isReceive,
  int remoteWall,
  int remoteCounter,
  String remoteDevice,
});

extension on Any {
  Generator<_Step> get step => combine5(
    intInRange(0, 20),
    this.bool,
    intInRange(-5, 25),
    either(intInRange(0, 3), intInRange(0, 1000)),
    fewDeviceIds,
    (physical, isReceive, remoteWall, remoteCounter, remoteDevice) => (
      physical: _base + physical,
      isReceive: isReceive,
      remoteWall: _base + remoteWall,
      remoteCounter: remoteCounter,
      remoteDevice: remoteDevice,
    ),
  );
}

void main() {
  group('HLC text form:', () {
    test('HLC toString/parse round trip', () {
      final hlc = _hlc(_base, 42);
      const text = '1760351234567-00042-$_device';
      expect(hlc.toString(), text);
      expect(Hlc.parse(text), hlc);
      expect(_hlc(0, 0).toString(), '0000000000000-00000-$_device');
      expect(
        _hlc(Hlc.maxWallMs, Hlc.maxCounter).toString(),
        '9999999999999-99999-$_device',
      );
    });

    test('HLC parse rejects anything but the exact fixed-width form', () {
      for (final bad in [
        '176035123456-00042-$_device', // 12-digit wall
        '1760351234567-0042-$_device', // 4-digit counter
        '1760351234567-00042-${_device.toUpperCase()}',
        '1760351234567-00042-$_device ',
        '1760351234567_00042_$_device',
        '1760351234567-00042-not-a-uuid-at-all-but-36-characters!',
        '-760351234567-00042-$_device',
        '',
      ]) {
        expect(Hlc.tryParse(bad), isNull, reason: bad);
        expect(() => Hlc.parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('HLC fields and device id are validated (A6)', () {
      expect(() => _hlc(-1, 0), throwsRangeError);
      expect(() => _hlc(Hlc.maxWallMs + 1, 0), throwsRangeError);
      expect(() => _hlc(0, -1), throwsRangeError);
      expect(() => _hlc(0, Hlc.maxCounter + 1), throwsRangeError);
      for (final bad in [
        _device.toUpperCase(),
        'device-1',
        '0199e3c25b1a7c3d8e4f0123456789ab',
        '',
      ]) {
        expect(() => _hlc(0, 0, bad), throwsArgumentError, reason: bad);
        expect(
          () => HybridLogicalClock(clock: ManualClock.millis(0), deviceId: bad),
          throwsArgumentError,
          reason: bad,
        );
      }
      expect(Hlc.checkDeviceId(_device), _device);
    });

    test('HLC orders by wall, then counter, then device id', () {
      final a = _hlc(_base, 5, _other);
      expect(a < _hlc(_base + 1, 0, _other), isTrue);
      expect(
        a < _hlc(_base, 6, '00000000-0000-7000-8000-000000000000'),
        isTrue,
      );
      expect(_hlc(_base, 5) > a, isTrue); // ties go to the higher device id
      expect(a.compareTo(_hlc(_base, 5, _other)), 0);
      expect(a > a, isFalse);
      expect(a, _hlc(_base, 5, _other));
      expect(a.hashCode, _hlc(_base, 5, _other).hashCode);
      expect(a == _hlc(_base, 5), isFalse);
    });
  });

  group('HybridLogicalClock:', () {
    test('HLC now() follows the physical clock and counts within a ms', () {
      final clock = ManualClock.millis(_base);
      final hlc = HybridLogicalClock(clock: clock, deviceId: _device);
      expect(hlc.last, isNull);
      expect(hlc.now(), _hlc(_base, 0));
      expect(hlc.now(), _hlc(_base, 1));
      clock.millis = _base + 10;
      expect(hlc.now(), _hlc(_base + 10, 0));
      clock.millis = _base; // the clock goes backwards
      expect(hlc.now(), _hlc(_base + 10, 1));
      expect(hlc.last, _hlc(_base + 10, 1));
      expect(hlc.maxForwardDrift, const Duration(hours: 24));
    });

    test('HLC restored from the last stored value stays ahead of it', () {
      // The stored HLC is ahead of the physical clock (it came from a peer).
      final hlc = HybridLogicalClock(
        clock: ManualClock.millis(_base),
        deviceId: _device,
        last: _hlc(_base + 500, 7, _other),
      );
      expect(hlc.last, _hlc(_base + 500, 7));
      expect(hlc.now(), _hlc(_base + 500, 8));
    });

    test('HLC receive follows the standard rules', () {
      final clock = ManualClock.millis(_base);
      final hlc = HybridLogicalClock(clock: clock, deviceId: _device);
      // No local history, remote on the physical ms: remote counter + 1.
      expect(_ok(hlc.receive(_hlc(_base, 3, _other))), _hlc(_base, 4));
      // Remote ahead: its wall, its counter + 1, our device id.
      expect(
        _ok(hlc.receive(_hlc(_base + 50, 9, _other))),
        _hlc(_base + 50, 10),
      );
      // Local ahead of the remote: local counter + 1.
      expect(
        _ok(hlc.receive(_hlc(_base + 20, 99, _other))),
        _hlc(_base + 50, 11),
      );
      // All three on one ms: max of both counters + 1.
      expect(
        _ok(hlc.receive(_hlc(_base + 50, 30, _other))),
        _hlc(_base + 50, 31),
      );
      // Physical clock ahead of both: counter 0.
      clock.millis = _base + 100;
      expect(
        _ok(hlc.receive(_hlc(_base + 60, 5, _other))),
        _hlc(_base + 100, 0),
      );
    });

    test('HLC counter overflow throws', () {
      final clock = ManualClock.millis(_base);
      final hlc = HybridLogicalClock(
        clock: clock,
        deviceId: _device,
        last: _hlc(_base, Hlc.maxCounter),
      );
      expect(
        hlc.now,
        throwsA(
          isA<HlcOverflowException>()
              .having((e) => e.wallMs, 'wallMs', _base)
              .having((e) => '$e', 'text', contains('$_base')),
        ),
      );
      expect(
        () => hlc.receive(_hlc(_base, 0, _other)),
        throwsA(isA<HlcOverflowException>()),
      );
      expect(
        () => HybridLogicalClock(
          clock: clock,
          deviceId: _device,
        ).receive(_hlc(_base, Hlc.maxCounter, _other)),
        throwsA(isA<HlcOverflowException>()),
      );
      expect(hlc.last, _hlc(_base, Hlc.maxCounter)); // unchanged
    });

    test('HLC remote beyond maxForwardDrift is rejected, not merged (A6)', () {
      final clock = ManualClock.millis(_base);
      final hlc = HybridLogicalClock(clock: clock, deviceId: _device);
      const day = Duration(hours: 24);
      final atLimit = _hlc(_base + day.inMilliseconds, 0, _other);
      expect(_ok(hlc.receive(atLimit)).wallMs, atLimit.wallMs);

      final fresh = HybridLogicalClock(clock: clock, deviceId: _device);
      final tooFar = _hlc(_base + day.inMilliseconds + 1, 0, _other);
      final result = fresh.receive(tooFar);
      expect(
        result,
        isA<HlcDriftRejected>()
            .having((r) => r.remote, 'remote', tooFar)
            .having(
              (r) => r.aheadBy,
              'aheadBy',
              day + const Duration(milliseconds: 1),
            ),
      );
      expect(fresh.last, isNull); // the clock is unchanged

      final strict = HybridLogicalClock(
        clock: clock,
        deviceId: _device,
        maxForwardDrift: const Duration(minutes: 5),
      );
      expect(
        strict.receive(_hlc(_base + 300001, 0, _other)),
        isA<HlcDriftRejected>(),
      );
      expect(
        () => HybridLogicalClock(
          clock: clock,
          deviceId: _device,
          maxForwardDrift: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('HLC a physical clock outside the 13-digit range is an error', () {
      expect(
        () => HybridLogicalClock(
          clock: ManualClock.millis(-1),
          deviceId: _device,
        ).now(),
        throwsStateError,
      );
      expect(
        () => HybridLogicalClock(
          clock: ManualClock.millis(Hlc.maxWallMs + 1),
          deviceId: _device,
        ).receive(_hlc(0, 0)),
        throwsStateError,
      );
    });
  });

  group('property: HLC', () {
    Glados(any.hlc, propertyRuns).test('parse(toString) is identity', (hlc) {
      final text = hlc.toString();
      expect(text, hasLength(56));
      expect(Hlc.parse(text), hlc);
      expect(Hlc.parse(text).toString(), text);
    });

    Glados2(any.hlc, any.hlc, propertyRuns).test(
      'string order equals compareTo order',
      (a, b) {
        expect(
          a.toString().compareTo(b.toString()).sign,
          a.compareTo(b).sign,
          reason: '$a vs $b',
        );
        expect(a.compareTo(b).sign, -b.compareTo(a).sign);
        expect(a.compareTo(b) == 0, a == b);
      },
    );

    Glados(
      any.listWithLengthInRange(1, 80, any.intInRange(0, 20)),
      propertyRuns,
    ).test('now() is strictly monotonic under any clock sequence', (offsets) {
      final clock = ManualClock.millis(_base);
      final hlc = HybridLogicalClock(clock: clock, deviceId: _device);
      Hlc? previous;
      for (final offset in offsets) {
        clock.millis = _base + offset;
        final next = hlc.now();
        if (previous != null) expect(next > previous, isTrue);
        // Never behind the physical clock.
        expect(next.wallMs, greaterThanOrEqualTo(_base + offset));
        previous = next;
      }
    });

    Glados(any.listWithLengthInRange(1, 60, any.step), propertyRuns).test(
      'receive(r) > both the last local and r',
      (steps) {
        final clock = ManualClock.millis(_base);
        final hlc = HybridLogicalClock(clock: clock, deviceId: _device);
        for (final step in steps) {
          clock.millis = step.physical;
          final before = hlc.last;
          if (!step.isReceive) {
            final next = hlc.now();
            if (before != null) expect(next > before, isTrue);
            continue;
          }
          final remote = _hlc(
            step.remoteWall,
            step.remoteCounter,
            step.remoteDevice,
          );
          final merged = _ok(hlc.receive(remote));
          expect(merged > remote, isTrue, reason: '$merged vs $remote');
          if (before != null) expect(merged > before, isTrue);
          expect(merged.deviceId, _device);
          expect(merged.wallMs, greaterThanOrEqualTo(step.physical));
        }
      },
    );
  });
}
