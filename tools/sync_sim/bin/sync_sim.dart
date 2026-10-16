import 'dart:convert';
import 'dart:io';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:sync_sim/sync_sim.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError(
      'usage: sync_sim.dart <loopback-base-url> (key from SYNC_SPIKE_KEY)',
    );
  }
  final base = Uri.parse(args.single);
  if (base.scheme != 'http' || base.host != '127.0.0.1') {
    throw ArgumentError('synthetic harness only permits loopback');
  }
  final key = Platform.environment['SYNC_SPIKE_KEY']!;
  final transport = ApiSyncTransport(
    baseUrl: base.toString(),
    key: key,
    deviceId: syntheticId(1),
  );
  final now = DateTime.now().toUtc();
  try {
    // Close a TCP connection after only part of the declared JSON body. Kestrel
    // must not apply any change; retrying the full immutable version is safe.
    final row = SyncChange(
      entity: 'diaryEntry',
      id: syntheticId(9000003),
      schemaVersion: 1,
      hlc: '${now.millisecondsSinceEpoch}-00000-${syntheticId(1)}',
      deviceId: syntheticId(1),
      deletedAt: null,
      payload: const {'value': 'partial-body'},
    );
    final body = utf8.encode(jsonEncode(SyncPushRequest(changes: [row])));
    final socket = await Socket.connect(base.host, base.port);
    socket
      ..write(
        'POST /v1/sync/push HTTP/1.1\r\nHost: localhost\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: ${body.length}\r\nX-App-Version: 0.1.0\r\n'
        'X-Platform: android\r\n'
        'X-Device-Id: ${syntheticId(1)}\r\nX-Sync-Spike-Key: $key\r\n\r\n',
      )
      ..add(body.sublist(0, body.length ~/ 2));
    await socket.flush();
    socket.destroy();
    require(
      (await transport.pull('0', 500)).changes.isEmpty,
      'partial-body push committed',
    );
    await transport.push([row]);
    await transport.push([row]);
    require(
      (await transport.pull('0', 500)).changes.length == 1,
      'partial-body retry duplicated data',
    );
    await runFaults(transport, now);
    stdout.writeln(
      'real API: partial-body drop, lost acknowledgement, duplicate, '
      'crash and concurrent-edit faults passed',
    );
    for (var seed = 0; seed < 50; seed++) {
      await runScenario(transport, seed, now);
      if ((seed + 1) % 10 == 0) {
        stdout.writeln('real API: ${seed + 1}/50 randomized runs passed');
      }
    }
    final timing = await benchmark(transport, now);
    stdout.writeln(
      '5000 rows: push=${timing.pushMs} ms; fresh pull=${timing.pullMs} ms '
      '(Docker loopback; not Wi-Fi)',
    );
  } finally {
    transport.close();
  }
}
