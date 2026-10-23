import 'package:fb_mobile/core/session/session_state.dart';
import 'package:flutter/services.dart';

/// PA2: acknowledgement that every plugin backing file reached commit().
abstract interface class SessionStorageDurability {
  /// Throws on false, timeout, platform failure or missing acknowledgement.
  Future<void> commit();
}

/// No file names, keys or credentials cross this app-owned channel.
final class AndroidSessionStorageDurability
    implements SessionStorageDurability {
  /// Creates the Android-only barrier. No plaintext or other-platform fallback.
  const new();

  static const _channel = MethodChannel('fitness_buddy/session_storage');

  @override
  Future<void> commit() async {
    try {
      final acknowledged = await _channel
          .invokeMethod<bool>('commit')
          .timeout(const Duration(seconds: 10));
      if (acknowledged == true) return;
    } on Object {
      // Drop platform messages/details; they are never diagnostic payloads.
    }
    throw const SessionStorageFailure(SessionStorageFailureKind.durability);
  }
}
