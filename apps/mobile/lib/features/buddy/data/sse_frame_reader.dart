import 'dart:async';
import 'dart:convert';

/// One server-sent event: its `id:` (or `null`) and its `data:` lines
/// joined by `\n`. Holds user content: never logged.
final class SseFrame {
  /// A frame.
  const new({required this.id, required this.data});

  /// The event's `id:` field, or `null` when it had none.
  final String? id;

  /// The event's data.
  final String data;

  @override
  String toString() => 'SseFrame($id)';
}

/// The hand-written part of the Buddy turn protocol (TD-125): the
/// `text/event-stream` framing over a byte stream (WHATWG §9.2, the subset
/// the server uses). UTF-8 across chunk boundaries, `\n`, `\r\n` and `\r`
/// line ends, `id:` and multi-line `data:` fields, comments (`: ping`
/// heartbeats) and unknown fields ignored, a blank line dispatches. A frame
/// without data is dropped; a trailing frame without its blank line is
/// dropped (the stream broke mid-event).
final class SseFrameReader extends StreamTransformerBase<List<int>, SseFrame> {
  /// The reader.
  const new();

  @override
  Stream<SseFrame> bind(Stream<List<int>> stream) async* {
    String? id;
    final data = <String>[];
    var pendingCr = false;
    final line = StringBuffer();
    await for (final text in utf8.decoder.bind(stream)) {
      final out = <SseFrame>[];
      void endLine() {
        final value = line.toString();
        line.clear();
        if (value.isEmpty) {
          if (data.isNotEmpty) out.add(SseFrame(id: id, data: data.join('\n')));
          data.clear();
          id = null;
          return;
        }
        if (value.startsWith(':')) return;
        final colon = value.indexOf(':');
        final field = colon < 0 ? value : value.substring(0, colon);
        var rest = colon < 0 ? '' : value.substring(colon + 1);
        if (rest.startsWith(' ')) rest = rest.substring(1);
        switch (field) {
          case 'data':
            data.add(rest);
          case 'id':
            // An id with NUL is ignored (WHATWG).
            if (!rest.contains('\u0000')) id = rest;
        }
      }

      for (var i = 0; i < text.length; i++) {
        final c = text.codeUnitAt(i);
        if (pendingCr) {
          pendingCr = false;
          if (c == 0x0A) continue;
        }
        if (c == 0x0D) {
          endLine();
          pendingCr = true;
        } else if (c == 0x0A) {
          endLine();
        } else {
          line.writeCharCode(c);
        }
      }
      yield* Stream.fromIterable(out);
    }
  }
}
