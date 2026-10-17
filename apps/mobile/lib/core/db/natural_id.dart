import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha1;
import 'package:fb_domain/fb_domain.dart' show isUuid;

/// Fitness Buddy's UUIDv5 namespace (A01 D6, TD-070). Fixed forever: every
/// natural id on every device is derived from it.
const String fbNamespace = '02ebdada-9a63-4b03-a1b0-da5747aabf36';

/// The deterministic id of the row whose natural key is [key] in [entity]
/// (A01 D6): `uuidv5(fbNamespace, '<entity>:<key>')`, a lowercase canonical
/// UUID, so two devices that create the same setting or default slot make
/// the same row and last-writer-wins merges them.
///
/// Examples: `naturalId('setting', 'units.system')`,
/// `naturalId('mealSlot', 'normal:breakfast')`.
String naturalId(String entity, String key) {
  checkEntityWireName(entity);
  if (key.isEmpty) throw ArgumentError.value(key, 'key', 'must not be empty');
  return uuidV5(fbNamespace, '$entity:$key');
}

/// The RFC 9562 version 5 UUID of [name] (UTF-8) in [namespace] (a
/// lowercase canonical UUID), as lowercase canonical text.
String uuidV5(String namespace, String name) {
  if (!isUuid(namespace)) {
    throw ArgumentError.value(namespace, 'namespace', 'is not a UUID');
  }
  final ns = namespace.replaceAll('-', '');
  final nsBytes = [
    for (var i = 0; i < 32; i += 2)
      int.parse(ns.substring(i, i + 2), radix: 16),
  ];
  final hash = sha1.convert([...nsBytes, ...utf8.encode(name)]).bytes;
  final bytes = hash.sublist(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50; // version 5
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// [entity] if it is a valid entity wire name: camelCase, at most 64
/// characters (the sync contract's `entity` limit, A01 PA7). Otherwise an
/// `ArgumentError`.
String checkEntityWireName(String entity) {
  if (entity.length > 64 || !_wireName.hasMatch(entity)) {
    throw ArgumentError.value(
      entity,
      'entity',
      'must be a camelCase wire name of at most 64 characters',
    );
  }
  return entity;
}

final _wireName = RegExp(r'^[a-z][a-zA-Z0-9]*$');
