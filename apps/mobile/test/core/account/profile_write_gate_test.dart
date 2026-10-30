import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/account/profile_write_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late ProfileRegistry registry;
  var suspended = false;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    registry = ProfileRegistry(SharedPreferencesAsync(), namespace: 'dev');
    suspended = false;
  });

  ProfileWriteGate gate() =>
      ProfileWriteGate(registry, suspended: () => suspended);

  test('AC-004 the active writable profile may be written; a read-only copy, '
      'an inactive profile or a running transition may not', () async {
    expect(await gate().denial(ProfileRegistry.guestKey), isNull);
    expect(await gate().denial('acct-0123456789abcdef'), 'inactiveProfile');

    suspended = true;
    expect(await gate().denial(ProfileRegistry.guestKey), 'transition');
    suspended = false;

    final snapshot = await registry.read();
    await registry.write(
      snapshot.put(snapshot.active.copyWith(readOnly: true)),
    );
    expect(await gate().denial(ProfileRegistry.guestKey), 'readOnlyProfile');
  });

  test('AC-003 a write bound to an older profile generation is rejected '
      '(a form opened before a recovery switched profiles)', () async {
    var current = 1;
    final gate = ProfileWriteGate(
      registry,
      suspended: () => false,
      currentGeneration: () => current,
    );
    expect(await gate.denial(ProfileRegistry.guestKey, generation: 1), isNull);
    current = 2;
    expect(
      await gate.denial(ProfileRegistry.guestKey, generation: 1),
      'staleProfile',
    );
  });
}
