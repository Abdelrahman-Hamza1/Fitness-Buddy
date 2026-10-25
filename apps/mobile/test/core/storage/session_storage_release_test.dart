import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

// Exact pub archive audit: bumping the plugin requires reviewing PA1/PA2 again.
void main() {
  test('Rule 09.4 A20 exact release recovery/mapping gate', () async {
    final config = File('../../.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
    final plugin = packages.cast<Map<String, dynamic>>().singleWhere(
      (p) => p['name'] == 'flutter_secure_storage',
    );
    final root = Directory.fromUri(
      config.uri.resolve(plugin['rootUri'] as String),
    );
    const inspected = <String, String>{
      'android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/KeyCipherImplementationRSAOAEP.java':
          '2de69a4ea9b7546ccc97ecfa175ce8d71a74e64553e4e2127fe3ac7e49bc6a46',
      'lib/options/android_options.dart':
          '18bcd09b5444a5f2b8651b4d84995e83148b7521e1616ca6351ed2e1709da86e',
      'android/build.gradle':
          '0013e75fdbf4ec4c80db514f5d01bd966fdcbbd9f65e115835e184266b2858fb',
      'android/src/main/java/com/it_nomads/fluttersecurestorage/FlutterSecureStorage.java':
          'fe83c8fe978f0bc4e66a8cfe33d020b484683fe837a3e53fd6945a2cba758ed3',
      'android/src/main/java/com/it_nomads/fluttersecurestorage/FlutterSecureStoragePlugin.java':
          'bcf44e85c3f4cca0a26a23b11152c198db1c9d8f2fda70c29ed531b7dc8923ae',
      'android/src/main/java/com/it_nomads/fluttersecurestorage/FlutterSecureStorageConfig.java':
          '0ae8ff90d2a7d20605b989e970d9d5908099ec6729a5224785e5499a6cec55e0',
      'android/src/main/java/com/it_nomads/fluttersecurestorage/NamespacedConfigSource.java':
          'efee7d10515b89c4818b675a6fc53dc9fc13a2f702f4c6988e6e5a92e33d40e6',
      'android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/StorageCipherFactory.java':
          '1b5aa836d15b42886885fbb05b6fac92244ffc11c2df75c41c133aec6baacb65',
      'android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/StorageCipherImplementationGCM.java':
          'd2a7a88658799fa529da57d98d942ce7fe8cc89df69f22e091c2280476f11c38',
      'android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/LegacyNamespaceKeyRecovery.java':
          '794f9eefe8216c6469f7bbee91416d77007217b3c4c261e927af0ce9bf1f2ece',
    };
    for (final entry in inspected.entries) {
      expect(
        sha256
            .convert(File('${root.path}/${entry.key}').readAsBytesSync())
            .toString(),
        entry.value,
        reason: 'Re-audit pinned source: ${entry.key}',
      );
    }
    final lock = File('../../pubspec.lock').readAsStringSync();
    expect(
      lock,
      contains(
        'd4e1fb6b2cb524868929e78dc0282fa000554b22060fb53789dc481c9fc95bb8',
      ),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('flutter_secure_storage: 11.2.0'),
    );
    final native = File(
      'android/app/src/main/java/io/github/'
      'abdelrahmanhamza1/fitnessbuddy/SessionStorageCommitter.java',
    ).readAsStringSync();
    for (final name in [
      'FlutterSecureKeyStorage:fb.session.secure.v1',
      'FlutterSecureStorageConfiguration:fb.session.secure.v1',
      '"fb.session.secure.v1"',
    ]) {
      expect(native, contains(name));
    }
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml')
        .readAsStringSync();
    // A11: cloud backup and device transfer are include-only allow-lists of
    // the database files (lint forbids excludes outside an include), so shared
    // preferences stay out by omission; only the iOS transfer keeps an exclude.
    expect(
      RegExp(r'<exclude domain="sharedpref" path="\." />')
          .allMatches(rules)
          .length,
      1,
    );
    expect(RegExp('<include domain="file"').allMatches(rules).length, 6);
    expect(rules, isNot(contains('<include domain="sharedpref"')));
    expect(rules, isNot(contains('<include domain="root"')));
    expect(
      File('android/app/src/main/res/xml/backup_rules.xml').readAsStringSync(),
      contains('<exclude domain="sharedpref" path="." />'),
    );
  });
}
