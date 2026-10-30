import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('TD-053 concurrent first calls make one id; later calls return the '
      'cached value', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = DeviceIdStore(
      SharedPreferencesAsync(),
      UuidV7Generator(ManualClock(DateTime.utc(2026, 10, 30)), Random(1)),
    );
    final ids = await Future.wait([store.deviceId(), store.deviceId()]);
    expect(ids[0], ids[1]);
    expect(isUuid(ids[0]), isTrue);
    expect(await store.deviceId(), ids[0]);
  });
}
