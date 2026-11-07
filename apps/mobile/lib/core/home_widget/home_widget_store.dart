import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha256;
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_store.g.dart';

/// The home-screen widgets' snapshot on the phone (A71 D1, D3): a few
/// formatted numbers the native widgets render, in the app's private
/// preferences file `fb_home_widget` (excluded from backup and transfer).
/// The widgets never open the database. Nothing here is logged.
abstract interface class HomeWidgetStore {
  /// Replaces the snapshot with [data] (strings, ints and bools only) and
  /// redraws every widget. Refused while [held], and when [epoch] (the
  /// [this.epoch] its inputs were read in) is no longer current.
  Future<void> save(Map<String, Object> data, {int? epoch});

  /// Bumped by [clearAndHold] and [release]: inputs read in an older epoch
  /// (before or during an account transition) are never written.
  int get epoch;

  /// Removes the snapshot and redraws: the widgets show "Open Fitness
  /// Buddy" and the buttons.
  Future<void> clear();

  /// [clear], but only while the stored snapshot belongs to [profileTag]
  /// (another profile may already have written its own).
  Future<void> clearFor(String profileTag);

  /// Clears the snapshot durably (written to disk before it completes) and
  /// refuses every [save] until [release] (A71 review, security 1): the
  /// account transitions call it before the open profile or its sign-out
  /// state changes, so no crash leaves the old profile's numbers behind and
  /// no write queued for the old profile lands afterwards. Throws when the
  /// clear can't be confirmed; without widgets (no channel) it does nothing.
  Future<void> clearAndHold();

  /// Accepts [save]s again (the transition ended).
  void release();

  /// Whether [save]s are refused ([clearAndHold]).
  bool get held;

  /// The widget tap the app was opened or brought back with, once: one of
  /// the native allow-list's action names, or null.
  Future<String?> takeLaunchAction();

  /// Calls [onTap] whenever a widget tap brings the running app to the
  /// front; read the action with [takeLaunchAction].
  void listen(void Function() onTap);
}

/// The snapshot key holding the profile tag (`homeWidgetProfileTag`).
const homeWidgetProfileKey = 'profile';

/// The tag of [profileKey] stored with its snapshot: a short one-way hash,
/// never the key itself.
String homeWidgetProfileTag(String profileKey) => sha256
    .convert(utf8.encode('fb-widget|$profileKey'))
    .toString()
    .substring(0, 16);

/// The Android widgets' channel (`MainActivity.kt`, `HomeWidgets.kt`). Off
/// Android every call does nothing (widgets are Android-only in R1). Calls
/// run one at a time in order, so a [clearAndHold] can't be overtaken by a
/// save queued before it, and a save checks the hold when it runs.
final class ChannelHomeWidgetStore implements HomeWidgetStore {
  /// Over the app's channel; [supported] defaults to "running on Android".
  new({bool? supported})
    : _supported =
          supported ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  /// The channel's name.
  static const channel = MethodChannel('fitness_buddy/home_widget');

  final bool _supported;
  Future<void> _queue = Future<void>.value();
  int _holds = 0;
  int _epoch = 0;

  @override
  bool get held => _holds > 0;

  @override
  int get epoch => _epoch;

  Future<T> _serial<T>(Future<T> Function() call) {
    final result = _queue.then((_) => call());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<void> save(Map<String, Object> data, {int? epoch}) =>
      _serial(() async {
        if (!_supported || held) return;
        if (epoch != null && epoch != _epoch) return;
        await channel.invokeMethod<void>('save', data);
      });

  @override
  Future<void> clear() => _serial(() async {
    if (!_supported) return;
    await channel.invokeMethod<void>('clear');
  });

  @override
  Future<void> clearFor(String profileTag) => _serial(() async {
    if (!_supported) return;
    await channel.invokeMethod<void>('clearFor', profileTag);
  });

  @override
  Future<void> clearAndHold() {
    // Held at once: a save queued behind this clear is refused too.
    _holds = 1;
    _epoch++;
    return _serial(() async {
      if (!_supported) return;
      try {
        final committed = await channel.invokeMethod<bool>('clearDurably');
        if (committed != true) throw StateError('widget clear not committed');
      } on MissingPluginException {
        // No widgets on this build: nothing to clear.
      }
    });
  }

  @override
  void release() {
    _holds = 0;
    _epoch++;
  }

  @override
  Future<String?> takeLaunchAction() async {
    if (!_supported) return null;
    return await channel.invokeMethod<String>('takeLaunchAction');
  }

  @override
  void listen(void Function() onTap) {
    if (!_supported) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'tapped') onTap();
    });
  }
}

/// The app's [HomeWidgetStore]; tests override it.
@Riverpod(keepAlive: true)
HomeWidgetStore homeWidgetStore(Ref ref) => ChannelHomeWidgetStore();

/// The open profile's widget tag (A71 D5), re-read on every profile switch;
/// `local` before any switch (like the notification tag).
@riverpod
Future<String> homeWidgetProfile(Ref ref) async {
  ref.watch(profileGenerationProvider);
  final selected = ref.watch(profileKeyProvider);
  final resolve = ref.watch(activeProfileResolverProvider);
  return homeWidgetProfileTag(selected ?? await resolve?.call() ?? 'local');
}
