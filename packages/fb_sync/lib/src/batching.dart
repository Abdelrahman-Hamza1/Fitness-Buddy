import 'dart:convert';

import 'package:fb_api_client/fb_api_client.dart';

/// The push limits (`05` §5.2, B05, B18 D14).
abstract final class PushLimits {
  /// Changes per push request.
  static const int maxChanges = 500;

  /// The byte budget of one push body: under the host's 256 KiB request cap
  /// with margin for headers and the envelope.
  static const int maxBodyBytes = 240 * 1024;

  /// The request envelope around the changes, with a dataset id.
  static const int envelopeBytes = 160;
}

/// The UTF-8 size of [change] as the push body encodes it (`jsonEncode`'s
/// default: non-ASCII unescaped, B18 D14).
int encodedChangeBytes(SyncChange change) =>
    utf8.encode(jsonEncode(change.toJson())).length;

/// [changes] in order, split into push requests of at most
/// [PushLimits.maxChanges] changes and [PushLimits.maxBodyBytes] bytes. A
/// change over the byte budget on its own goes alone (the server answers
/// 413 if it is really too large, and the engine parks it).
List<List<SyncChange>> pushBatches(
  List<SyncChange> changes, {
  int maxChanges = PushLimits.maxChanges,
  int maxBodyBytes = PushLimits.maxBodyBytes,
}) {
  final batches = <List<SyncChange>>[];
  var batch = <SyncChange>[];
  var bytes = PushLimits.envelopeBytes;
  for (final change in changes) {
    final size = encodedChangeBytes(change);
    final next = bytes + size + (batch.isEmpty ? 0 : 1);
    if (batch.isNotEmpty &&
        (next > maxBodyBytes || batch.length >= maxChanges)) {
      batches.add(batch);
      batch = [];
      bytes = PushLimits.envelopeBytes;
    }
    bytes += size + (batch.isEmpty ? 0 : 1);
    batch.add(change);
  }
  if (batch.isNotEmpty) batches.add(batch);
  return batches;
}
