import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'device_id_store.g.dart';

/// The install's id (S06 plan D8): the single id of this install, used for
/// the `X-Device-Id` header and, from S09, as the node id of the hybrid
/// logical clock (TD-049). Never sent to error reporting (A5).
///
/// A UUIDv7 made once, on first use, and kept in preferences: an install
/// id, not a hardware id. It is reset only by reinstalling or clearing the
/// app's data.
final class DeviceIdStore {
  /// Creates the store over the preferences; the id generator makes the id
  /// when there is none yet.
  new(this._preferences, this._ids);

  final SharedPreferencesAsync _preferences;
  final IdGenerator _ids;
  Future<String>? _id;

  /// The device id, read (or created) once and then memoised. Concurrent
  /// first calls share one lookup, so they can't make two ids.
  Future<String> deviceId() {
    if (_id case final id?) return id;
    final id = _id = _loadOrCreate();
    // A failed lookup is retried on the next call instead of being kept.
    unawaited(
      id.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_id, id)) _id = null;
        },
      ),
    );
    return id;
  }

  Future<String> _loadOrCreate() async {
    final stored = await _preferences.getString(PreferenceKeys.deviceId);
    if (stored != null && isUuid(stored)) return stored;
    final id = _ids.next();
    await _preferences.setString(PreferenceKeys.deviceId, id);
    return id;
  }
}

/// The app's [DeviceIdStore].
@Riverpod(keepAlive: true)
DeviceIdStore deviceIdStore(Ref ref) => DeviceIdStore(
  ref.watch(sharedPreferencesProvider),
  ref.watch(idGeneratorProvider),
);
