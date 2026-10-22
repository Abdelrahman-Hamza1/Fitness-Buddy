// Host-only VM heap probe. Flutter's test engine has no VM service; a fresh
// Dart VM provides an isolated, GC-measured retained-size gate without deps.
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:fb_domain/fb_domain.dart';

Future<void> main() async {
  final words = (jsonDecode(
    await utf8.decoder.bind(stdin).join(),
  ) as List<dynamic>).cast<String>();
  final result = await measureIndex(words);
  final json = jsonEncode({
    'ms': result.ms,
    'bytes': result.bytes,
    'keys': result.keys,
    'two': result.two,
  });
  stdout.writeln('INDEX_JSON:$json');
  await developer.Service.controlWebServer(silenceOutput: true);
}

/// Cold build in an isolated heap. VM GC measures retained heap, rather than
/// process RSS (which includes JIT, Flutter, SQLite and dead temporary
/// objects).
Future<({double ms, int bytes, int keys, bool two})> measureIndex(
  List<String> words,
) => Isolate.run(() async {
  final server = await developer.Service.controlWebServer(
    enable: true,
    silenceOutput: true,
  );
  final uri = server.serverUri!;
  final isolate = developer.Service.getIsolateId(Isolate.current)!;
  Future<int> heap() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        uri
            .resolve('getAllocationProfile')
            .replace(queryParameters: {'isolateId': isolate, 'gc': 'true'}),
      );
      final response = await request.close();
      final body = jsonDecode(
        await utf8.decoder.bind(response).join(),
      ) as Map<String, dynamic>;
      final result = body['result'] as Map<String, dynamic>;
      final memory = result['memoryUsage'] as Map<String, dynamic>;
      return (memory['heapUsage'] as int) + (memory['externalUsage'] as int);
    } finally {
      client.close(force: true);
    }
  }

  final before = await heap();
  final timer = Stopwatch()..start();
  final index = FuzzyIndex.build(words);
  timer.stop();
  final after = await heap();
  // Keep the complete index reachable through the GC above.
  final keys = index.deletionKeyCount;
  return (
    ms: timer.elapsedMicroseconds / 1000,
    bytes: after - before,
    keys: keys,
    two: index.distanceTwoEnabled,
  );
});
